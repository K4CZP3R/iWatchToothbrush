//
//  KspNotifications.swift
//  kacper WatchKit Extension
//
//  Created by Kacper Serewiś on 15/07/2021.
//

import Foundation

enum KspNotificationTypes : String {
    case ToothbrushConnected
    case ToothbrushConnecting
    case ToothbrushConnectingFail
    case ToothbrushDisconnected
    case BluetoothDeviceConnecting
    case BluetoothDeviceConnected
    case BluetoothDeviceConnectingFail
    case BluetoothScanningStarted
    case BluetoothScanningStopped
    case BluetoothDeviceFound
    case BluetoothDeviceDisconnected
    case ToothbrushSelected
    case BluetoothCharUpdate
    case ToothbrushUpdate
    case RequestCachedToothbrushDatas
    case CachedToothbrushDatas
    case DoVibrate
}

class KspNotifications {
    func notify(notificationType: KspNotificationTypes, notifObj: Any?){
        NotificationCenter.default.post(name: Notification.Name(notificationType.rawValue), object: notifObj)
    }
    func getPublisher(notificationType: KspNotificationTypes) -> NotificationCenter.Publisher {
        return NotificationCenter.default.publisher(for:  Notification.Name(notificationType.rawValue), object: nil)
    }
}
