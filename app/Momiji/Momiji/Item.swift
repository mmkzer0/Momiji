//
//  Item.swift
//  Momiji
//
//  Created by Lennart Kotzur on 03.09.25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
