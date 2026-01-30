 // ========================================
// 'MomentEntryView'.swift
// ========================================

import SwiftUI
import PhotosUI
import SwiftData
internal import Speech
import Photos
import AVFoundation
import UIKit

struct MomentEntryView: View {
    var existingMoment: Moment? = nil
    var onSaved: (() -> Void)? = nil

    @State private var title = ""
    @State private var note = ""
    @State private var imageData: Data?
    @State private var isShowingCancelConfirmation = false
    @State private var isLocked: Bool = false
    @State private var showDraftAlert = false
    @State private var existingDraft: Draft?
    @State private var showPhotoOptions = false
    @State private var contentType: ContentType = .photo
    @State private var selectedColor: Color = Color(white: 0.4, opacity: 0.32)
    @State private var showColorPicker = false
    
    @State private var showPhotoLibrary = false
    @State private var showCameraPermissionAlert = false
    
    // NEW: Camera support
    @State private var showCamera = false
    
    // NEW: Voice logging
    @State private var voiceManager = VoiceLoggingManager()
    @State private var showVoicePermissionAlert = false
    @State private var isEditing: Bool = false
    
    @Environment(\.dismiss) private var dismiss
    @Environment(DataContainer.self) private var dataContainer
    @Environment(\.modelContext) private var modelContext
    @FocusState private var focusedField: Field?
    
    enum ContentType: String, Sendable {
        case photo
        case color
    }
    
    enum Field: Hashable {
        case title
        case note
    }
    
