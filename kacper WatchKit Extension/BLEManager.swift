//
//  BLEManager.swift
//  kacper WatchKit Extension
//
//  Created by Kacper Serewiś on 14/07/2021.
//

import Foundation
import CoreBluetooth

struct Peripheral: Identifiable {
    let id: Int
    let name: String
    let rssi: Int
}

class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate {
    var myCentral: CBCentralManager!
    
    
    @Published var isSwitchedOn = false
    @Published var manufacturerData = [String : [UInt8]]()
    
    
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
    
    lazy var lastByteArray: [UInt8] = [UInt8](repeating: 0, count: 13)
    
    
    @Published var peripherals = [Peripheral]()
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        
        //manufacturerData[peripheral.identifier.uuidString] =
        
        
        
        if let manuData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? NSData {
            let count = manuData.length / MemoryLayout<UInt8>.size
            var byteArray = [UInt8](repeating: 0, count: count)
            manuData.getBytes(&byteArray, length: count)
            
            
            if peripheral.identifier.uuidString == "33C9C672-14BE-97A0-69F8-E48E04576571" {
                manufacturerData[peripheral.identifier.uuidString] = byteArray
                print("Added toothbrysg [blemanager]")
                NotificationCenter.default.post(name: NSNotification.Name("NewBrushData"), object: nil)
            }
            // 33C9C672-14BE-97A0-69F8-E48E04576571
            
            //print(byteArray)
            
            
//            let quarterTime = byteArray[8]
//            let totalTime = byteArray[11]
//            let currentQuarter = byteArray[10]
//            let minutesPassed = byteArray[7]
//            let preassureHigh = byteArray[6] == 192
//            let currentMode = byteArray[9]
//            print("Quarter Time: \(quarterTime) | Total time: \(totalTime) | Current Quarter: \(currentQuarter) | Minutes: \(minutesPassed) | High preassure: \(preassureHigh) | Current mode: \(currentMode)")
            
            
            
            
            lastByteArray = byteArray
            
            
        }
//        if(peripheral.identifier.uuidString == "33C9C672-14BE-97A0-69F8-E48E04576571")
//        {
//
//        }
        
        
        
        
        //        if let name = peripheral.name as? String {
        //            peripheralName = name
        //        }
        //        else{
        //            peripheralName = "Unknown"
        //        }
        
        //        let newPeripheral = Peripheral(id: peripherals.count, name: peripheralName, rssi: RSSI.intValue)
        //        print(newPeripheral)
        //        peripherals.append(newPeripheral)
    }
    
    func startScanning(){
        myCentral.scanForPeripherals(withServices: nil, options: nil)
    }
    func stopScanning(){
        myCentral.stopScan()
    }
}
