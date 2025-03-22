//
//  WhisperService.swift
//  FeelGood
//
//  Created for FeelGood.
//

import Foundation
import AVFoundation
import SwiftUI

// Access API keys securely
class WhisperService: NSObject, ObservableObject {
    static let shared = WhisperService()
    
    // State variables
    @Published var isRecording = false
    @Published var isTranscribing = false
    @Published var transcription: String = ""
    @Published var errorMessage: String?
    @Published var permissionGranted = false
    
    // Audio recording properties
    private var audioRecorder: AVAudioRecorder?
    private var audioFileURL: URL?
    private var audioPlayer: AVAudioPlayer?
    
    // Callback for handling transcription results
    var transcriptionCompletionHandler: ((String) -> Void)?
    
    // Private initializer for singleton
    private override init() {
        super.init()
        checkPermissions()
    }
    
    // MARK: - Setup
    
    private func checkPermissions() {
        if #available(iOS 17.0, *) {
            // Use new iOS 17+ APIs
            switch AVAudioApplication.shared.recordPermission {
            case .granted:
                permissionGranted = true
                setupAudioSession()
            case .denied:
                permissionGranted = false
                errorMessage = "Microphone access denied. Please enable in Settings > Privacy > Microphone."
            case .undetermined:
                AVAudioApplication.requestRecordPermission { [weak self] (granted: Bool) in
                    DispatchQueue.main.async {
                        self?.permissionGranted = granted
                        if granted {
                            self?.setupAudioSession()
                        } else {
                            self?.errorMessage = "Microphone access denied. Voice recording will not be available."
                        }
                    }
                }
            @unknown default:
                permissionGranted = false
                errorMessage = "Unknown permission status for microphone."
            }
        } else {
            // Fallback for iOS 16 and earlier
            let audioSession = AVAudioSession.sharedInstance()
            
            switch audioSession.recordPermission {
            case .granted:
                permissionGranted = true
                setupAudioSession()
            case .denied:
                permissionGranted = false
                errorMessage = "Microphone access denied. Please enable in Settings > Privacy > Microphone."
            case .undetermined:
                audioSession.requestRecordPermission { [weak self] granted in
                    DispatchQueue.main.async {
                        self?.permissionGranted = granted
                        if granted {
                            self?.setupAudioSession()
                        } else {
                            self?.errorMessage = "Microphone access denied. Voice recording will not be available."
                        }
                    }
                }
            @unknown default:
                permissionGranted = false
                errorMessage = "Unknown permission status for microphone."
            }
        }
    }
    
    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    // MARK: - Recording Methods
    
    func startRecording() {
        guard permissionGranted else {
            errorMessage = "Cannot record audio. Microphone access is required."
            return
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            // Create a temporary file URL
            let fileName = "voice_memo_\(Date().timeIntervalSince1970).m4a"
            let tempDir = FileManager.default.temporaryDirectory
            audioFileURL = tempDir.appendingPathComponent(fileName)
            
            // Recording settings optimized for Whisper
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 16000, // Whisper recommends 16kHz
                AVNumberOfChannelsKey: 1, // Mono
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            // Initialize and start recording
            audioRecorder = try AVAudioRecorder(url: audioFileURL!, settings: settings)
            audioRecorder?.record()
            
            // Update state
            isRecording = true
            errorMessage = nil
            print("🎤 Recording started at \(audioFileURL?.path ?? "unknown location")")
        } catch {
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
            print("🔴 Recording error: \(error)")
        }
    }
    
    func stopRecording() {
        // Stop the recorder
        audioRecorder?.stop()
        isRecording = false
        
        // After stopping, transcribe the audio if we have a valid file
        if let fileURL = audioFileURL {
            print("🎙️ Recording stopped. File size: \(getFileSize(url: fileURL)) bytes")
            transcribeAudio(fileURL: fileURL)
        } else {
            errorMessage = "No recording found to transcribe"
        }
    }
    
    // MARK: - Playback Methods
    
    func playRecording() {
        guard let fileURL = audioFileURL else {
            errorMessage = "No recording available to play"
            return
        }
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            
            audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            
            print("▶️ Playing recording from \(fileURL.lastPathComponent)")
        } catch {
            errorMessage = "Failed to play recording: \(error.localizedDescription)"
            print("🔴 Playback error: \(error)")
        }
    }
    
    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    // MARK: - Whisper Transcription
    
    func transcribeAudio(fileURL: URL) {
        isTranscribing = true
        errorMessage = nil
        
        Task {
            do {
                // Ensure the file exists and has content
                guard FileManager.default.fileExists(atPath: fileURL.path) else {
                    throw NSError(domain: "WhisperService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Audio file not found"])
                }
                
                // Read audio file data
                let audioData = try Data(contentsOf: fileURL)
                guard !audioData.isEmpty else {
                    throw NSError(domain: "WhisperService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Audio file is empty"])
                }
                
                print("📤 Sending audio file (\(audioData.count) bytes) to Whisper API")
                
                // Create multipart form data
                var request = URLRequest(url: URL(string: "https://api.openai.com/v1/audio/transcriptions")!)
                request.httpMethod = "POST"
                
                let boundary = UUID().uuidString
                request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                request.setValue("Bearer \(APIConfig.openAIAPIKey)", forHTTPHeaderField: "Authorization")
                
                var body = Data()
                
                // Add file data
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
                body.append(audioData)
                body.append("\r\n".data(using: .utf8)!)
                
                // Add model parameter
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
                body.append("whisper-1\r\n".data(using: .utf8)!)
                
                // Add response format parameter
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
                body.append("json\r\n".data(using: .utf8)!)
                
                // Close the form
                body.append("--\(boundary)--\r\n".data(using: .utf8)!)
                
                request.httpBody = body
                
                // Make the request with a timeout
                let config = URLSessionConfiguration.default
                config.timeoutIntervalForRequest = 30
                let session = URLSession(configuration: config)
                
                let (data, response) = try await session.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NSError(domain: "WhisperService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"])
                }
                
                // Handle API response
                if httpResponse.statusCode != 200 {
                    let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
                    print("❌ Whisper API error (\(httpResponse.statusCode)): \(errorText)")
                    throw NSError(domain: "WhisperService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API Error: \(httpResponse.statusCode)"])
                }
                
                // Parse the response
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let transcriptionText = json["text"] as? String {
                    
                    // Process and clean the transcription
                    let cleanedText = transcriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    await MainActor.run {
                        self.transcription = cleanedText
                        self.isTranscribing = false
                        self.transcriptionCompletionHandler?(cleanedText)
                        print("✅ Transcription completed: \"\(cleanedText)\"")
                    }
                } else {
                    throw NSError(domain: "WhisperService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse API response"])
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = "Transcription failed: \(error.localizedDescription)"
                    self.isTranscribing = false
                    print("🔴 Transcription error: \(error)")
                }
            }
            
            // Clean up temporary file
            if let fileURL = audioFileURL {
                try? FileManager.default.removeItem(at: fileURL)
                print("🗑️ Removed temporary audio file")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getFileSize(url: URL) -> UInt64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? UInt64 ?? 0
        } catch {
            print("Error getting file size: \(error)")
            return 0
        }
    }
    
    func resetState() {
        isRecording = false
        isTranscribing = false
        transcription = ""
        errorMessage = nil
        audioFileURL = nil
        stopPlayback()
    }
}

// MARK: - AVAudioPlayerDelegate
extension WhisperService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // Reset player when done
        audioPlayer = nil
    }
} 