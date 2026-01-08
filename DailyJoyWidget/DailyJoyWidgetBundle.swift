//
//  DailyJoyWidgetBundle.swift
//  DailyJoyWidget
//
//  Created by Amadeus Jackson on 1/7/26.
//

import WidgetKit
import SwiftUI

@main
struct DailyJoyWidgetBundle: WidgetBundle {
    var body: some Widget {
        DailyJoySmallWidget()
        DailyJoyMediumWidget()
        DailyJoyLockScreenWidget()
    }
}
