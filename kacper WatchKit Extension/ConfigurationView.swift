//
//  ConfigurationView.swift
//  kacper WatchKit Extension
//
//  Created by Kacper Serewiś on 15/07/2021.
//

import Foundation
import SwiftUI


struct ConfigurationView: View {
    @State var toothbrushToBeAdded = KspUserStorage.getStringFromStorage(storageKey: .SavedToothbrush) == nil
    
    var kspNotifications = KspNotifications()
    var toothbrushSelectedPublisher: NotificationCenter.Publisher
    
    
    init(){
        toothbrushSelectedPublisher = kspNotifications.getPublisher(notificationType: .ToothbrushSelected)
        
    }
    
    var body: some View {
        if toothbrushToBeAdded {
            ToothbrushSelectorView()
                .onReceive(toothbrushSelectedPublisher) {
                    (output) in updateToothbrushState()
                }
        }
        else{
            ContentView()
        }
        
    }
    
    func updateToothbrushState(){
        print("Updating toothbrush state")
        toothbrushToBeAdded = KspUserStorage.getStringFromStorage(storageKey: .SavedToothbrush) == nil
    }
}

struct ConfigurationView_Previews: PreviewProvider {
    static var previews: some View {
        ConfigurationView()
    }
}
