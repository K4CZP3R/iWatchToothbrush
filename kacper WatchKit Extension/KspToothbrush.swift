//
//  KspToothbrush.swift
//  kacper WatchKit Extension
//
//  Created by Kacper Serewiś on 14/07/2021.
//

import Foundation
import SwiftUI
import CoreBluetooth

struct ToothbrushBrushInfo {
    let type: Int
    let protocolVersion: Int?
    let fwVersion: Int?
}

struct ToothbrushBrushSignalCharValues{
    let vibrate : Bool
    let finalVibrate : Bool
    let visualSignal : Bool
    let finalVisualSignal : Bool
    
    init(val: Int){
        vibrate = (val & 0x01) != 0
        finalVibrate = (val & 0x02) != 0
        visualSignal = (val & 0x04) != 0
        finalVisualSignal = (val & 0x08) != 0
        
    }
}



enum ToothbrushBrushModeCharValues : Int {
    case Off = 0x00
    case DailyClean = 0x01
    case Sensitive = 0x02
    case Massage = 0x03
    case Whitening = 0x04
    case DeepClean = 0x05
    case TongueCleaning = 0x06
    case Turbo = 0x07
    case Unknown = 0xff
    
    var caseName: String {
        return Mirror(reflecting: self).children.first?.label ?? String(describing: self)
    }
}

enum ToothbrushStatusCharValues : Int{
    case Unknown = 0x00
    case Init = 0x01
    case Idle = 0x02
    case Run = 0x03
    case Charge = 0x4
    case Setup = 0x05
    case FlightMenu = 0x06
    case FinalTest = 0x71
    case PcbTest = 0x72
    case Sleep = 0x73
    case Transport = 0x74
    
    var caseName: String {
        return Mirror(reflecting: self).children.first?.label ?? String(describing: self)
    }
}

enum ToothbrushCharacteristics : String {
    case TOOTHBRUSH_ID_TIME = "a0f0ff01-5047-4d53-8208-4f72616c2d42"
    case MODEL_ID = "a0f0ff02-5047-4d53-8208-4f72616c2d42"
    case USER_ID = "a0f0ff03-5047-4d53-8208-4f72616c2d42"
    case STATUS = "a0f0ff04-5047-4d53-8208-4f72616c2d42"
    case BATTERY = "a0f0ff05-5047-4d53-8208-4f72616c2d42"
    case BUTTON = "a0f0ff06-5047-4d53-8208-4f72616c2d42"
    case MODE = "a0f0ff07-5047-4d53-8208-4f72616c2d42"
    case BRUSHING_TIME = "a0f0ff08-5047-4d53-8208-4f72616c2d42"
    case CURRENT_SECTOR = "a0f0ff09-5047-4d53-8208-4f72616c2d42"
    case CONTROL = "a0f0ff21-5047-4d53-8208-4f72616c2d42" // not used
    case CURRENT_DATE = "a0f0ff22-5047-4d53-8208-4f72616c2d42"
    case SIGNAL = "a0f0ff24-5047-4d53-8208-4f72616c2d42"
    case AVAILABLE_MODES = "a0f0ff25-5047-4d53-8208-4f72616c2d42"
    case SECTOR_TIME = "a0f0ff26-5047-4d53-8208-4f72616c2d42"
    case SESSION_INFO = "a0f0ff29-5047-4d53-8208-4f72616c2d42" // not used
    case PRESSURE_SENSOR = "a0f0ff0b-5047-4d53-8208-4f72616c2d42"
    
    static let allValues = [TOOTHBRUSH_ID_TIME, MODEL_ID, USER_ID, STATUS, BATTERY, BUTTON, MODE, BRUSHING_TIME, CURRENT_SECTOR, CURRENT_DATE, SIGNAL, AVAILABLE_MODES, SECTOR_TIME, PRESSURE_SENSOR]
    
    var caseName: String {
        return Mirror(reflecting: self).children.first?.label ?? String(describing: self)
    }
    
    
}

struct ToothbrushData {
    let type: ToothbrushCharacteristics
    var value: Any?
    var  secondValue: Any?
}

public class KspToothbrush: ObservableObject {
    @ObservedObject var bluetoothManager = BLEManager()
    var toothbrushPeripheral: CBPeripheral?
    var kspNotifications = KspNotifications()
    var toothbrushId: UUID
    
    @Published var savedToothbrushData = [ToothbrushData]()
    
    
    
    
    
