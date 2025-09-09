//
//  Works.swift
//  Momiji
//
//  Created by Lennart Kotzur on 04.09.25.
//

import Foundation
import SwiftData

struct Work: Identifiable, Hashable, Codable {
    let id: UUID
    let url: URL
    var hash: String?
    var pageCount: Int?
    
    // init all fields on param except UUID
    init(id: UUID = UUID(), url: URL, hash: String? = nil, pageCount: Int? = nil) {
        self.id = id
        self.url = url
        self.hash = hash
        self.pageCount = pageCount
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, url, hash, pageCount
    }
    
    // decode UUID if given, else generate
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.url = try container.decode(URL.self, forKey: .url)
        self.hash = try container.decodeIfPresent(String.self, forKey: .hash)
        self.pageCount = try container.decodeIfPresent(Int.self, forKey: .pageCount)
    }
}
