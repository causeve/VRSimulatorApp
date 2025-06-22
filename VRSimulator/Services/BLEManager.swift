import Combine
import Foundation
import CoreBluetooth

class BLEManager: NSObject, ObservableObject {
    // Service and characteristic UUIDs should match the actual peripheral
    private let serviceUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    private let characteristicUUID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    private let characteristicUUID1 = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
    
    private var centralManager: CBCentralManager?
    private var peripheral: CBPeripheral?
    private var characteristic: CBCharacteristic?
    private var reconnectTimer: Timer?
    
    @Published var status: BLEStatus = .disconnected
    private let reconnectInterval: TimeInterval = 5.0
    
    // Publishers for axis values
    private let axisSubject = PassthroughSubject<AxisValue, Never>()
    var axisPublisher: AnyPublisher<AxisValue, Never> {
        axisSubject.eraseToAnyPublisher()
    }
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Public Methods
    
    func startScanning() {
        guard centralManager?.state == .poweredOn else {
            return
        }
        
        updateStatus(.connecting)
        centralManager?.scanForPeripherals(withServices: [serviceUUID], options: nil)
        
        // Set a timeout for scanning
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            if self?.status == .connecting {
                self?.stopScanning()
                self?.scheduleReconnect()
            }
        }
    }
    
    func stopScanning() {
        centralManager?.stopScan()
        if status == .connecting {
            updateStatus(.disconnected)
        }
    }
    
    func sendCommand(axis: String, value: Int) -> Bool {
        guard let characteristic = characteristic, status == .connected else {
            return false
        }
        
        // Format the command string based on your BLE protocol
        let command = "\(axis):\(value)"
        guard let data = command.data(using: .utf8) else {
            return false
        }
        
        peripheral?.writeValue(data, for: characteristic, type: .withResponse)
        return true
    }
    
    func sendSequentialCommands(commands: [(axis: String, value: Int)], completion: @escaping (Bool) -> Void) {
        guard status == .connected else {
            completion(false)
            return
        }
        
        sendCommandsSequentially(commands: commands, index: 0, completion: completion)
    }
    
    private func sendCommandsSequentially(commands: [(axis: String, value: Int)], index: Int, completion: @escaping (Bool) -> Void) {
        guard index < commands.count else {
            completion(true)
            return
        }
        
        let command = commands[index]
        let success = sendCommand(axis: command.axis, value: command.value)
        
        if success {
            // Wait a brief moment before sending the next command
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.sendCommandsSequentially(commands: commands, index: index + 1, completion: completion)
            }
        } else {
            completion(false)
        }
    }
    
    func cleanup() {
        stopScanning()
        cancelReconnectTimer()
        
        if let peripheral = peripheral, let centralManager = centralManager {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    // MARK: - Private Methods
    
    private func updateStatus(_ newStatus: BLEStatus) {
        guard status != newStatus else { return }
        
        DispatchQueue.main.async { [weak self] in
            self?.status = newStatus
        }
        
        if newStatus == .disconnected {
            scheduleReconnect()
        } else if newStatus == .connected {
            cancelReconnectTimer()
        }
    }
    
    private func scheduleReconnect() {
        cancelReconnectTimer()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: reconnectInterval, repeats: false) { [weak self] _ in
            self?.startScanning()
        }
    }
    
    @objc private func reconnect() {
        startScanning()
    }
    
    private func cancelReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
    
    // Parse BLE notification data
    private func parseNotification(_ data: Data) {
        guard let message = String(data: data, encoding: .utf8) else { return }
        
        // Clean and split
        let components = message.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: ",")
        
        for component in components {
            let parts = component.trimmingCharacters(in: .whitespacesAndNewlines)
                .components(separatedBy: ":")
            
            if parts.count == 2,
               let axis = parts.first,
               let valueString = parts.last,
               let value = Double(valueString) {
                
                let axisValue = AxisValue(axis: axis, value: Int(value))
                DispatchQueue.main.async {
                    self.axisSubject.send(axisValue)
                }
            }
        }
    }
    
}

// MARK: - CBCentralManagerDelegate
extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            startScanning()
        case .poweredOff:
            updateStatus(.disconnected)
        case .resetting:
            updateStatus(.disconnected)
        case .unauthorized:
            updateStatus(.disconnected)
        case .unsupported:
            updateStatus(.disconnected)
        case .unknown:
            updateStatus(.disconnected)
        @unknown default:
            updateStatus(.disconnected)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Connect to the discovered peripheral
        self.peripheral = peripheral
        central.stopScan()
        central.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices([serviceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        updateStatus(.disconnected)
        scheduleReconnect()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        updateStatus(.disconnected)
        scheduleReconnect()
    }
}

// MARK: - CBPeripheralDelegate
extension BLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {
            return
        }
        for service in services {
            peripheral.discoverCharacteristics([characteristicUUID, characteristicUUID1], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            if characteristic.uuid == characteristicUUID1 {
                self.characteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                updateStatus(.connected)
            }
            else if characteristic.uuid == characteristicUUID{
                self.characteristic = characteristic  // for write
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        
        // Convert Data to String (if it's a UTF-8 string)
        if let message = String(data: data, encoding: .utf8) {
            // Optionally parse it
            parseNotification(data)
        } else {
           //print("Received raw data: \(data)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            //print("DEBUG - Error writing to characteristic: \(error.localizedDescription)")
        } else {
           // print("DEBUG - Successfully wrote value to characteristic")
        }
    }
}
