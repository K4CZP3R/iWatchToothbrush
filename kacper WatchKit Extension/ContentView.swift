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
    @ObservedObject var kspToothbrush: KspToothbrush
    
    @State var bluetoothState = false
    @State var progressValue: Float = 0.0
    
    init(){
        let toothbrushId = UUID(uuidString: KspUserStorage.getStringFromStorage(storageKey: .SavedToothbrush)!)
        kspToothbrush = KspToothbrush(toothbrushId: toothbrushId!)
        
    }
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    
    
    var body: some View {
        
        ScrollView {
            VStack {
                
                
                if bluetoothState {
                    Text("Waiting for the toothbrush...")
                }
                else{
                    Text("Allow this app to use bluetooth on your iWatch")
                    Text("Otherwise this app won't be able to communicate with your toothbrush").foregroundColor(.gray)
                }
            }.onReceive(timer) {
                (output) in self.doTimeTick()
            }
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
