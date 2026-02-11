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
        // Row 1 - Blacks and Whites
        [
            Color("Black"),
            Color("Tundora"),
            Color("Dove Gray"),
            Color("Dusty Gray"),
            Color("Noble"),
            Color("Silver"),
            Color("Alto"),
            Color("Gallery"),
            Color("Concrete"),
            Color("White")
        ],
        // Row 2
        [
            Color("Red Berry"),
            Color("Red"),
            Color("California"),
            Color("Yellow"),
            Color("Green"),
            Color("Cyan"),
            Color("Cornflower Blue"),
            Color("Blue"),
            Color("Electric Violet"),
            Color("Magenta")
        ],
        // Row 3
        [
            Color("Shilo"),
            Color("Beauty Bush"),
            Color("Double Pearl Lusta"),
            Color("Barley White"),
            Color("Zanah"),
            Color("Geyser"),
            Color("Tropical Blue"),
            Color("Link Water"),
            Color("Snuff"),
            Color("Melanie")
        ],
        // Row 4
        [
            Color("Japonica"),
            Color("Sea Pink"),
            Color("Corvette"),
            Color("Cream Brulee"),
            Color("Sprout"),
            Color("Opal"),
            Color("Perano"),
            Color("Cornflower"),
            Color("Wistful"),
            Color("Careys Pink"),
        ],
        // Row 5
        [
            Color("Punch"),
            Color("Sunglo"),
            Color("Rajah"),
            Color("Dandelion"),
            Color("Olivine"),
            Color("Gulf Stream"),
            Color("Cornflower Blue"),
            Color("Havelock Blue"),
            Color("Purple Mountain's Majesty"),
            Color("Viola")
        ],
        // Row 6
        [
            Color("Milano Red"),
            Color("Guardsman Red"),
            Color("Fire Bush"),
            Color("Saffron"),
            Color("Chelsea Cucumber"),
            Color("Wedgewood"),
            Color("Royal Blue"),
            Color("Boston Blue"),
            Color("Butterfly Bush"),
            Color("Cadillac")
        ],
        // Row 7
        [
            Color("Tamarillo"),
            Color("Red Berry"),
            Color("Mai Tai"),
            Color("Pirate Gold"),
            Color("Forest Green"),
            Color("Eden"),
            Color("Denim"),
            Color("Venice Blue"),
            Color("Meteorite"),
            Color("Claret"),
        ],
        // Row 8
        [
            Color("Rosewood"),
            Color("Lonestar"),
            Color("Peru Tan"),
            Color("Olive"),
            Color("Green House"),
            Color("Elephant"),
            Color("Chathams Blue"),
            Color("Deep Sapphire"),
            Color("Valentino"),
            Color("Loulou"),
        ]
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Selected color preview
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
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
                                    
                                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                                        .fill(color)
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 30, style: .continuous)
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
                    .frame(maxWidth: 400)
                    .frame(maxWidth: 350)
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

