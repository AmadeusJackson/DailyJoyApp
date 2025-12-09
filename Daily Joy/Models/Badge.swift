//
//  Badge.swift
//  Daily Joy
//
//  Created by Amadeus Jackson on 11/20/25.
//

import Foundation
import SwiftData


@Model
class Badge {
    var details: BadgeDetails
    var moment: Moment?
    var timestamp: Date?


    init(details: BadgeDetails) {
        self.details = details
        self.moment = nil
        self.timestamp = nil
    }
}


extension Badge {
    static var sample: Badge {
        let badge = Badge(details: .firstEntry)
        badge.timestamp = .now
        return badge
    }
}
