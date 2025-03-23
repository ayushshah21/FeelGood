import SwiftUI

struct BobbyAssistantView: View {
    @StateObject private var vapiService = VapiService()
    @EnvironmentObject private var userModel: UserModel
    
    var body: some View {
        ZStack {
            // Background
            Color(userModel.activeTheme.mainColor)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                Text("Bobby")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                
                // Status text
                Text(vapiService.isLoading ? "Connecting..." : (vapiService.isCallActive ? "Listening..." : "Tap to talk"))
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                // Transcripts
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(vapiService.transcripts, id: \.self) { transcript in
                            Text(transcript)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                }
                
                Spacer()
                
                // Call button
                Button(action: {
                    vapiService.toggleCall()
                }) {
                    Image(systemName: vapiService.isCallActive ? "phone.down.fill" : "phone.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .padding(30)
                        .background(
                            Circle()
                                .fill(vapiService.isCallActive ? Color.red : Color.green)
                        )
                }
                .disabled(vapiService.isLoading)
                .padding(.bottom, 40)
            }
            .padding()
            
            // Error alert
            if let error = vapiService.error {
                VStack {
                    Spacer()
                    Text(error)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(10)
                        .padding()
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                vapiService.error = nil
                            }
                        }
                }
            }
        }
    }
} 