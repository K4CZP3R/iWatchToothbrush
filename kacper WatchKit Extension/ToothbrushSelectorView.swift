//
//  ToothbrushSelectorView.swift
//  kacper WatchKit Extension
//
//  Created by Kacper Serewiś on 15/07/2021.
//

import Foundation
import SwiftUI


struct ToothbrushSelectorView: View {
    
    @ObservedObject var bleManager = BLEManager()
    
    var kspNotifications = KspNotifications()
    @State var bluetoothState = false
    
    let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    
    var newBluetoothDeviceFound: NotificationCenter.Publisher
    
    init(){
        newBluetoothDeviceFound = kspNotifications.getPublisher(notificationType: .BluetoothDeviceFound)
    }
    var body: some View {
        VStack {
            
            if bluetoothState {
                
                List {
                    ForEach(bleManager.foundDevices){
                        item in Button(String(item.name)) {
                            bleManager.stopScanning()
                            saveToothbrush(bluetoothDevice: item)
                        }
                    }
                    
                }
                .onReceive(newBluetoothDeviceFound){
                    (output) in self.onNewBluetoothDeviceFound()
                }
            }
            else{
                Text("Allow this app to use bluetooth on your iWatch")
                Text("Otherwise this app won't be able to communicate with your toothbrush").foregroundColor(.gray)
            }
            
            
        }.navigationTitle(Text("Scanner"))
            .onReceive(timer) {
                (output) in self.doTimerTick()
            }
    }
    func onNewBluetoothDeviceFound(){
        print("New device found!")
    }
    func saveToothbrush(bluetoothDevice: BluetoothDevice)
    {
        KspUserStorage.saveStringToStorage(storageKey: .SavedToothbrush, value: bluetoothDevice.id.uuidString)
        
        kspNotifications.notify(notificationType: .ToothbrushSelected, notifObj: nil)
    }
    
    func doTimerTick(){
        print("Checking bluetooth state...")
        bluetoothState = bleManager.isSwitchedOn
        
        if(bluetoothState)
        {
            bleManager.startScanning()
            self.timer.upstream.connect().cancel()
        }
        
    }
}


struct ToothbrushSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        ToothbrushSelectorView()
    }
}
