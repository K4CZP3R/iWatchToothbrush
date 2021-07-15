//
//  Helpers.swift
//  kacper WatchKit Extension
//
//  Created by Kacper Serewiś on 15/07/2021.
//

import Foundation

class Helpers {
    static func map(minRange:Int, maxRange:Int, minDomain:Int, maxDomain:Int, value:Int) -> Int {
        return minDomain + (maxDomain - minDomain) * (value - minRange) / (maxRange - minRange)
    }
}
