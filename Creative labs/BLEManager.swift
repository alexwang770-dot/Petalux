import CoreBluetooth
import Combine
import Foundation
import SwiftUI

// MARK: - BLE UUID Constants
enum PetaLuxUUID {
    nonisolated static let deviceName = "PetaLux"
    nonisolated static let service       = CBUUID(string: "12345678-0000-1000-8000-00805F9B34FB")
    nonisolated static let timeSync      = CBUUID(string: "12345678-0001-1000-8000-00805F9B34FB")
    nonisolated static let command       = CBUUID(string: "12345678-0002-1000-8000-00805F9B34FB")
    nonisolated static let state         = CBUUID(string: "12345678-0003-1000-8000-00805F9B34FB")
}

// MARK: - Models

struct LampState: Equatable {
    var isOpen: Bool = false
    var color: Color3 = Color3(r: 255, g: 120, b: 0)
}

struct Color3: Equatable {
    var r: UInt8
    var g: UInt8
    var b: UInt8

    var swiftUIColor: SwiftUI.Color {
        SwiftUI.Color(
            red:   Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255
        )
    }
}

enum LampCommand {
    case bloomOpen(speed: Int)
    case bloomClose(speed: Int)
    case lightOn
    case lightOff
    case lightColor(r: UInt8, g: UInt8, b: UInt8)
    case scheduleSet(time: String)   // "HH:MM"
    case scheduleClear
    case statusGet

    var payload: Data {
        let dict: [String: Any]
        switch self {
        case .bloomOpen(let s):       dict = ["cmd": "BLOOM_OPEN",     "speed": s]
        case .bloomClose(let s):      dict = ["cmd": "BLOOM_CLOSE",    "speed": s]
        case .lightOn:                dict = ["cmd": "LIGHT_ON"]
        case .lightOff:               dict = ["cmd": "LIGHT_OFF"]
        case .lightColor(let r, let g, let b):
            dict = ["cmd": "LIGHT_COLOR", "r": r, "g": g, "b": b]
        case .scheduleSet(let t):     dict = ["cmd": "SCHEDULE_SET",   "time": t]
        case .scheduleClear:          dict = ["cmd": "SCHEDULE_CLEAR"]
        case .statusGet:              dict = ["cmd": "STATUS_GET"]
        }
        return (try? JSONSerialization.data(withJSONObject: dict)) ?? Data()
    }

    var logString: String {
        String(data: payload, encoding: .utf8) ?? ""
    }
}

struct BLELogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let direction: Direction
    let message: String

    enum Direction { case tx, rx, system }

    var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f.string(from: timestamp)
    }
}

// MARK: - BLE Manager

@MainActor
final class BLEManager: NSObject, ObservableObject {
    // Published state
    @Published var connectionState: ConnectionState = .disconnected
    @Published var lampState = LampState()
    @Published var logEntries: [BLELogEntry] = []

    enum ConnectionState: Equatable {
        case disconnected
        case scanning
        case connecting
        case connected
    }

    // CoreBluetooth
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var timeSyncChar: CBCharacteristic?
    private var commandChar: CBCharacteristic?
    private var stateChar: CBCharacteristic?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }

    // MARK: - Public API

    func startScanning() {
        guard centralManager.state == .poweredOn else { return }
        connectionState = .scanning
        log(.system, "Scanning for \"\(PetaLuxUUID.deviceName)\"...")
        centralManager.scanForPeripherals(
            withServices: [PetaLuxUUID.service],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
    }

    func disconnect() {
        guard let p = peripheral else { return }
        centralManager.cancelPeripheralConnection(p)
    }

    func send(_ command: LampCommand) {
        guard let p = peripheral, let char = commandChar else { return }
        log(.tx, "COMMAND \(command.logString)")
        p.writeValue(command.payload, for: char, type: .withResponse)
    }

    // MARK: - Private

    private func syncTime() {
        guard let p = peripheral, let char = timeSyncChar else { return }

        let now = Date()
        let cal = Calendar.current
        let c = cal.dateComponents([.hour, .minute, .second], from: now)
        let secondsOfDay = (c.hour ?? 0) * 3600
                         + (c.minute ?? 0) * 60
                         + (c.second ?? 0)

        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"

        let payload = (try? JSONSerialization.data(withJSONObject: [
            "time": f.string(from: now),
            "secondsOfDay": secondsOfDay
        ])) ?? Data()

        log(.tx, "TIME_SYNC \(String(data: payload, encoding: .utf8) ?? "")")
        p.writeValue(payload, for: char, type: .withResponse)
    }

    private func requestState() {
        send(.statusGet)
    }

    private func parseState(_ data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        let logStr = String(data: data, encoding: .utf8) ?? ""
        log(.rx, "STATE \(logStr)")
        if let open = json["open"] as? Bool { lampState.isOpen = open }
        if let color = json["color"] as? [Int], color.count == 3 {
            lampState.color = Color3(
                r: UInt8(clamping: color[0]),
                g: UInt8(clamping: color[1]),
                b: UInt8(clamping: color[2])
            )
        }
    }

    private func log(_ direction: BLELogEntry.Direction, _ message: String) {
        let entry = BLELogEntry(timestamp: Date(), direction: direction, message: message)
        logEntries.append(entry)
        if logEntries.count > 100 { logEntries.removeFirst() }
    }
}

// MARK: - CBCentralManagerDelegate

extension BLEManager: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            if central.state == .poweredOn { startScanning() }
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let name = peripheral.name ?? (advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? "")
        guard name == PetaLuxUUID.deviceName else { return }
        Task { @MainActor in
            central.stopScan()
            self.peripheral = peripheral
            self.connectionState = .connecting
            self.log(.system, "Found \"\(name)\" RSSI \(RSSI) dBm - connecting...")
            central.connect(peripheral, options: nil)
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Task { @MainActor in
            self.connectionState = .connected
            self.log(.system, "Connected - discovering services...")
            peripheral.delegate = self
            peripheral.discoverServices([PetaLuxUUID.service])
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in
            self.connectionState = .disconnected
            self.timeSyncChar = nil
            self.commandChar  = nil
            self.stateChar    = nil
            self.log(.system, "Disconnected")
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in
            self.connectionState = .disconnected
            self.log(.system, "Failed to connect: \(error?.localizedDescription ?? "unknown")")
        }
    }
}

// MARK: - CBPeripheralDelegate

extension BLEManager: CBPeripheralDelegate {
    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        Task { @MainActor in
            guard let service = peripheral.services?.first(where: { $0.uuid == PetaLuxUUID.service }) else { return }
            peripheral.discoverCharacteristics(
                [PetaLuxUUID.timeSync, PetaLuxUUID.command, PetaLuxUUID.state],
                for: service
            )
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        Task { @MainActor in
            for char in service.characteristics ?? [] {
                switch char.uuid {
                case PetaLuxUUID.timeSync: self.timeSyncChar = char
                case PetaLuxUUID.command:  self.commandChar  = char
                case PetaLuxUUID.state:
                    self.stateChar = char
                    peripheral.setNotifyValue(true, for: char)
                default: break
                }
            }
            // Step 3: sync time silently
            self.syncTime()
            // Step 4: read current state
            if let stateChar = self.stateChar {
                peripheral.readValue(for: stateChar)
            }
            self.log(.system, "Ready - subscribed to STATE notifications")
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        Task { @MainActor in
            guard characteristic.uuid == PetaLuxUUID.state,
                  let data = characteristic.value else { return }
            self.parseState(data)
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error { Task { @MainActor in self.log(.system, "Write error: \(error.localizedDescription)") } }
    }
}
