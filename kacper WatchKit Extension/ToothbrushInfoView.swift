//
//  ToothbrushInfoView.swift
//  kacper WatchKit Extension
//
//  Created by Kacper Serewiś on 15/07/2021.
//

import Foundation
import SwiftUI

struct ToothbrushInfo : Identifiable{
    let id: String
    var value: String
}

enum KeyValuePairs : String {
    case Battery = "Battery:"
    case BatteryInSeconds = "Time left on bat:"
    case State = "State:"
    case Mode = "Mode:"
    case TypeId = "Type Id:"
    case FwVersion = "FW Version:"
    case ProtocolVersion = "Prot. Version:"
    case Date = "Date:"
    case SupportedModes = "Supported modes:"
    case Signals = "Signals:"
    case Sectors = "Sectors:"
    case UserId = "User ID:"
    case BrushId = "Brush ID:"
    case HighPressure = "Pressure:"
}

struct ToothbrushInfoView: View {
    var toothrbushUpdatePub: NotificationCenter.Publisher
    var cachedToothbrushDatasPub: NotificationCenter.Publisher
    var kspNotifications = KspNotifications()
    
    @State var toothbrushInfos = [ToothbrushInfo]()
    
//    ForEach(bleManager.foundDevices){
//        item in Button(String(item.name)) {
//            bleManager.stopScanning()
//            saveToothbrush(bluetoothDevice: item)
//        }
//    }
    
    init(){
        toothrbushUpdatePub = kspNotifications.getPublisher(notificationType: .ToothbrushUpdate)
        cachedToothbrushDatasPub = kspNotifications.getPublisher(notificationType: .CachedToothbrushDatas)
    }
    var body: some View {
        ScrollView {
            ForEach(toothbrushInfos){
                item in HStack {
                    Text(item.id)
                    Text(item.value)
                }
            }
            
        }.onAppear() {
            kspNotifications.notify(notificationType: .RequestCachedToothbrushDatas, notifObj: nil)
        }
        .onReceive(toothrbushUpdatePub)
        {
            (output) in self.onToothbrushUpdate(output)
        }.onReceive(cachedToothbrushDatasPub) {
            (output) in self.onCachedToothbrushDatas(output)
        }
        
        .navigationTitle("Info")
    }
    
    private func onCachedToothbrushDatas(_ notification: Notification)
    {
        let toothbrushDatas = notification.object as! [ToothbrushData]
        for toothbrushData in toothbrushDatas {
            parseToothbrushData(toothbrushData: toothbrushData)
        }
    }

    private func parseToothbrushData(toothbrushData: ToothbrushData)
    {
        switch toothbrushData.type {
        case .BATTERY:
            updateArray(keyName: .Battery, keyValue: String(toothbrushData.value as! Int))
            updateArray(keyName: .BatteryInSeconds, keyValue: String(toothbrushData.secondValue as! Int))
        case .STATUS:
            let optionalOrg = toothbrushData.value as! ToothbrushStatusCharValues?
            if let unwrapped = optionalOrg {
                updateArray(keyName: .State, keyValue: String(unwrapped.caseName))
            }else{
                updateArray(keyName: .State, keyValue: String("Invalid"))
            }
        case .MODE:
            let optionalOrg = toothbrushData.value as! ToothbrushBrushModeCharValues?
            if let unwrapped = optionalOrg {
                updateArray(keyName: .Mode, keyValue: String(unwrapped.caseName))
            }
            else{
                updateArray(keyName: .Mode, keyValue: String("Invalid"))
            }
        case .MODEL_ID:
            let optionalOrg = toothbrushData.value as! ToothbrushBrushInfo?
            if let unwrapped = optionalOrg {
                updateArray(keyName: .TypeId, keyValue: String(unwrapped.type))
                if let fwVersion = unwrapped.fwVersion {
                    updateArray(keyName: .FwVersion, keyValue: String(fwVersion))
                }
                if let protVersion = unwrapped.protocolVersion {
                    updateArray(keyName: .ProtocolVersion, keyValue: String(protVersion))
                }
            } else{
                updateArray(keyName: .TypeId, keyValue: String("Invalid."))
            }
        case .CURRENT_DATE:
            let optionalOrg = toothbrushData.value as! Date?
            if let unwrapped = optionalOrg {
                updateArray(keyName: .Date, keyValue: unwrapped.formatted())
            }
            else{
                updateArray(keyName: .Date, keyValue: String("Invalid."))
            }
        case .AVAILABLE_MODES:
            let optionalOrg = toothbrushData.value as! [ToothbrushBrushModeCharValues]?
            if let unwrapped = optionalOrg {
                updateArray(keyName: .SupportedModes, keyValue: String(unwrapped.count))
            }else{
                updateArray(keyName: .SupportedModes, keyValue: String("Invalid."))
            }
        case .SIGNAL:
            let optionalOrg = toothbrushData.value as! ToothbrushBrushSignalCharValues?
            if let unwrapped = optionalOrg {
                let toShow = String("\(unwrapped.vibrate),\(unwrapped.finalVibrate),\(unwrapped.visualSignal),\(unwrapped.finalVisualSignal)")
                updateArray(keyName: .Signals, keyValue: toShow)
            }
            else{
                updateArray(keyName: .Signals, keyValue: String("Invalid."))
            }
        case .SECTOR_TIME:
            let optionalOrg = toothbrushData.value as! [Int]?
            if let unwrapped = optionalOrg {
                var str: String = ""
                for u in unwrapped {
                    str += "\(u) "
                }
                updateArray(keyName: .Sectors, keyValue: str)
            }
            else{
                updateArray(keyName: .Sectors, keyValue: String("Invalid."))
            }
        case .USER_ID:
            let optionalOrg = toothbrushData.value as! Int?
            if let unwrapped = optionalOrg {
                updateArray(keyName: .UserId, keyValue: String(unwrapped))
            }
            else{
                updateArray(keyName: .UserId, keyValue: String("Invalid."))
            }
        case .TOOTHBRUSH_ID_TIME:
            let optionalOrg = toothbrushData.value as! Int?
            if let unwrapped = optionalOrg {
                updateArray(keyName: .BrushId, keyValue: String(unwrapped))
            }
            else{
                updateArray(keyName: .BrushId, keyValue: String("Invalid"))
            }
        case .PRESSURE_SENSOR:
            let optionalOrg = toothbrushData.value as! Int?
            if let unwrapped = optionalOrg {
                updateArray(keyName: .HighPressure, keyValue: String(unwrapped))
            }
            else{
                updateArray(keyName: .HighPressure, keyValue: String("Invalid"))
            }
        default:
            print("Boeie")
        }
    }
    
    func onToothbrushUpdate(_ notification: Notification){
        let toothbrushData = notification.object as! ToothbrushData
        parseToothbrushData(toothbrushData: toothbrushData)
    }
    
    func updateArray(keyName: KeyValuePairs, keyValue: String)
    {
        for index in 0..<toothbrushInfos.count {
            if toothbrushInfos[index].id == keyName.rawValue {
                toothbrushInfos[index].value = String(keyValue)
                return
            }
        }
        
        toothbrushInfos.append(ToothbrushInfo(id: keyName.rawValue, value: keyValue))
        
    }
    
    
}
