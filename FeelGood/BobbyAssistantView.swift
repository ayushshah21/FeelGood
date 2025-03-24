import SwiftUI

struct BobbyAssistantView: View {
    @StateObject private var vapiService = VapiService()
    @EnvironmentObject private var userModel: UserModel
    @State private var animateGlow = false
    @State private var rotationDegrees: Double = 0
    @State private var showPulse = false
    @State private var pulseOpacity: Double = 0
    @State private var scrollToBottom = false
    
    var body: some View {
        ZStack {
            // Background
            Color(.black)
                .ignoresSafeArea()
            
            VStack(spacing: 0) { // Reduced spacing between main elements
                // Header - Minimal and Modern
                Text("Bobby")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20) // Reduced top padding
                    .padding(.horizontal)
                
                // Use GeometryReader to create a more adaptive layout
                GeometryReader { geometry in
                    VStack {
                        // Animated glowing orb - positioned to allow space for transcript
                        ZStack {
                            // Main glow effect
                            Circle()
                                .fill(Color(userModel.activeTheme.mainColor).opacity(0.2))
                                .frame(width: 250, height: 250)
                                .blur(radius: 70)
                                .scaleEffect(animateGlow ? 1.2 : 0.8)
                                .opacity(animateGlow ? 0.8 : 0.5)
                            
                            // Inner glow layers
                            ForEach(0..<3) { index in
                                Circle()
                                    .stroke(Color(userModel.activeTheme.mainColor).opacity(0.4 - Double(index) * 0.1), lineWidth: 20 - Double(index) * 5)
                                    .frame(width: 140 + CGFloat(index) * 40, height: 140 + CGFloat(index) * 40)
                                    .blur(radius: 20)
                            }
                            
                            // Dynamic swirling effect - similar to the image
                            ZStack {
                                ForEach(0..<2) { i in
                                    Circle()
                                        .trim(from: 0.3, to: 0.7)
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color(userModel.activeTheme.mainColor).opacity(0.0),
                                                    Color(userModel.activeTheme.mainColor).opacity(0.8),
                                                    Color(userModel.activeTheme.mainColor).opacity(0.0)
                                                ]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ),
                                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                                        )
                                        .frame(width: 180 - CGFloat(i) * 30, height: 180 - CGFloat(i) * 30)
                                        .rotationEffect(Angle(degrees: rotationDegrees + (i == 0 ? 0 : 180)))
                                }
                                
                                ForEach(0..<3) { i in
                                    Circle()
                                        .trim(from: 0.4, to: 0.6)
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color(userModel.activeTheme.mainColor).opacity(0.0),
                                                    Color(userModel.activeTheme.mainColor).opacity(0.6),
                                                    Color(userModel.activeTheme.mainColor).opacity(0.0)
                                                ]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ),
                                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                                        )
                                        .frame(width: 120 + CGFloat(i) * 50, height: 120 + CGFloat(i) * 50)
                                        .rotationEffect(Angle(degrees: -rotationDegrees - Double(i) * 60))
                                }
                            }
                            
                            // Pulse effect for when actively listening
                            Circle()
                                .stroke(Color(userModel.activeTheme.mainColor).opacity(pulseOpacity), lineWidth: 8)
                                .frame(width: 200, height: 200)
                                .scaleEffect(showPulse ? 1.5 : 1.0)
                                .opacity(showPulse ? 0 : 0.5)
                            
                            // Status text
                            if vapiService.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                            } else {
                                Text(vapiService.isCallActive ? "Listening..." : "Tap to talk")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(.top, 240)
                            }
                        }
                        .frame(height: 280) // Slightly reduced height
                        .contentShape(Circle()) // Make the entire area tappable
                        .onTapGesture {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                // Don't trigger if already loading
                                if !vapiService.isLoading {
                                    vapiService.toggleCall()
                                    
                                    if !vapiService.isCallActive {
                                        // Reset pulse when stopping
                                        showPulse = false
                                    } else {
                                        // Start pulse animation when active
                                        startPulseAnimation()
                                    }
                                    
                                    // Add haptic feedback
                                    let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                                    impactGenerator.impactOccurred()
                                }
                            }
                        }
                        .disabled(vapiService.isLoading) // Disable taps while loading
                        
                        Spacer(minLength: vapiService.transcripts.isEmpty ? 40 : 0) // Adaptive spacer
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
                .frame(height: vapiService.transcripts.isEmpty ? 420 : 350) // Adjust main content height based on transcript visibility
                
                // Single main action button - removed side buttons
                Button(action: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        vapiService.toggleCall()
                        
                        if !vapiService.isCallActive {
                            // Reset pulse when stopping
                            showPulse = false
                        } else {
                            // Start pulse animation when active
                            startPulseAnimation()
                        }
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.8)) // Dark blue for middle button like in image
                            .frame(width: 70, height: 70)
                            .shadow(color: Color.blue.opacity(0.5), radius: 10)
                        
                        Image(systemName: vapiService.isCallActive ? "waveform" : "mic.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                }
                .disabled(vapiService.isLoading)
                .padding(.bottom, vapiService.transcripts.isEmpty ? 40 : 10) // Adaptive bottom padding
                
                // Transcript area - slides up when there's content
                if !vapiService.transcripts.isEmpty {
                    VStack(alignment: .leading, spacing: 8) { // Reduced spacing
                        Text("Transcript")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal)
                            .padding(.bottom, 4)
                        
                        ScrollViewReader { scrollView in
                            ScrollView {
                                VStack(alignment: .leading, spacing: 20) {
                                    ForEach(Array(vapiService.transcripts.enumerated()), id: \.element) { index, transcript in
                                        let isUser = transcript.hasPrefix("You:")
                                        let messageText = transcript.replacingOccurrences(of: "You: ", with: "")
                                            .replacingOccurrences(of: "Bobby: ", with: "")
                                        
                                        HStack {
                                            if isUser {
                                                Spacer()
                                            }
                                            
                                            Text(messageText)
                                                .font(.system(size: 17))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 12)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 20)
                                                        .fill(isUser ? Color.blue.opacity(0.8) : Color(white: 0.2))
                                                )
                                                .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: isUser ? .trailing : .leading)
                                            
                                            if !isUser {
                                                Spacer()
                                            }
                                        }
                                        .id(index)
                                    }
                                    // Invisible element at the bottom with extra padding to ensure scrolling works properly
                                    Color.clear
                                        .frame(height: 40)
                                        .id("bottom")
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 20) // Extra bottom padding for scroll buffer
                            }
                            .frame(height: 200) // Increased height for better visibility
                            .onChange(of: vapiService.transcripts.count) { _ in
                                // Scroll to bottom whenever the transcript changes with a slight delay to ensure rendering completes
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        scrollView.scrollTo("bottom", anchor: .bottom)
                                    }
                                }
                            }
                            .onAppear {
                                // Scroll to bottom when the view appears with slight delay
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        scrollView.scrollTo("bottom", anchor: .bottom)
                                    }
                                }
                            }
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.horizontal)
                    .padding(.bottom, 10) // Add some bottom padding for the entire transcript section
                }
            }
            
            // Error alert
            if let error = vapiService.error {
                VStack {
                    Spacer()
                    Text(error)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(16)
                        .padding()
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                vapiService.error = nil
                            }
                        }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut, value: vapiService.error != nil)
            }
        }
        .onAppear {
            // Start animations when view appears
            startAnimations()
        }
    }
    
    // Start continuous glow animation
    private func startAnimations() {
        // Start glow animation
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            animateGlow = true
        }
        
        // Start rotation animation
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            rotationDegrees = 360
        }
    }
    
    // Start pulse animation when actively listening
    private func startPulseAnimation() {
        showPulse = true
        pulseOpacity = 0.7
        
        withAnimation(Animation.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
            showPulse = false
            pulseOpacity = 0
        }
    }
} 