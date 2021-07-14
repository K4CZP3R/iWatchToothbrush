//
//  ContentView.swift
//  kacper WatchKit Extension
//
//  Created by Kacper Serewiś on 14/07/2021.
//

import SwiftUI
import CoreBluetooth


struct ProgressBar: View {
    @Binding var progress: Float
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 10.0)
                .opacity(0.3)
                .foregroundColor(Color.red)
            Circle()
                .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 10.0, lineCap: .round, lineJoin: .round))
                .foregroundColor(Color.red)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear)
            Text(String(format: "%.0f %%", min(self.progress, 1.0)*100.0))
                .font(.caption)
                .bold()
        }
    }
}

struct ContentView: View {
var id = 123
    @ObservedObject var kspToothbrush = KspToothbrush()
    
    @State var bluetoothState = false
    @State var brushingTime = 0
    @State var timerActive = false
    @State var dataFromBle = false
    @State var dataFromBleTimeout = 0
    @State var quadrant = 0
    @State var tooHard = false
    @State var progressValue: Float = 0.0
    
    init(){
        
    }
    
    let newBrushData = NotificationCenter.default.publisher(for: Notification.Name("NewBrushData"))
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    let brushTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    
    
    var body: some View {
        
        
        VStack {
            Text(String(bluetoothState)).onReceive(timer) {
                (output) in self.doTimeTick()
            }
            if bluetoothState {
                ProgressBar(progress: self.$progressValue)
                    .frame(width: 30.0, height: 30.0)
                    .padding(15.0)
                    .onAppear{
                        kspToothbrush.startListening()
                    }
                    .onReceive(newBrushData) {
                        (output) in updateTimer()
                    }
                
                Text("Time: \(brushingTime)")
                    .onReceive(newBrushData) {
                        (output) in updateTimer()
                    }
                    .onReceive(brushTimer)
                {
                    (output) in incrementTimer()
                }
                Text("\(tooHard ? "Too hard" : "Ok.")")
                    .onReceive(newBrushData)
                {
                    (output) in updateTimer()
                }
                
                Button("Reenable") {
                    kspToothbrush.startListening()
                }
                Button("Disable") {
                    kspToothbrush.stopListening()
                }
            }
            else{
                Text("Bluetooth is OFF").foregroundColor(.red)
            }
            
            
            
            
        }
        

    }
    
    func updateTimer(){
        brushingTime = Int(kspToothbrush.fetchNewestTime())
        quadrant = Int(kspToothbrush.fetchQuadrant())
        progressValue = Float(quadrant - 1) * 0.25
        tooHard = kspToothbrush.fetchTooHard()
        
        if brushingTime != 0{
            timerActive = true;
        }
    }
    
    func incrementTimer(){
        if timerActive {
            print("Incrementing!")
            brushingTime += 1
            if(dataFromBle != true){
                dataFromBleTimeout += 1
            }
            else{
                dataFromBleTimeout = 0
            }
            
            if(dataFromBleTimeout > 5)
            {
                timerActive = false
            }
            
        }
    }
    
    
    func doTimeTick(){
        bluetoothState = kspToothbrush.bluetoothManager.isSwitchedOn
        
        if(bluetoothState)
        {
            self.timer.upstream.connect().cancel()
        }
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
