//
//  DailyJoyWidgetBundle.swift
//  DailyJoyWidget
//
//  Created by Amadeus Jackson on 11/28/25.
//

import WidgetKit
import SwiftUI

@main
struct DailyJoyWidgetBundle: WidgetBundle {
    var body: some Widget {
        StreakWidget()                // Home screen streak
        MomentWidget()                // Home screen moment
        LockScreenStreakWidget()      // Lock screen streak
    }
}
