import SwiftUI
import Vapi
import Combine

class VapiService: ObservableObject {
    private var vapi: Vapi?
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isCallActive = false
    @Published var isLoading = false
    @Published var transcripts: [String] = []
    @Published var error: String?
    
    // These values should come from a secure configuration not tracked in Git
    private let vapiKey: String
    private let assistantId: String
    
    init() {
        // Load the real keys from APIConfig
        self.vapiKey = APIConfig.vapiPublicKey
        self.assistantId = APIConfig.vapiAssistantId
        setupVapi()
    }
    
    private func setupVapi() {
        vapi = Vapi(publicKey: vapiKey)
        setupEventHandlers()
    }
    
    private func setupEventHandlers() {
        vapi?.eventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                switch event {
                case .callDidStart:
                    print("Call started successfully")
                    self?.isCallActive = true
                    self?.isLoading = false
                case .callDidEnd:
                    print("Call ended")
                    self?.isCallActive = false
                    self?.isLoading = false
                case .transcript(let transcript):
                    if transcript.transcriptType == .final {
                        print("Received transcript: \(transcript.transcript)")
                        self?.transcripts.append("\(transcript.role == .assistant ? "Bobby" : "You"): \(transcript.transcript)")
                    }
                case .error(let error):
                    print("Error occurred: \(error.localizedDescription)")
                    self?.error = error.localizedDescription
                    self?.isLoading = false
                case .speechUpdate(let update):
                    print("Speech update: \(update.status) for \(update.role)")
                case .functionCall(let function):
                    print("Function call received: \(function.name)")
                case .modelOutput(let output):
                    print("Model output: \(output.output)")
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }
    
    func startCall() {
        Task {
            do {
                isLoading = true
                print("Starting call with assistant ID: \(assistantId)")
                try await vapi?.start(assistantId: assistantId)
            } catch {
                print("Failed to start call: \(error.localizedDescription)")
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func endCall() {
        print("Ending call")
        vapi?.stop()
        transcripts.removeAll()
    }
    
    func toggleCall() {
        if isCallActive {
            endCall()
        } else {
            startCall()
        }
    }
} 