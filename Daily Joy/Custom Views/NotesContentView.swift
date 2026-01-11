//
//  NotesContentView.swift
//  Daily Joy
//
//  Created by Amadeus Jackson on 11/28/25.
//

import SwiftUI
import PhotosUI
import WidgetKit

// MARK: - Shared UserDefaults
extension UserDefaults {
    static var appGroup: UserDefaults {
        UserDefaults(suiteName: "group.com.amadeusjackson.dailyjoy")!
    }
}

// MARK: - Note Model
struct Note: Identifiable, Codable {
    let id: UUID
    var title: String
    var content: String
    var imageData: Data?
    var createdAt: Date
    
    init(id: UUID = UUID(), title: String, content: String, imageData: Data? = nil, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.content = content
        self.imageData = imageData
        self.createdAt = createdAt
    }
}

// MARK: - Main Content View
struct NotesContentView: View {
    @State private var notes: [Note] = []
    @State private var showingAddNote = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if notes.isEmpty {
                    emptyStateView
                } else {
                    notesList
                }
                
                // Floating Add Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showingAddNote = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Notes")
            .sheet(isPresented: $showingAddNote) {
                AddNoteView(notes: $notes)
            }
            .onAppear {
                loadNotes()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "note.text")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No Notes Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Tap the + button to create your first note")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    private var notesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(notes) { note in
                    NoteCard(note: note)
                        .onTapGesture {
                            // Handle note tap if needed
                        }
                }
            }
            .padding()
            .padding(.bottom, 80)
        }
    }
    
    private func loadNotes() {
        if let data = UserDefaults.appGroup.data(forKey: "savedNotes"),
           let decoded = try? JSONDecoder().decode([Note].self, from: data) {
            notes = decoded
        }
    }
}

// MARK: - Note Card View
struct NoteCard: View {
    let note: Note
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let imageData = note.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 180)
                    .clipped()
                    .cornerRadius(12)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(note.title)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text(note.content)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                
                Text(note.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

// MARK: - Add Note View (Modal)
struct AddNoteView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var notes: [Note]
    
    @State private var title = ""
    @State private var content = ""
    @State private var selectedImage: PhotosPickerItem?
    @State private var selectedImageData: Data?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Title")) {
                    TextField("Enter title", text: $title)
                        .font(.headline)
                }
                
                Section(header: Text("Note")) {
                    TextEditor(text: $content)
                        .frame(minHeight: 120)
                }
                
                Section(header: Text("Image (Optional)")) {
                    if let imageData = selectedImageData,
                       let uiImage = UIImage(data: imageData) {
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .cornerRadius(8)
                            
                            Button(action: {
                                selectedImageData = nil
                                selectedImage = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            .padding(8)
                        }
                    }
                    
                    PhotosPicker(selection: $selectedImage, matching: .images) {
                        HStack {
                            Image(systemName: "photo")
                            Text(selectedImageData == nil ? "Select Image" : "Change Image")
                        }
                    }
                    .onChange(of: selectedImage) { _, newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                selectedImageData = data
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveNote()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func saveNote() {
        let newNote = Note(
            title: title,
            content: content,
            imageData: selectedImageData
        )
        
        notes.insert(newNote, at: 0)
        
        // Save to shared UserDefaults
        if let encoded = try? JSONEncoder().encode(notes) {
            UserDefaults.appGroup.set(encoded, forKey: "savedNotes")
        }
        
        // Also save the latest note for the widget
        let widgetNote = NoteData(
            title: newNote.title,
            note: newNote.content,
            imageName: newNote.imageData != nil ? "photo" : nil
        )
        if let encoded = try? JSONEncoder().encode(widgetNote) {
            UserDefaults.appGroup.set(encoded, forKey: "widgetNoteData")
        }
        
        // Update widget
        WidgetCenter.shared.reloadAllTimelines()
        
        dismiss()
    }
}

// MARK: - Widget Note Data Model (for widget communication)
struct NoteData: Codable {
    let title: String
    let note: String
    let imageName: String?
}

// MARK: - Preview
#Preview {
    NotesContentView()
}
