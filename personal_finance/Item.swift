//
//  Item.swift
//  personal_finance
//
//  Created by firstfu on 2026/2/17.
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
