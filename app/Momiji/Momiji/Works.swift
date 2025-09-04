//
//  Works.swift
//  Momiji
//
//  Created by Lennart Kotzur on 04.09.25.
//

import Foundation
import SwiftData

struct Work: Identifiable, Hashable {
    let id: UUID = .init()
    let url: URL
    var hash: String?
}
