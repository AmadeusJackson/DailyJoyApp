import SwiftUI
import PhotosUI
import SwiftData

struct MomentEntryView: View {
    @State private var title = ""
    @State private var note = ""
    @State private var imageData: Data?
    @State private var newImage: PhotosPickerItem?
    @State private var isShowingCancelConfirmation = false
    @State private var isLocked: Bool = false
    
    @State private var contentType: ContentType = .photo
    @State private var selectedColorName: String = "Ember"
    
    // TEMPORARY - For testing Memory Lane
    @State private var customDate = Date()
    @State private var useCustomDate = false
    
    @Environment(\.dismiss) private var dismiss
    @Environment(DataContainer.self) private var dataContainer
    
    enum ContentType {
        case photo
        case color
    }
    
    let availableColors = ["Ember", "Forest", "Lavender", "Ocean", "Pearl", "Rose", "Ruby", "Sapphire", "Sky"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Title (Required)")) {
                    TextField("What made you happy?", text: $title)
                        .font(.headline)
                        .accessibilityLabel("Moment title")
                        .accessibilityHint("Enter what made you happy today")
                }
                
                Section(header: Text("Note")) {
                    TextEditor(text: $note)
                        .frame(minHeight: 100)
                        .accessibilityLabel("Moment note")
                        .accessibilityHint("Add additional details about this moment")
                }
                
                Section(header: Text("Background Type")) {
                    Picker("Type", selection: $contentType) {
                        Text("Photo").tag(ContentType.photo)
                        Text("Color").tag(ContentType.color)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("Background type")
                    .accessibilityHint("Choose between photo or color background")
                }
                
                if contentType == .photo {
                    Section(header: Text("Photo (Optional)")) {
                        photoPicker
                    }
                } else {
                    Section(header: Text("Choose a Color")) {
                        colorPicker
                    }
                }
                
                Section {
                    Toggle(isOn: $isLocked) {
                        HStack {
                            Image(systemName: isLocked ? "lock.fill" : "lock.open")
                                .foregroundColor(isLocked ? .blue : .gray)
                            Text("Lock this moment")
                        }
                    }
                    .accessibilityLabel("Lock moment")
                    .accessibilityValue(isLocked ? "Locked" : "Unlocked")
                    .accessibilityHint("Locked moments require Face ID to view")
                } header: {
                    Text("Privacy")
                } footer: {
                    Text("Locked moments require Face ID or passcode to view")
                }
                
                // TEMPORARY - For testing Memory Lane
                #if DEBUG
                Section(header: Text("🧪 Test: Custom Date")) {
                    Toggle("Use Custom Date", isOn: $useCustomDate)
                    
                    if useCustomDate {
                        DatePicker("Select Date", selection: $customDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                    }
                }
                #endif
            }
            .navigationTitle("Grateful For")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if title.isEmpty, note.isEmpty, imageData == nil {
                            dismiss()
                        } else {
                            isShowingCancelConfirmation = true
                        }
                    }
                    .tint(Color("Ember"))
                    .accessibilityLabel("Cancel")
                    .accessibilityHint("Discard this moment")
                    .confirmationDialog("Discard Moment", isPresented: $isShowingCancelConfirmation) {
                        Button("Discard Moment", role: .destructive) {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        saveMoment()
                    }
                    .tint(Color("Ember"))
                    .disabled(title.isEmpty)
                    .accessibilityLabel("Add moment")
                    .accessibilityHint(title.isEmpty ? "Enter a title first" : "Save this grateful moment")
                }
            }
        }
    }
    
    private var photoPicker: some View {
        PhotosPicker(selection: $newImage) {
            Group {
                if let imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.badge.plus.fill")
                            .font(.largeTitle)
                            .foregroundStyle(Color("Ember"))
                        Text("Add Photo")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(height: 250)
                    .frame(maxWidth: .infinity)
                    .background(Color(white: 0.4, opacity: 0.32))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .onChange(of: newImage) {
            guard let newImage else { return }
            Task {
                imageData = try await newImage.loadTransferable(type: Data.self)
            }
        }
    }
    
    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 80))
            ], spacing: 16) {
                ForEach(availableColors, id: \.self) { colorName in
                    ColorOption(
                        colorName: colorName,
                        isSelected: selectedColorName == colorName
                    )
                    .onTapGesture {
                        selectedColorName = colorName
                    }
                }
            }
            
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(selectedColorName))
                .frame(height: 200)
                .overlay(
                    VStack {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                )
        }
    }
    
    private func saveMoment() {
        let finalImageData: Data?
        
        if contentType == .color {
            finalImageData = createColorImage(colorName: selectedColorName)
        } else {
            finalImageData = imageData
        }
        
        let newMoment = Moment(
            title: title,
            note: note,
            imageData: finalImageData,
            timestamp: useCustomDate ? customDate : .now,
            isLocked: isLocked
        )
        
        dataContainer.context.insert(newMoment)
        do {
            try dataContainer.badgeManager.unlockBadges(newMoment: newMoment)
            
            // ✅ CHECK FOR CHALLENGE COMPLETION
            dataContainer.challengeManager.checkChallengeCompletion(for: newMoment)
            
            try dataContainer.context.save()
            dismiss()
        } catch {
            // Don't dismiss
        }
    }
    
    private func createColorImage(colorName: String) -> Data? {
        let size = CGSize(width: 500, height: 500)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            UIColor(Color(colorName)).setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        
        return image.pngData()
    }
}

struct ColorOption: View {
    let colorName: String
    let isSelected: Bool
    
    let lightColors = ["Pearl", "Lavender", "Sky", "Rose"]
    
    var borderColor: Color {
        if lightColors.contains(colorName) {
            return Color.gray.opacity(0.3)
        }
        return Color.white.opacity(0.2)
    }
    
    var checkmarkColor: Color {
        if lightColors.contains(colorName) {
            return Color.black
        }
        return Color.white
    }
    
    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(colorName))
                .frame(height: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(borderColor, lineWidth: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.primary, lineWidth: isSelected ? 3 : 0)
                )
                .overlay(
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                        .foregroundStyle(checkmarkColor)
                        .opacity(isSelected ? 1 : 0)
                )
            
            Text(colorName)
                .font(.caption)
                .foregroundStyle(isSelected ? .primary : .secondary)
        }
    }
}

#Preview {
    MomentEntryView()
        .sampleDataContainer()
}
