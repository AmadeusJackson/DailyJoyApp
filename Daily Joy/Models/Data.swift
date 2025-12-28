//
//  Data.swift
//  Daily Joy
//
//  Created by Amadeus Jackson on 12/28/25.
//

import Foundation
import SwiftData

@Model
class Draft {
    var id: UUID
    var title: String
    var note: String
    var imageData: Data?
    var selectedColorName: String?
    var contentType: String // "photo" or "color"
    var isLocked: Bool
    var savedAt: Date
    
    init(
        id: UUID = UUID(),
        title: String,
        note: String,
        imageData: Data? = nil,
        selectedColorName: String? = nil,
        contentType: String = "photo",
        isLocked: Bool = false,
        savedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.note = note
        self.imageData = imageData
        self.selectedColorName = selectedColorName
        self.contentType = contentType
        self.isLocked = isLocked
        self.savedAt = savedAt
    }
}
