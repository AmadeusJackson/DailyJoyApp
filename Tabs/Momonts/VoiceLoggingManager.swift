//
//  VoiceLoggingManager.swift
//  Daily Joy
//
//  Created by Amadeus Jackson on 12/28/25.
//

import Foundation
internal import Speech
import AVFoundation

@Observable
class VoiceLoggingManager: NSObject {
    // State
    var isRecording = false
    var transcribedText = ""
    var errorMessage: String?
    var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    
    // Speech recognition
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    override init() {
        super.init()
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                self.authorizationStatus = status
                continuation.resume(returning: status == .authorized)
            }
        }
    }
    
    func checkAuthorizationStatus() {
        authorizationStatus = SFSpeechRecognizer.authorizationStatus()
    }
    
    var canRecord: Bool {
        authorizationStatus == .authorized && speechRecognizer?.isAvailable == true
    }
    
    // MARK: - Recording
    
    func startRecording() throws {
        // Cancel any existing task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw VoiceError.recognitionRequestFailed
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Get audio input node
        let inputNode = audioEngine.inputNode
        
        // Remove any existing tap
        inputNode.removeTap(onBus: 0)
        
        // Create recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            var isFinal = false
            
            if let result = result {
                self.transcribedText = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.isRecording = false
            }
        }
        
        // Configure microphone input
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()
        
        isRecording = true
        transcribedText = ""
        errorMessage = nil
    }
    
    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        isRecording = false
    }
    
    // MARK: - Cleanup
    
    func reset() {
        stopRecording()
        transcribedText = ""
        errorMessage = nil
    }
}

enum VoiceError: Error, LocalizedError {
    case recognitionRequestFailed
    case audioEngineFailed
    case notAuthorized
    
    var errorDescription: String? {
        switch self {
        case .recognitionRequestFailed:
            return "Unable to create speech recognition request"
        case .audioEngineFailed:
            return "Audio engine failed to start"
        case .notAuthorized:
            return "Speech recognition not authorized"
        }
    }
}
