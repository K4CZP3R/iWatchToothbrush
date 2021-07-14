//
//  KspToothbrush.swift
//  kacper WatchKit Extension
//
//  Created by Kacper Serewiś on 14/07/2021.
//

import Foundation
import SwiftUI


public class KspToothbrush: ObservableObject {
    @ObservedObject var bluetoothManager = BLEManager()
    
    
    func fetchQuadrant() -> UInt8 {
        let keyExists = bluetoothManager.manufacturerData["33C9C672-14BE-97A0-69F8-E48E04576571"] != nil
        
        if keyExists {
            print("Toothbrush was seen!")
            
            return bluetoothManager.manufacturerData["33C9C672-14BE-97A0-69F8-E48E04576571"]![10]
            
            
        }
        print("Still no toothbrush!")
        return 0
    }
    func fetchTooHard() -> Bool {
        let keyExists = bluetoothManager.manufacturerData["33C9C672-14BE-97A0-69F8-E48E04576571"] != nil
        
        if keyExists {
            print("Toothbrush was seen!")
            
            return bluetoothManager.manufacturerData["33C9C672-14BE-97A0-69F8-E48E04576571"]![6] == 192
            
            
        }
        print("Still no toothbrush!")
        return false
    }
    func fetchNewestTime() -> UInt8 {
        let keyExists = bluetoothManager.manufacturerData["33C9C672-14BE-97A0-69F8-E48E04576571"] != nil
        
        if keyExists {
            print("Toothbrush was seen!")
            
            return bluetoothManager.manufacturerData["33C9C672-14BE-97A0-69F8-E48E04576571"]![8]
            
            
        }
        print("Still no toothbrush!")
        return 0
        
    }

    
    
    func startListening(){
        print("Starting disco")
        bluetoothManager.startScanning()
    }
    
    func stopListening(){
        bluetoothManager.stopScanning()
    }
}
