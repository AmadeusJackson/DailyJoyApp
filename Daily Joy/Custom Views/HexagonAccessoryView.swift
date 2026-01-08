//
//  HexagonAccessoryView.swift
//  Daily Joy
//
//  Created by Amadeus Jackson on 11/24/25.
//

import SwiftUI

struct HexagonAccessoryView: View {
    let moment: Moment
    let hexagonLayout: HexagonLayout
    
    var body: some View {
        // Badges feature not implemented yet
        // This view will be empty until badges are added
        EmptyView()
    }
}

#Preview("Single badge") {
    MomentHexagonView(moment: .sample, layout: .large)
        .sampleDataContainer()
}

#Preview("Multiple badges") {
    MomentHexagonView(moment: .imageSample, layout: .standard)
        .dynamicTypeSize(.large)
        .sampleDataContainer()
}
