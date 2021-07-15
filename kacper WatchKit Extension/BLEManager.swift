//
//  BLEManager.swift
//  kacper WatchKit Extension
//
//  Created by Kacper Serewiś on 14/07/2021.
//

import Foundation
import CoreBluetooth

struct BluetoothDevice: Identifiable {
    let name: String
    let id: UUID
    let peripheral: CBPeripheral
}

class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate{
    
    
    var myCentral: CBCentralManager!
    var kspNotifications = KspNotifications()
    
    
    @Published var isSwitchedOn = false
    
    @Published var foundDevices = [BluetoothDevice]()
    @Published var connectedDeviceRef: CBPeripheral?
    
    override init(){
        super.init()
        myCentral = CBCentralManager(delegate: self, queue: nil)
        myCentral.delegate = self
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            isSwitchedOn = true
        }
        else{
            isSwitchedOn = false
        }
    }
    
    
    // onDiscoverBluetoothDevice
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let deviceName = peripheral.name {
            if !alreadyExists(uuid: peripheral.identifier)
            {
                foundDevices.append(BluetoothDevice(name: deviceName, id: peripheral.identifier, peripheral: peripheral))
                kspNotifications.notify(notificationType: .BluetoothDeviceFound, notifObj: nil)
                
            }
        }
    }
    
    func connectToPeripheral(cbperipheral: CBPeripheral)
    {
        stopScanning()
        myCentral.connect(cbperipheral, options: nil)
        kspNotifications.notify(notificationType: .BluetoothDeviceConnecting, notifObj: nil)
    }
    
    // onDidFailToConnect
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        kspNotifications.notify(notificationType: .BluetoothDeviceConnectingFail, notifObj: nil)
    }
    
    // onDidConnect
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        connectedDeviceRef = peripheral
        kspNotifications.notify(notificationType: .BluetoothDeviceConnected, notifObj: nil)
        discoverServices(peripheral: peripheral)
        
    }
    
    func discoverServices(peripheral: CBPeripheral)
    {
        peripheral.discoverServices(nil)
    }
    
    // onDidDiscoverServices
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {
            return
        }
        discoverCharacteristics(peripheral: peripheral)
    }
    
    // onDiscoverCharacteristics
    func discoverCharacteristics(peripheral: CBPeripheral) {
        guard let services = peripheral.services else {
            return
        }
        for service in services {
            peripheral.discoverCharacteristics(nil,for: service)
        }
    }
    
    // onDidDiscoverCharacteristicsFor
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?){
        print("did discover chars!")
        guard let characteristics = service.characteristics else {
            print("invalid chars!")
            return
        }
        
        for characteristic in characteristics {
            print("\(service): \(characteristic)")
            
            if characteristic.uuid.uuidString.uppercased() == "A0F0FF08-5047-4D53-8208-4F72616C2D42"{
                print("GOT TIMER BRUSH CHAR UPDATING")
                peripheral.readValue(for: characteristic)
            }
        }
    }
    
    // onDidUpdateValueFor
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("Did update for!")
        
        if characteristic.uuid.uuidString.uppercased() == "A0F0FF08-5047-4D53-8208-4F72616C2D42" {
            if characteristic.value != nil {
                let charData = characteristic.value! as Data
                let brushTime = charData[0] * 60 + charData[1]
                print("Brush time: \(brushTime)")
                peripheral.setNotifyValue(true, for: characteristic)
                
            }
        }
    }
    
    // onDidUpdateNotificationStateFor
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("notification update!")
    }

    private func alreadyExists(uuid: UUID) -> Bool {
        for fd in foundDevices {
            if fd.id == uuid {
                return true
            }
        }
        return false
    }
    
    func startScanning(){
        kspNotifications.notify(notificationType: .BluetoothScanningStarted, notifObj: nil)
        myCentral.scanForPeripherals(withServices: nil, options: nil)
    }
    func stopScanning(){
        kspNotifications.notify(notificationType: .BluetoothScanningStopped, notifObj: nil)
        myCentral.stopScan()
    }
}
