//
//  ContentView.swift
//  kacper WatchKit Extension
//
//  Created by Kacper Serewiś on 14/07/2021.
//

import SwiftUI
import CoreBluetooth
import UIKit
import WatchKit

enum ToothbrushState : String {
    case NoConnection
    case Connecting
    case Connected
    case Error
}





struct ContentView: View {
var id = 123
    @ObservedObject var kspToothbrush: KspToothbrush
    var kspNotifications = KspNotifications()
    
    @State var bluetoothState = false
    @State var progressValue: Float = 0.0
    
    
    var toothbrushConnectingPub: NotificationCenter.Publisher
    var toothbrushConnectedPub: NotificationCenter.Publisher
    var toothbrushConnectingFailPub: NotificationCenter.Publisher
    var toothbrushDisconnectedPub: NotificationCenter.Publisher
    var toothrbushUpdatePub: NotificationCenter.Publisher
    
    @State var toothbrushState: ToothbrushState = .NoConnection
    
    init(){
        let toothbrushId = UUID(uuidString: KspUserStorage.getStringFromStorage(storageKey: .SavedToothbrush)!)
        kspToothbrush = KspToothbrush(toothbrushId: toothbrushId!)
        
        toothbrushConnectedPub = kspNotifications.getPublisher(notificationType: .ToothbrushConnected)
        toothbrushConnectingPub = kspNotifications.getPublisher(notificationType: .ToothbrushConnecting)
        toothbrushConnectingFailPub = kspNotifications.getPublisher(notificationType: .ToothbrushConnectingFail)
        toothbrushDisconnectedPub = kspNotifications.getPublisher(notificationType: .ToothbrushDisconnected)
        toothrbushUpdatePub = kspNotifications.getPublisher(notificationType: .ToothbrushUpdate)
        
    }
    
    @State var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State var connectedTimer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    
    @State var timePassed: Int = 0
    @State var currentSector: Int = 0
    @State var totalTime: Int = 0
    @State var tooHighPressure: Bool = false
    
    
    func simpleSuccess() {
    }
    
    var body: some View {
        
        ZStack {
            if tooHighPressure {
                Color.red.ignoresSafeArea().onAppear{
                    WKInterfaceDevice.current().play(.retry)
                }
           }
            
            ScrollView {
                
                VStack {
                    
                    if bluetoothState {
                        Text("Current state: \(toothbrushState.rawValue)")
                            .onReceive(toothbrushConnectedPub) {
                                (output) in self.onToothbrushConnected()
                            }
                            .onReceive(toothbrushConnectingPub) {
                                (output) in self.onToothbrushConnecting()
                            }
                            .onReceive(toothbrushConnectingFailPub) {
                                (output) in self.onToothbrushConnectingFail()
                            }
                            .onReceive(toothbrushDisconnectedPub) {
                                (output) in self.onToothbrushDisconnected()
                            }
                        
                        if toothbrushState == .Connected{
                            CircleProgressBarView(progress: $progressValue).frame(width: 75.0, height: 75.0, alignment: .center)
                            Text("Time passed: \(timePassed)s")
                            
                            NavigationLink(destination: ToothbrushInfoView()){
                                Text("View brush info")
                            }
                        }
                        
                        
                    }
                    else{
                        Text("Allow this app to use bluetooth on your iWatch")
                        Text("Otherwise this app won't be able to communicate with your toothbrush").foregroundColor(.gray)
                    }
                }.onReceive(timer) {
                    (output) in self.doTimeTick()
                }.onReceive(connectedTimer) {
                    (output) in self.doConnectionCheckTick()
                }.onReceive(toothrbushUpdatePub)
                {
                    (output) in self.onToothbrushUpdate(output)
                }
                
                
            }.navigationTitle("Brushing")
            
            
            
        }
    }
    
    func onToothbrushUpdate(_ notification: Notification){
        let toothbrushData = notification.object as! ToothbrushData
        
        switch toothbrushData.type {
        case .BRUSHING_TIME:
            timePassed = toothbrushData.value as! Int
            
            print("Total time: \(totalTime)")
            if totalTime > 0 {
                let circlePercentage = Helpers.map(minRange: 0, maxRange: totalTime, minDomain: 0, maxDomain: 100, value: timePassed)
                print("Cicrcle per: \(circlePercentage)")
                
                progressValue = Float(circlePercentage) / 100.0
                print("prog val: \(progressValue)")
            }
        case .CURRENT_SECTOR:
            currentSector = toothbrushData.value as! Int
            //progressValue = Float(currentSector) * 0.25
        case .SECTOR_TIME:
            let optionalOrg = toothbrushData.value as! [Int]?
            totalTime = 0
            if let unwrapped = optionalOrg {
                print("unwrapped sectors: \(unwrapped)")
                for sectorTime in unwrapped {
                    totalTime += sectorTime
                }
            }
        case .PRESSURE_SENSOR:
            let optionalOrg = toothbrushData.value as! Int?
            if let unwrapped = optionalOrg {
                tooHighPressure = unwrapped > 0
                if tooHighPressure {
                    kspNotifications.notify(notificationType: .DoVibrate, notifObj: nil)
                }
            }
        default:
            
            print("Not implemented: \(toothbrushData.type)")
        }
        
        
    }
    
    func onToothbrushConnected(){
        toothbrushState = .Connected
        
    }
    func onToothbrushConnecting(){
        toothbrushState = .Connecting
    }
    func onToothbrushConnectingFail(){
        toothbrushState = .Error
    }
    func onToothbrushDisconnected(){
        toothbrushState = .NoConnection
        createTimer()
    }
    func createTimer(){
        self.timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        
    }
    func doConnectionCheckTick(){
        if toothbrushState == .Connected && kspToothbrush.bluetoothManager.connectedDeviceRef == nil {
            print("Needs to disconnect!")
            kspNotifications.notify(notificationType: .BluetoothDeviceDisconnected, notifObj: nil)
        }
    }
    
    func doTimeTick(){
        print("Checking bluetooth state...")
        bluetoothState = kspToothbrush.bluetoothManager.isSwitchedOn
        
        if(bluetoothState)
        {
            self.timer.upstream.connect().cancel()
            kspToothbrush.startScanningForToothbrush()
        }
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