    init(toothbrushId: UUID){
        
        self.toothbrushId = toothbrushId
        
        for char in ToothbrushCharacteristics.allValues {
            bluetoothManager.trackThisCharacteristic(uuid: UUID(uuidString: char.rawValue)!)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(onBluetoothDeviceConnected(_:)), name: Notification.Name(KspNotificationTypes.BluetoothDeviceConnected.rawValue), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onBluetoothDeviceConnecting(_:)), name: Notification.Name(KspNotificationTypes.BluetoothDeviceConnecting.rawValue), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onBluetoothDeviceConnectingFail(_:)), name: Notification.Name(KspNotificationTypes.BluetoothDeviceConnectingFail.rawValue), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onBluetoothScanningStarted(_:)), name: Notification.Name(KspNotificationTypes.BluetoothScanningStarted.rawValue), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onBluetoothScanningStopped(_:)), name: Notification.Name(KspNotificationTypes.BluetoothScanningStopped.rawValue), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onBluetoothDeviceFound(_:)), name: Notification.Name(KspNotificationTypes.BluetoothDeviceFound.rawValue), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onBluetoothDeviceDisconnected(_:)), name: Notification.Name(KspNotificationTypes.BluetoothDeviceDisconnected.rawValue), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onBluetoothCharUpdate(_:)), name: Notification.Name(KspNotificationTypes.BluetoothCharUpdate.rawValue), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onRequestCachedToothbrushDatas(_:)), name: Notification.Name(KspNotificationTypes.RequestCachedToothbrushDatas.rawValue), object: nil)
        
        
        
        
        

    }
    
    @objc func onRequestCachedToothbrushDatas(_ notification: Notification)
    {
        kspNotifications.notify(notificationType: .CachedToothbrushDatas, notifObj: self.savedToothbrushData)
    }
    
    private func updateOrAddToothbrushData(toothbrushData: ToothbrushData)
    {
        for index in 0..<savedToothbrushData.count {
            if savedToothbrushData[index].type == toothbrushData.type {
                self.savedToothbrushData[index].value = toothbrushData.value
                self.savedToothbrushData[index].secondValue = toothbrushData.secondValue
                return
            }
            
        }
        self.savedToothbrushData.append(toothbrushData)
    }
    
    
    
    @objc func onBluetoothCharUpdate(_ notification: Notification) {
        let charUpdate = notification.object as! CharacteristicUpdate
        
        parseAndNotify(charUpdate: charUpdate)
        
    }
    
    private func tryToResolveStatusChar(rawValue: Int) -> ToothbrushStatusCharValues? {
        return  ToothbrushStatusCharValues(rawValue: rawValue)
    }
    private func tryToResolveModeChar(rawValue: Int) -> ToothbrushBrushModeCharValues? {
        return ToothbrushBrushModeCharValues(rawValue: rawValue)
    }
    private func tryToResolveBrushSignalChar(rawValue: Int) -> ToothbrushBrushSignalCharValues? {
        return ToothbrushBrushSignalCharValues(val: rawValue)
    }
    
    func parseCharUpdate(charUpdate: CharacteristicUpdate) -> ToothbrushData? {
        switch charUpdate.id.uuidString.uppercased()
        {
        case ToothbrushCharacteristics.PRESSURE_SENSOR.rawValue.uppercased():
            return ToothbrushData(type: .PRESSURE_SENSOR, value: Int(charUpdate.value[0]), secondValue: nil)
        case ToothbrushCharacteristics.TOOTHBRUSH_ID_TIME.rawValue.uppercased():
            let unpacked = (try! unpack("<I", charUpdate.value.subdata(in: 0..<4))[0]) as? Int
            return ToothbrushData(type: .TOOTHBRUSH_ID_TIME, value: unpacked, secondValue: nil)
        case ToothbrushCharacteristics.USER_ID.rawValue.uppercased():
            return ToothbrushData(type: .USER_ID, value: Int(charUpdate.value[0]), secondValue: nil)
            
        case ToothbrushCharacteristics.SECTOR_TIME.rawValue.uppercased():
            var sectorTimers = [Int]()
            let nSector = charUpdate.value.count >> 1
            let unpacked = try! unpack("<" + String(repeating: "H", count:  nSector), charUpdate.value)
            
            for unpack in unpacked {
                if let uunpack = unpack as? Int {
                    sectorTimers.append(uunpack)
                }
            }
            
            return ToothbrushData(type: .SECTOR_TIME, value: sectorTimers, secondValue: nil)
        case ToothbrushCharacteristics.SIGNAL.rawValue.uppercased():
            let structValue = tryToResolveBrushSignalChar(rawValue: Int(charUpdate.value[0]))
            return ToothbrushData(type: .SIGNAL, value: structValue, secondValue: nil)
            
            
        case ToothbrushCharacteristics.AVAILABLE_MODES.rawValue.uppercased():
            var modes: [ToothbrushBrushModeCharValues] = []
            
            for m in charUpdate.value {
                if let unwrapped = tryToResolveModeChar(rawValue: Int(m)){
                    modes.append(unwrapped)
                }
            }
            
            return ToothbrushData(type: .AVAILABLE_MODES, value: modes)
        case ToothbrushCharacteristics.CURRENT_DATE.rawValue.uppercased():
            if charUpdate.value.count != 4{
                return nil
            }
            
            let secAfter2000 = (try! unpack("<I", charUpdate.value)[0] as? Int)!
            var dComps = DateComponents()
            dComps.year = 2000
            dComps.month = 1
            dComps.day = 1
            let cal = Calendar(identifier: .gregorian)
            let startDt = cal.date(from: dComps)
            
            let currentDt = startDt?.addingTimeInterval(TimeInterval(secAfter2000))
            
            return ToothbrushData(type: .CURRENT_DATE, value: currentDt)
            
            
        case ToothbrushCharacteristics.MODEL_ID.rawValue.uppercased():
            if charUpdate.value.count == 3 {
                let binfo = ToothbrushBrushInfo(type: Int(charUpdate.value[0]), protocolVersion: Int(charUpdate.value[1]), fwVersion: Int(charUpdate.value[2]))
                return ToothbrushData(type: .MODEL_ID, value: binfo, secondValue: nil)
            }
            else{
                let binfo = ToothbrushBrushInfo(type: Int(charUpdate.value[0]), protocolVersion: nil, fwVersion: nil)
                return ToothbrushData(type: .MODEL_ID, value: binfo, secondValue: nil)
            }
        case ToothbrushCharacteristics.MODE.rawValue.uppercased():
            let enumValue = tryToResolveModeChar(rawValue: Int(charUpdate.value[0]))
            return ToothbrushData(type: .MODE, value: enumValue, secondValue: nil)
        case ToothbrushCharacteristics.STATUS.rawValue.uppercased():
            let enumValue = tryToResolveStatusChar(rawValue: Int(charUpdate.value[0]))
            return ToothbrushData(type: .STATUS, value: enumValue, secondValue: nil)
            
            
        case ToothbrushCharacteristics.TOOTHBRUSH_ID_TIME.rawValue.uppercased():
            let rawData = try! unpack("<I", charUpdate.value.subdata(in: 0..<4))
            let tId = (rawData[0] as? Int)!
            return ToothbrushData(type: .TOOTHBRUSH_ID_TIME, value: Int(tId), secondValue: nil)
            
        case ToothbrushCharacteristics.BATTERY.rawValue.uppercased():
            if charUpdate.value.count >= 3 {
                let remainingSecUnpacked = try! unpack("<H", charUpdate.value.subdata(in: 1..<3))
                let remainingSec = remainingSecUnpacked[0] as? Int
                return ToothbrushData(type: .BATTERY, value: Int(charUpdate.value[0]), secondValue: remainingSec)
            }
            else{
                return ToothbrushData(type: .BATTERY, value: Int(charUpdate.value[0]), secondValue: nil)
            }
            
        case ToothbrushCharacteristics.BRUSHING_TIME.rawValue.uppercased():
            let brushingTimeInSec = charUpdate.value[0] * 60 + charUpdate.value[1]
            return  ToothbrushData(type: .BRUSHING_TIME, value: Int(brushingTimeInSec), secondValue: nil)
            
        case ToothbrushCharacteristics.CURRENT_SECTOR.rawValue.uppercased():
            let sector = charUpdate.value[0]
            return  ToothbrushData(type: .CURRENT_SECTOR, value: Int(sector), secondValue: nil)
        
        default:
            return nil
            
        }
    }
    
    private func parseAndNotify(charUpdate: CharacteristicUpdate)
    {
        let parsed = parseCharUpdate(charUpdate: charUpdate)
        
        if let unwrapped = parsed {
            updateOrAddToothbrushData(toothbrushData: unwrapped)
            kspNotifications.notify(notificationType: .ToothbrushUpdate, notifObj: unwrapped)
        }
        
        
    }

    @objc func onBluetoothDeviceFound(_ notification: Notification) {
        for fd in bluetoothManager.foundDevices {
            if fd.id == toothbrushId {
                print("Found toothbrush!")
                bluetoothManager.connectToPeripheral(cbperipheral: fd.peripheral)
                return
            }
        }
        
        print("Still no toothbrush...")
    }
    
    @objc func onBluetoothDeviceConnected(_ notification: Notification) {
        kspNotifications.notify(notificationType: .ToothbrushConnected, notifObj: nil)
        print("Bluetooth device connected!")
    }
    
    @objc func onBluetoothDeviceConnecting(_ notification: Notification) {
        kspNotifications.notify(notificationType: .ToothbrushConnecting, notifObj: nil)
        print("Bluetooth device connecting!")
    }
    
    @objc func onBluetoothDeviceConnectingFail(_ notification: Notification){
        kspNotifications.notify(notificationType: .ToothbrushConnectingFail, notifObj: nil)
        print("Bluetooth device connecting fail!")
    }
    
    @objc func onBluetoothScanningStarted(_ notification: Notification) {
        print("Bluetooth device scan start!")
    }
    
    @objc func onBluetoothScanningStopped(_ notification: Notification){
        print("Bluetooth device scan stop!")
    }
    
    @objc func onBluetoothDeviceDisconnected(_ notification: Notification){
        print("Bluetooth device disconnected!")
        kspNotifications.notify(notificationType: .ToothbrushDisconnected, notifObj: nil)
        
    }
    
    func startScanningForToothbrush(){
        bluetoothManager.startScanning()
    }
    
    func stopScanningForToothbrush(){
        bluetoothManager.stopScanning()
    }
}
