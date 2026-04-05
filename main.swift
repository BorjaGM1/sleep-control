import AppKit
import Darwin
import Foundation

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private var refreshTimer: Timer?

    private let noSleepItem = NSMenuItem(title: "No Sleep", action: #selector(toggleNoSleep), keyEquivalent: "")
    private let stayAwakeItem = NSMenuItem(title: "StayAwake", action: #selector(toggleStayAwake), keyEquivalent: "")
    private let turnBothOffItem = NSMenuItem(title: "Turn Both Off", action: #selector(turnBothOff), keyEquivalent: "")
    private let noSleepStatusItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let stayAwakeStatusItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let powerSourceItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")

    private let pidFile = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".stayawake.pid")
    private let stayAwakeCommand = "/usr/bin/caffeinate"
    private let stayAwakeArguments = ["-dimsu"]

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureStatusItem()
        configureMenu()
        refreshState()

        refreshTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.refreshState()
        }
    }

    private func configureStatusItem() {
        statusItem.menu = menu
        guard let button = statusItem.button else { return }
        button.imagePosition = .imageOnly
        button.toolTip = "Sleep Control"
        updateStatusIcon(noSleep: false, stayAwake: false)
    }

    private func configureMenu() {
        menu.delegate = self

        let titleItem = NSMenuItem(title: "Sleep Control", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        menu.addItem(.separator())

        noSleepItem.target = self
        stayAwakeItem.target = self
        turnBothOffItem.target = self
        menu.addItem(noSleepItem)
        menu.addItem(stayAwakeItem)
        menu.addItem(turnBothOffItem)

        menu.addItem(.separator())

        noSleepStatusItem.isEnabled = false
        stayAwakeStatusItem.isEnabled = false
        powerSourceItem.isEnabled = false
        menu.addItem(noSleepStatusItem)
        menu.addItem(stayAwakeStatusItem)
        menu.addItem(powerSourceItem)

        menu.addItem(.separator())
        menu.addItem(makeItem("Quit", action: #selector(quitApp)))
    }

    private func makeItem(_ title: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    func menuWillOpen(_ menu: NSMenu) {
        refreshState()
    }

    private func refreshState() {
        let noSleep = sleepDisabled()
        let stayAwake = stayAwakeRunning()

        noSleepItem.state = noSleep ? .on : .off
        stayAwakeItem.state = stayAwake ? .on : .off
        turnBothOffItem.isEnabled = noSleep || stayAwake

        noSleepStatusItem.title = "No Sleep status: \(noSleep ? "On" : "Off")"
        stayAwakeStatusItem.title = "StayAwake status: \(stayAwake ? "On" : "Off")"
        powerSourceItem.title = "Power: \(currentPowerSource())"

        updateStatusIcon(noSleep: noSleep, stayAwake: stayAwake)
    }

    private func updateStatusIcon(noSleep: Bool, stayAwake: Bool) {
        guard let button = statusItem.button else { return }

        let symbolName: String
        if noSleep && stayAwake {
            symbolName = "bolt.horizontal.circle.fill"
        } else if noSleep || stayAwake {
            symbolName = "bolt.horizontal.circle"
        } else {
            symbolName = "moon.circle"
        }

        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Sleep Control") {
            image.isTemplate = true
            button.image = image
            button.title = ""
        } else {
            button.image = nil
            button.title = noSleep || stayAwake ? "SC" : "Zz"
        }

        button.toolTip = "Sleep Control\nNo Sleep: \(noSleep ? "On" : "Off")\nStayAwake: \(stayAwake ? "On" : "Off")"
    }

    private func sleepDisabled() -> Bool {
        guard let output = shell("/usr/bin/pmset", ["-g"]) else { return false }
        return output
            .split(separator: "\n")
            .contains(where: { $0.contains("SleepDisabled") && $0.contains("1") })
    }

    private func currentPowerSource() -> String {
        guard let output = shell("/usr/bin/pmset", ["-g", "batt"]) else {
            return "Unknown"
        }

        for line in output.split(separator: "\n") {
            if line.contains("Now drawing from") {
                if line.contains("Battery Power") { return "Battery" }
                if line.contains("AC Power") { return "AC" }
            }
        }

        return "Unknown"
    }

    private func stayAwakeRunning() -> Bool {
        let pids = stayAwakePIDs()
        syncStayAwakePIDFile(with: pids)
        return !pids.isEmpty
    }

    private func stayAwakePID() -> pid_t? {
        guard
            let data = try? Data(contentsOf: pidFile),
            let text = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
            let value = Int32(text)
        else {
            return nil
        }
        return value
    }

    private func stayAwakePIDs() -> [pid_t] {
        var pids = Set<pid_t>()

        if let pid = stayAwakePID(), processMatchesStayAwake(pid: pid), kill(pid, 0) == 0 {
            pids.insert(pid)
        }

        guard let output = shell("/bin/ps", ["-axo", "pid=,command="]) else {
            return Array(pids)
        }

        for line in output.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            let parts = trimmed.split(maxSplits: 1, whereSeparator: \.isWhitespace)
            guard parts.count == 2, let pid = Int32(parts[0]) else { continue }

            let command = String(parts[1]).trimmingCharacters(in: .whitespaces)
            if isStayAwakeCommand(command) {
                pids.insert(pid)
            }
        }

        return Array(pids).sorted()
    }

    private func syncStayAwakePIDFile(with pids: [pid_t]) {
        guard let pid = pids.first else {
            try? FileManager.default.removeItem(at: pidFile)
            return
        }

        let pidText = "\(pid)\n"
        try? pidText.write(to: pidFile, atomically: true, encoding: .utf8)
    }

    private func processMatchesStayAwake(pid: pid_t) -> Bool {
        guard let output = shell("/bin/ps", ["-p", String(pid), "-o", "command="]) else {
            return false
        }

        return output
            .split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .contains(where: isStayAwakeCommand)
    }

    private func isStayAwakeCommand(_ command: String) -> Bool {
        let normalized = command.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized == ([stayAwakeCommand] + stayAwakeArguments).joined(separator: " ") {
            return true
        }

        return normalized.hasSuffix("caffeinate -dimsu")
    }

    @objc
    private func toggleNoSleep() {
        let target = sleepDisabled() ? "0" : "1"
        runNoSleepCommand(target)

        refreshState()
    }

    @objc
    private func toggleStayAwake() {
        if stayAwakeRunning() {
            stopStayAwake()
        } else {
            startStayAwake()
        }

        refreshState()
    }

    @objc
    private func turnBothOff() {
        if sleepDisabled() {
            runNoSleepCommand("0")
        }

        if stayAwakeRunning() {
            stopStayAwake()
        }

        refreshState()
    }

    private func startStayAwake() {
        if stayAwakeRunning() {
            return
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: stayAwakeCommand)
        process.arguments = stayAwakeArguments
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            let pidText = "\(process.processIdentifier)\n"
            try pidText.write(to: pidFile, atomically: true, encoding: .utf8)
        } catch {
            showError("Failed to start StayAwake.", details: error.localizedDescription)
        }
    }

    private func stopStayAwake() {
        let pids = stayAwakePIDs()
        guard !pids.isEmpty else {
            try? FileManager.default.removeItem(at: pidFile)
            return
        }

        var failures: [String] = []

        for pid in pids {
            if kill(pid, SIGTERM) != 0 && errno != ESRCH {
                failures.append("PID \(pid): \(String(cString: strerror(errno)))")
            }
        }

        try? FileManager.default.removeItem(at: pidFile)

        if !failures.isEmpty {
            showError("Failed to stop StayAwake.", details: failures.joined(separator: "\n"))
        }
    }

    private func runNoSleepCommand(_ target: String) {
        let command = "/usr/bin/pmset -a disablesleep \(target)"
        let script = """
        do shell script "\(escapeAppleScript(command))" with administrator privileges
        """

        var error: NSDictionary?
        NSAppleScript(source: script)?.executeAndReturnError(&error)

        if let error {
            showError("Failed to update No Sleep mode.", details: error.description)
        }
    }

    @objc
    private func quitApp() {
        NSApp.terminate(nil)
    }

    private func showError(_ message: String, details: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = details
        alert.alertStyle = .warning
        alert.runModal()
    }

    private func shell(_ executable: String, _ arguments: [String]) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)
    }

    private func escapeAppleScript(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
