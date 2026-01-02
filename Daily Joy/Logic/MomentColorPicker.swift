//
//  ColorExtension.swift
//  Daily Joy
//
//  Created by Amadeus Jackson on 12/9/25.
//

/// ========================================
// ColorPickerSheet.swift
// ========================================

import SwiftUI

struct MomentColorPicker: View {
    @Binding var selectedColor: Color
    @Environment(\.dismiss) private var dismiss
    
    @State private var hue: Double = 0.0
    @State private var saturation: Double = 1.0
    @State private var brightness: Double = 1.0
    
    // Color grid - similar to iOS system picker
    let colorGrid: [[Color]] = [
        // Row 1 - Reds to Oranges
        [
            Color(hue: 0.0, saturation: 0.9, brightness: 0.9),
            Color(hue: 0.03, saturation: 0.9, brightness: 0.9),
            Color(hue: 0.05, saturation: 0.9, brightness: 0.9),
            Color(hue: 0.08, saturation: 0.9, brightness: 0.9),
            Color(hue: 0.1, saturation: 0.9, brightness: 0.9),
            Color(hue: 0.12, saturation: 0.9, brightness: 0.9),
        ],
        // Row 2 - Yellows to Greens
        [
            Color(hue: 0.15, saturation: 0.9, brightness: 0.95),
            Color(hue: 0.2, saturation: 0.8, brightness: 0.9),
            Color(hue: 0.25, saturation: 0.8, brightness: 0.85),
            Color(hue: 0.3, saturation: 0.8, brightness: 0.8),
            Color(hue: 0.33, saturation: 0.8, brightness: 0.75),
            Color(hue: 0.38, saturation: 0.8, brightness: 0.7),
        ],
        // Row 3 - Cyans to Blues
        [
            Color(hue: 0.5, saturation: 0.8, brightness: 0.9),
            Color(hue: 0.53, saturation: 0.8, brightness: 0.9),
            Color(hue: 0.58, saturation: 0.8, brightness: 0.85),
            Color(hue: 0.6, saturation: 0.85, brightness: 0.8),
            Color(hue: 0.63, saturation: 0.85, brightness: 0.75),
            Color(hue: 0.65, saturation: 0.85, brightness: 0.75),
        ],
        // Row 4 - Purples to Pinks
        [
            Color(hue: 0.7, saturation: 0.8, brightness: 0.85),
            Color(hue: 0.75, saturation: 0.7, brightness: 0.85),
            Color(hue: 0.8, saturation: 0.7, brightness: 0.9),
            Color(hue: 0.85, saturation: 0.6, brightness: 0.95),
            Color(hue: 0.9, saturation: 0.6, brightness: 0.95),
            Color(hue: 0.95, saturation: 0.7, brightness: 0.9),
        ],
        // Row 5 - Grays
        [
            Color(hue: 0.0, saturation: 0.0, brightness: 0.2),
            Color(hue: 0.0, saturation: 0.0, brightness: 0.35),
            Color(hue: 0.0, saturation: 0.0, brightness: 0.5),
            Color(hue: 0.0, saturation: 0.0, brightness: 0.65),
            Color(hue: 0.0, saturation: 0.0, brightness: 0.8),
            Color(hue: 0.0, saturation: 0.0, brightness: 0.95),
        ]
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Selected color preview
                    RoundedRectangle(cornerRadius: 20)
                        .fill(selectedColor)
                        .frame(height: 120)
                        .overlay(
                            Circle()
                                .strokeBorder(.white, lineWidth: 3)
                                .frame(width: 40, height: 40)
                        )
                        .padding(.horizontal)
                        .padding(.top)
                    
                    // Color grid
                    VStack(spacing: 8) {
                        ForEach(0..<colorGrid.count, id: \.self) { rowIndex in
                            HStack(spacing: 8) {
                                ForEach(0..<colorGrid[rowIndex].count, id: \.self) { colIndex in
                                    let color = colorGrid[rowIndex][colIndex]
                                    
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(color)
                                        .frame(height: 50)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .strokeBorder(.white, lineWidth: 2)
                                                .opacity(selectedColor.isApproximately(color) ? 1 : 0)
                                        )
                                        .onTapGesture {
                                            selectedColor = color
                                            extractHSB(from: color)
                                        }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Sliders section
                    VStack(spacing: 24) {
                        Text("Custom Color")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Hue slider
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Hue")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            HStack {
                                Slider(value: $hue, in: 0...1)
                                    .tint(Color(hue: hue, saturation: 1, brightness: 1))
                                    .onChange(of: hue) { _, _ in
                                        updateColor()
                                    }
                                
                                Text("\(Int(hue * 360))°")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 50)
                            }
                        }
                        
                        // Saturation slider
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Saturation")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            HStack {
                                Slider(value: $saturation, in: 0...1)
                                    .tint(Color(hue: hue, saturation: saturation, brightness: 1))
                                    .onChange(of: saturation) { _, _ in
                                        updateColor()
                                    }
                                
                                Text("\(Int(saturation * 100))%")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 50)
                            }
                        }
                        
                        // Brightness slider
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Brightness")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            HStack {
                                Slider(value: $brightness, in: 0...1)
                                    .tint(Color(hue: hue, saturation: 1, brightness: brightness))
                                    .onChange(of: brightness) { _, _ in
                                        updateColor()
                                    }
                                
                                Text("\(Int(brightness * 100))%")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 50)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("Choose Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .tint(Color("Ember"))
                }
            }
        }
        .onAppear {
            extractHSB(from: selectedColor)
        }
    }
    
    private func updateColor() {
        selectedColor = Color(hue: hue, saturation: saturation, brightness: brightness)
    }
    
    private func extractHSB(from color: Color) {
        let uiColor = UIColor(color)
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        
        hue = Double(h)
        saturation = Double(s)
        brightness = Double(b)
    }
}

// Helper extension to compare colors
extension Color {
    func isApproximately(_ other: Color) -> Bool {
        let uiColor1 = UIColor(self)
        let uiColor2 = UIColor(other)
        
        var h1: CGFloat = 0, s1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var h2: CGFloat = 0, s2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        uiColor1.getHue(&h1, saturation: &s1, brightness: &b1, alpha: &a1)
        uiColor2.getHue(&h2, saturation: &s2, brightness: &b2, alpha: &a2)
        
        let threshold: CGFloat = 0.05
        return abs(h1 - h2) < threshold &&
               abs(s1 - s2) < threshold &&
               abs(b1 - b2) < threshold
    }
}

#Preview {
    MomentColorPicker(selectedColor: .constant(Color(hue: 0.0, saturation: 0.8, brightness: 0.9)))
}

