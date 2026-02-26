//
//  DailyJoyWidgetBundle.swift
//  DailyJoyWidget
//
//  Created by Amadeus Jackson on 2/24/26.
//

import WidgetKit
import SwiftUI

@main
struct DailyJoyWidgetBundle: WidgetBundle {
    var body: some Widget {
        DailyJoyStreakSmallWidget()
        DailyJoyAddSmallWidget()
        DailyJoyStreakAddSmallWidget()
        DailyJoyStreakAddMediumWidget()
        DailyJoyLargeWidget()
        DailyJoyLockWidget()
    }
}
