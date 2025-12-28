import SwiftUI
import PhotosUI
import SwiftData
internal import Speech

struct MomentEntryView: View {
    @State private var title = ""
    @State private var note = ""
    @State private var imageData: Data?
    @State private var newImage: PhotosPickerItem?
    @State private var isShowingCancelConfirmation = false
    @State private var isLocked: Bool = false
    @State private var showDraftAlert = false
    @State private var existingDraft: Draft?
    
    @State private var contentType: ContentType = .photo
    @State private var selectedColorName: String = "Ember"
    
    // TEMPORARY - For testing Memory Lane (COMMENTED OUT FOR SUBMISSION)
//    @State private var customDate = Date()
//    @State private var useCustomDate = false
    
    // NEW: Reflection pause state
    @State private var showingSaveConfirmation = false
    
    // NEW: Voice logging
    @State private var voiceManager = VoiceLoggingManager()
    @State private var showVoicePermissionAlert = false
    
    @Environment(\.dismiss) private var dismiss
    @Environment(DataContainer.self) private var dataContainer
    @Environment(\.modelContext) private var modelContext
    @FocusState private var focusedField: Field?
    
    enum ContentType {
        case photo
        case color
    }
    
    enum Field: Hashable {
        case title
        case note
    }
    
    let availableColors = ["Ember", "Forest", "Lavender", "Ocean", "Pearl", "Rose", "Ruby", "Sapphire", "Sky"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Form {
                    Section {
                        HStack {
                            TextField("What made you happy?", text: $title)
                                .font(.headline)
                                .focused($focusedField, equals: .title)
                                .accessibilityLabel("Moment title")
                                .accessibilityHint("Enter what made you happy today")
                            
                            // Voice input button
                            Button {
                                handleVoiceInput()
                            } label: {
                                Image(systemName: voiceManager.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(voiceManager.isRecording ? .red : Color("Ember"))
                                    .symbolEffect(.pulse, options: .repeating, isActive: voiceManager.isRecording)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(voiceManager.isRecording ? "Stop recording" : "Record with voice")
                        }
                    } header: {
                        Text("Title (Required)")
                    } footer: {
                        if voiceManager.isRecording {
                            HStack {
                                Image(systemName: "waveform")
                                    .symbolEffect(.variableColor.iterative, options: .repeating)
                                Text("Listening...")
                                    .foregroundStyle(.secondary)
                            }
                            .font(.caption)
                        }
                    }
                    
                    Section {
                        TextEditor(text: $note)
                            .frame(minHeight: 100)
                            .focused($focusedField, equals: .note)
                            .accessibilityLabel("Moment note")
                            .accessibilityHint("Add additional details about this moment")
                    } header: {
                        Text("Note (Optional)")
                    } footer: {
                        Text("A title is enough! Add details only if you want to.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Section {
                        Picker("Type", selection: $contentType) {
                            Text("Photo").tag(ContentType.photo)
                            Text("Color").tag(ContentType.color)
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: contentType) { _, _ in
                            focusedField = nil
                        }
                        .accessibilityLabel("Background type")
                        .accessibilityHint("Choose between photo or color background")
                    } header: {
                        Text("Background Type")
                    }
                    
                    if contentType == .photo {
                        Section {
                            photoPicker
                        } header: {
                            Text("Photo (Optional)")
                        }
                    } else {
                        Section {
                            colorPicker
                        } header: {
                            Text("Choose a Color")
                        }
                    }
                    
                    Section {
                        Toggle(isOn: $isLocked) {
                            HStack {
                                Image(systemName: isLocked ? "lock.fill" : "lock.open")
                                    .foregroundColor(isLocked ? .orange : .gray)
                                Text("Lock this moment")
                            }
                        }
                        .onChange(of: isLocked) { _, _ in
                            focusedField = nil
                        }
                        .accessibilityLabel("Lock moment")
                        .accessibilityValue(isLocked ? "Locked" : "Unlocked")
                        .accessibilityHint("Locked moments require Face ID to view")
                    } header: {
                        Text("Privacy")
                    } footer: {
                        Text("Locked moments require Face ID or passcode to view")
                    }
                    
                    // TEMPORARY - For testing Memory Lane (COMMENTED OUT FOR SUBMISSION)
//                    #if DEBUG
//                    Section {
//                        Toggle("Use Custom Date", isOn: $useCustomDate)
//
//                        if useCustomDate {
//                            DatePicker("Select Date", selection: $customDate, displayedComponents: [.date, .hourAndMinute])
//                                .datePickerStyle(.compact)
//                        }
//                    } header: {
//                        Text("🧪 Test: Custom Date")
//                    }
//                    #endif
                }
                .scrollDismissesKeyboard(.immediately)
                .blur(radius: showingSaveConfirmation ? 3 : 0)
                .disabled(showingSaveConfirmation)
                
                // NEW: Save confirmation overlay
                if showingSaveConfirmation {
                    SaveConfirmationView()
                        .transition(.scale.combined(with: .opacity))
                }
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
                    .confirmationDialog("Save as Draft?", isPresented: $isShowingCancelConfirmation) {
                        Button("Save Draft") {
                            saveDraft()
                            dismiss()
                        }
                        Button("Discard", role: .destructive) {
                            if let draft = existingDraft {
                                deleteDraft(draft)
                            }
                            dismiss()
                        }
                        Button("Keep Editing", role: .cancel) {}
                    } message: {
                        Text("You have unsaved changes. Would you like to save as a draft?")
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
                
                // NEW: Done button to dismiss keyboard (only shows when keyboard is visible)
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button {
                        focusedField = nil
                    } label: {
                        Text("Done")
                            .fontWeight(.semibold)
                    }
                    .tint(Color("Ember"))
                }
            }
        }
        .onAppear {
            loadDraft()
        }
        .alert("Continue Draft?", isPresented: $showDraftAlert) {
            Button("Continue") {
                if let draft = existingDraft {
                    loadFromDraft(draft)
                }
            }
            Button("Start Fresh") {
                if let draft = existingDraft {
                    deleteDraft(draft)
                }
            }
        } message: {
            Text("You have an unfinished moment. Would you like to continue where you left off?")
        }
        .alert("Enable Microphone", isPresented: $showVoicePermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("To use voice input, please enable microphone access in Settings.")
        }
        .onChange(of: voiceManager.transcribedText) { oldValue, newValue in
            // Auto-fill title with transcribed text
            if !newValue.isEmpty && newValue != oldValue {
                title = newValue
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
                        focusedField = nil // Dismiss keyboard when selecting color
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
            timestamp: .now, // TEMPORARY: useCustomDate ? customDate : .now (commented out for submission)
            isLocked: isLocked
        )
        
        dataContainer.context.insert(newMoment)
        do {
            try dataContainer.badgeManager.unlockBadges(newMoment: newMoment)
            
            // ✅ CHECK FOR CHALLENGE COMPLETION
            dataContainer.challengeManager.checkChallengeCompletion(for: newMoment)
            
            try dataContainer.context.save()
            
            // Delete draft after successful save
            if let draft = existingDraft {
                deleteDraft(draft)
            }
            
            // ✅ UPDATE NOTIFICATION SCHEDULE based on new logging pattern
            Task {
                await dataContainer.notificationManager.updateScheduleAfterNewMoment()
            }
            
            // Dismiss keyboard before showing confirmation
            focusedField = nil
            
            // NEW: Show reflection pause instead of immediate dismiss
            withAnimation(.easeInOut(duration: 0.3)) {
                showingSaveConfirmation = true
            }
            
            // Dismiss after brief pause
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                dismiss()
            }
            
        } catch {
            // Don't dismiss
        }
    }
    
    // MARK: - Draft Functions
    
    private func loadDraft() {
        let descriptor = FetchDescriptor<Draft>(sortBy: [SortDescriptor(\.savedAt, order: .reverse)])
        
        if let drafts = try? modelContext.fetch(descriptor),
           let draft = drafts.first {
            existingDraft = draft
            showDraftAlert = true
        }
    }
    
    private func loadFromDraft(_ draft: Draft) {
        title = draft.title
        note = draft.note
        imageData = draft.imageData
        selectedColorName = draft.selectedColorName ?? "Ember"
        contentType = draft.contentType == "color" ? .color : .photo
        isLocked = draft.isLocked
    }
    
    private func saveDraft() {
        // Only save if there's content
        guard !title.isEmpty || !note.isEmpty || imageData != nil else { return }
        
        // Delete any existing draft
        if let existing = existingDraft {
            deleteDraft(existing)
        }
        
        let draft = Draft(
            title: title,
            note: note,
            imageData: imageData,
            selectedColorName: selectedColorName,
            contentType: contentType == .color ? "color" : "photo",
            isLocked: isLocked
        )
        
        modelContext.insert(draft)
        try? modelContext.save()
    }
    
    private func deleteDraft(_ draft: Draft) {
        modelContext.delete(draft)
        try? modelContext.save()
        existingDraft = nil
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
    
    // MARK: - Voice Input
    
    private func handleVoiceInput() {
        if voiceManager.isRecording {
            // Stop recording
            voiceManager.stopRecording()
        } else {
            // Check authorization first
            if voiceManager.authorizationStatus == .notDetermined {
                Task {
                    let granted = await voiceManager.requestAuthorization()
                    if granted {
                        startVoiceRecording()
                    } else {
                        showVoicePermissionAlert = true
                    }
                }
            } else if voiceManager.canRecord {
                startVoiceRecording()
            } else {
                showVoicePermissionAlert = true
            }
        }
    }
    
    private func startVoiceRecording() {
        // Clear current title to show fresh recording
        title = ""
        voiceManager.reset()
        
        do {
            try voiceManager.startRecording()
        } catch {
            voiceManager.errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Save Confirmation View

struct SaveConfirmationView: View {
    @State private var scale: CGFloat = 0.8
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundStyle(Color("Ember"))
                .scaleEffect(scale)
            
            Text("Moment Saved")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Take a breath")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
        )
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1.0
            }
        }
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