    private var titleSection: some View {
        Section {
            HStack {
                TextField("What made you happy?", text: $title)
                    .font(.headline)
                    .focused($focusedField, equals: .title)
                    .accessibilityLabel("Moment title")
                    .accessibilityHint("Enter what made you happy today")

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
    }

    private var noteSection: some View {
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
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Form {
                    titleSection
                    
                    noteSection
                    
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
                            addPhotoView
                        } header: {
                            Text("Photo (Optional)")
                        }
                    } else {
                        Section {
                            colorButton
                        } header: {
                            Text("Color (Optional)")
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
                }
                .scrollDismissesKeyboard(.immediately)
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
                    Button(isEditing ? "Done" : "Add") {
                        // Haptic feedback to confirm tap on device
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        addMomentTapped()
                    }
                    .tint(Color("Ember"))
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityLabel(isEditing ? "Save changes" : "Add moment")
                    .accessibilityHint(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Enter a title first" : (isEditing ? "Save your edits" : "Save this grateful moment"))
                }
            }
            .sheet(isPresented: $showColorPicker) {
                MomentColorPicker(selectedColor: $selectedColor)
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker(imageData: $imageData)
            }
            .sheet(isPresented: $showPhotoLibrary) {
                PhotoLibraryPicker(imageData: $imageData)
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
            .alert("Enable Camera", isPresented: $showCameraPermissionAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("To take a photo, please enable camera access in Settings.")
            }
            .onChange(of: voiceManager.transcribedText) { oldValue, newValue in
                // Auto-fill title with transcribed text
                if !newValue.isEmpty && newValue != oldValue {
                    title = newValue
                }
            }
            .onAppear {
                // Ensure badges exist in the data store
                try? dataContainer.badgeManager.loadBadgesIfNeeded()
                if let m = existingMoment {
                    // Enter edit mode and prefill fields
                    isEditing = true
                    title = m.title
                    note = m.note
                    imageData = m.imageData
                    isLocked = m.isLocked
                    // Determine content type based on whether imageData is a color image
                    if let data = m.imageData, let img = UIImage(data: data), img.size == CGSize(width: 500, height: 500) {
                        contentType = .color
                        // selectedColor cannot be perfectly recovered; leave as default color swatch
                    } else {
                        contentType = .photo
                    }
                } else {
                    loadDraft()
                }
            }
        }
    }
    
    private var addPhotoView: some View {
        ZStack {
            // 🔹 Your visible UI
            Button {
                showPhotoOptions = true
            } label: {
                Group {
                    if let imageData,
                       let uiImage = UIImage(data: imageData) {

                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()

                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "photo.fill")
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
            .confirmationDialog("Add Photo", isPresented: $showPhotoOptions) {
                
                Button("Take Photo") {
                    showPhotoOptions = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        let status = AVCaptureDevice.authorizationStatus(for: .video)
                        switch status {
                        case .authorized:
                            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                showCamera = true
                            } else {
                                // If no camera, fall back to photo library
                                showPhotoLibrary = true
                            }
                        case .notDetermined:
                            AVCaptureDevice.requestAccess(for: .video) { granted in
                                DispatchQueue.main.async {
                                    if granted {
                                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                            showCamera = true
                                        } else {
                                            showPhotoLibrary = true
                                        }
                                    } else {
                                        showCameraPermissionAlert = true
                                    }
                                }
                            }
                        case .denied, .restricted:
                            showCameraPermissionAlert = true
                        @unknown default:
                            showCameraPermissionAlert = true
                        }
                    }
                }
                
                Button("Choose from Photos") {
                    showPhotoOptions = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        showPhotoLibrary = true
                    }
                }
            }
        }
    }

    
    private var colorButton: some View {
        Button {
            showColorPicker = true
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(selectedColor)
                    .frame(height: 250)
                
                // Only show icon and text if still using default gray
                if selectedColor == Color(white: 0.4, opacity: 0.32) {
                    VStack(spacing: 12) {
                        Image(systemName: "paintpalette.fill")
                            .font(.largeTitle)
                            .foregroundStyle(Color("Ember"))
                        Text("Add Color")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    @MainActor
    private func addMomentTapped() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            // Haptic error feedback for invalid input
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            return
        }
        // Keep the original title value for storage (you can also assign trimmed if desired)
        if isEditing {
            saveEdits()
        } else {
            saveMoment()
        }
    }
    
    @MainActor
    private func saveMoment() {
        let finalImageData: Data?
        
        if contentType == .color {
            finalImageData = createColorImage(color: selectedColor)
        } else {
            finalImageData = imageData
        }
        
        let newMoment = Moment(
            title: title,
            note: note,
            imageData: finalImageData,
            timestamp: .now,
            isLocked: isLocked
        )
        
        do {
            // Insert and save via the same SwiftData modelContext that the list observes
            modelContext.insert(newMoment)
            try modelContext.save()
            
            // ✅ UNLOCK ACHIEVEMENT BADGES for this new moment
            do {
                try dataContainer.badgeManager.unlockBadges(newMoment: newMoment)
            } catch {
                print("Failed to unlock badges: \(error)")
            }
            
            // Ensure badge updates are persisted
            try? modelContext.save()
            
            // ✅ CHECK FOR CHALLENGE COMPLETION
            dataContainer.challengeManager.checkChallengeCompletion(for: newMoment)
            
            // Delete draft after successful save
            if let draft = existingDraft {
                deleteDraft(draft)
            }
            
            // ✅ UPDATE NOTIFICATION SCHEDULE based on new logging pattern
            Task {
                await dataContainer.notificationManager.updateScheduleAfterNewMoment()
            }
            
            print("Moment saved successfully: \(title)")
            
            // Dismiss keyboard and close immediately so parent can celebrate
            focusedField = nil
            
            dismiss()
            
            // Notify presenter after the sheet has actually dismissed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                onSaved?()
            }
            
        } catch {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            print("Failed to save moment: \(error.localizedDescription)")
            // Don't dismiss
        }
    }
    
    @MainActor
    private func saveEdits() {
        guard let m = existingMoment else { return }
        let finalImageData: Data?
        if contentType == .color {
            finalImageData = createColorImage(color: selectedColor)
        } else {
            finalImageData = imageData
        }
        m.title = title
        m.note = note
        m.imageData = finalImageData
        m.isLocked = isLocked
        do {
            try modelContext.save()
            // Updating a moment may change badge eligibility (e.g., note/photo-dependent). We can re-evaluate.
            do {
                try dataContainer.badgeManager.unlockBadges(newMoment: m)
            } catch {
                print("Failed to re-evaluate badges after edit: \(error)")
            }
            // Ensure badge updates are persisted after edit
            try? modelContext.save()
            focusedField = nil
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                onSaved?()
            }
        } catch {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            print("Failed to save edits: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Draft Functions
    
    @MainActor
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
        contentType = draft.contentType == "color" ? .color : .photo
        isLocked = draft.isLocked
    }
    
    @MainActor
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
            selectedColorName: nil,
            contentType: contentType.rawValue == "color" ? "color" : "photo",
            isLocked: isLocked
        )
        
        modelContext.insert(draft)
        try? modelContext.save()
    }
    
    @MainActor
    private func deleteDraft(_ draft: Draft) {
        modelContext.delete(draft)
        try? modelContext.save()
        existingDraft = nil
    }
    
    private func createColorImage(color: Color) -> Data? {
        let size = CGSize(width: 500, height: 500)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            UIColor(color).setFill()
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

#Preview {
    MomentEntryView()
        .sampleDataContainer()
}

