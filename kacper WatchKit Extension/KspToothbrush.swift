//
//  KspToothbrush.swift
//  kacper WatchKit Extension
//
//  Created by Kacper Serewiś on 14/07/2021.
//

import Foundation
import SwiftUI
import CoreBluetooth


public class KspToothbrush: ObservableObject {
    @ObservedObject var bluetoothManager = BLEManager()
    var toothbrushPeripheral: CBPeripheral?
    var kspNotifications = KspNotifications()
    var toothbrushId: UUID
    
    init(toothbrushId: UUID){
        
        self.toothbrushId = toothbrushId
        
        NotificationCenter.default.addObserver(self, selector: #selector(onBluetoothDeviceConnected(_:)), name: Notification.Name(KspNotificationTypes.BluetoothDeviceConnected.rawValue), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onBluetoothDeviceConnecting(_:)), name: Notification.Name(KspNotificationTypes.BluetoothDeviceConnecting.rawValue), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onBluetoothDeviceConnectingFail(_:)), name: Notification.Name(KspNotificationTypes.BluetoothDeviceConnectingFail.rawValue), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onBluetoothScanningStarted(_:)), name: Notification.Name(KspNotificationTypes.BluetoothScanningStarted.rawValue), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onBluetoothScanningStopped(_:)), name: Notification.Name(KspNotificationTypes.BluetoothScanningStopped.rawValue), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onBluetoothDeviceFound(_:)), name: Notification.Name(KspNotificationTypes.BluetoothDeviceFound.rawValue), object: nil)
        
        
        
        

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
        print("Bluetooth device connected!")
    }
    
    @objc func onBluetoothDeviceConnecting(_ notification: Notification) {
        print("Bluetooth device connecting!")
    }
    
    @objc func onBluetoothDeviceConnectingFail(_ notification: Notification){
        print("Bluetooth device connecting fail!")
    }
    
    @objc func onBluetoothScanningStarted(_ notification: Notification) {
        print("Bluetooth device scan start!")
    }
    
    @objc func onBluetoothScanningStopped(_ notification: Notification){
        print("Bluetooth device scan stop!")
    }
    
    func startScanningForToothbrush(){
        bluetoothManager.startScanning()
    }
    
    func stopScanningForToothbrush(){
        bluetoothManager.stopScanning()
    }
}
