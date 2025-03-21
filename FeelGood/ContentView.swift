//
//  ContentView.swift
//  FeelGood
//
//  Created by Ayush Shah on 3/20/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var userModel: UserModel
    
    var body: some View {
        if !userModel.isOnboarded {
            OnboardingView()
        } else {
            CheckInView()
        }
    }
}

struct OnboardingView: View {
    @EnvironmentObject private var userModel: UserModel
    @State private var currentPage = 0
    @State private var animateSelected = false
    @State private var themePreviewOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Background gradient based on selected theme
            LinearGradient(
                gradient: Gradient(colors: userModel.activeTheme.colors),
                startPoint: userModel.activeTheme.startPoint,
                endPoint: userModel.activeTheme.endPoint
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Back button
                HStack {
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            if currentPage > 0 {
                                currentPage -= 1
                            }
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(.white)
                            .opacity(currentPage > 0 ? 1 : 0)
                    }
                    .padding(.leading)
                    Spacer()
                }
                
                Spacer()
                
                // Avatar
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.9))
                        .frame(width: 100, height: 100)
                        .shadow(color: .black.opacity(0.1), radius: 10)
                    
                    VStack(spacing: 2) {
                        // Simple smiley face
                        HStack(spacing: 30) {
                            Circle()
                                .fill(.black)
                                .frame(width: 8, height: 8)
                            Circle()
                                .fill(.black)
                                .frame(width: 8, height: 8)
                        }
                        
                        // Smile
                        Image(systemName: "mouth.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30)
                            .foregroundColor(.orange)
                            .offset(y: 5)
                    }
                }
                .scaleEffect(animateSelected ? 1.05 : 1.0)
                
                // Title
                Text("Boom - magic color change!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("CAN BE CHANGED LATER IN SETTINGS")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                // Scrollable color selection
                VStack(spacing: 25) {
                    // Selected theme preview
                    ZStack {
                        Circle()
                            .strokeBorder(.white, lineWidth: 3)
                            .frame(width: 80, height: 80)
                            .scaleEffect(animateSelected ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: animateSelected)
                            
                        LinearGradient(
                            gradient: Gradient(colors: userModel.activeTheme.colors),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .clipShape(Circle())
                        .frame(width: 74, height: 74)
                        .shadow(color: .black.opacity(0.1), radius: 5)
                        .scaleEffect(animateSelected ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: animateSelected)
                    }
                    .overlay {
                        // Selected indicator
                        Circle()
                            .stroke(.white, lineWidth: animateSelected ? 3 : 0)
                            .frame(width: 90, height: 90)
                            .opacity(animateSelected ? 1 : 0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: animateSelected)
                    }
                    
                    // Horizontal scrolling theme selection
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(Array(userModel.themeGradients.enumerated()), id: \.element.id) { index, theme in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        userModel.selectedThemeIndex = index
                                        animateSelected = true
                                    }
                                    
                                    // Haptic feedback
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                    
                                    // Reset animation after a delay
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        animateSelected = false
                                    }
                                }) {
                                    ZStack {
                                        Circle()
                                            .strokeBorder(.white, lineWidth: userModel.selectedThemeIndex == index ? 3 : 1)
                                            .frame(width: 60, height: 60)
                                            
                                        LinearGradient(
                                            gradient: Gradient(colors: theme.colors),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                        .clipShape(Circle())
                                        .frame(width: userModel.selectedThemeIndex == index ? 54 : 56, height: userModel.selectedThemeIndex == index ? 54 : 56)
                                        .shadow(color: .black.opacity(0.1), radius: 5)
                                    }
                                    .scaleEffect(userModel.selectedThemeIndex == index ? 1.1 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: userModel.selectedThemeIndex)
                                }
                            }
                        }
                        .padding(.horizontal, 30)
                    }
                    .padding(.bottom, 20)
                }
                
                // Next button
                Button(action: {
                    // Haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        if currentPage < 2 {
                            currentPage += 1
                        } else {
                            userModel.isOnboarded = true
                            userModel.savePreferences()
                        }
                    }
                }) {
                    Text("NEXT")
                        .fontWeight(.semibold)
                        .foregroundColor(userModel.activeTheme.colors[0])
                        .frame(width: 280, height: 60)
                        .background(
                            Capsule()
                                .fill(.white)
                                .shadow(color: .black.opacity(0.1), radius: 5)
                        )
                }
                .buttonStyle(ScaleButtonStyle())
                
                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(currentPage == index ? .white : .white.opacity(0.5))
                            .frame(width: 8, height: 8)
                            .scaleEffect(currentPage == index ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
    }
}

struct CheckInView: View {
    @EnvironmentObject private var userModel: UserModel
    @State private var moodRating: Double = 7
    @State private var isRecording = false
    @State private var note: String = ""
    @State private var isAddingNote = false
    @State private var animateEmoji = false
    @State private var isDragging = false // Track dragging state
    @State private var previousRating: Double = 7
    
    // Define slider dimensions as constants at the struct level
    private let sliderWidth: CGFloat = UIScreen.main.bounds.width * 0.75
    private let thumbWidth: CGFloat = 35
    private let trackHeight: CGFloat = 12
    
    var moodText: String {
        switch Int(moodRating) {
        case 1...3:
            return "Not great"
        case 4...6:
            return "Okay"
        case 7...8:
            return "Pretty good"
        case 9...10:
            return "Amazing!"
        default:
            return "Okay"
        }
    }
    
    var moodEmoji: String {
        switch Int(moodRating) {
        case 1...3:
            return "😔"
        case 4...6:
            return "😐"
        case 7...8:
            return "🙂"
        case 9...10:
            return "😄"
        default:
            return "🙂"
        }
    }
    
    var moodRatingColor: Color {
        switch Int(moodRating) {
        case 1...3:
            return .red.opacity(0.7)
        case 4...6:
            return .yellow.opacity(0.7)
        case 7...8:
            return .green.opacity(0.7)
        case 9...10:
            return Color(hex: "00FF00").opacity(0.7) // Bright green
        default:
            return .green.opacity(0.7)
        }
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: userModel.activeTheme.colors),
                startPoint: userModel.activeTheme.startPoint,
                endPoint: userModel.activeTheme.endPoint
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 15) {
                    // Header
                    HStack {
                        Spacer()
                        Text("Morning Check-in")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // Main content section
                    VStack(spacing: 8) {
                        Text("How are you feeling?")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text(formattedDate())
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.top, 5)
                    
                    // Emoji with animation
                    Text(moodEmoji)
                        .font(.system(size: 90))
                        .padding(.vertical, 10)
                        .scaleEffect(animateEmoji ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: animateEmoji)
                    
                    // Mood text
                    Text(moodText)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.bottom, 5)
                    
                    // Improved slider for mood rating
                    VStack(spacing: 5) {
                        // Custom slider track with thumb
                        ZStack(alignment: .leading) {
                            // Background track
                            Capsule()
                                .frame(width: sliderWidth, height: trackHeight)
                                .foregroundColor(.white.opacity(0.3))
                            
                            // Calculate exact positions for perfect alignment
                            let percentage = (moodRating - 1.0) / 9.0
                            let thumbPosition = percentage * (sliderWidth - thumbWidth)
                            let fillWidth = thumbPosition + (thumbWidth / 2)
                            
                            // Filled portion - aligned exactly with thumb center
                            Capsule()
                                .frame(width: fillWidth, height: trackHeight)
                                .foregroundColor(moodRatingColor)
                                
                            // Slider thumb directly on the track
                            Circle()
                                .fill(.white)
                                .frame(width: thumbWidth, height: thumbWidth)
                                .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 1)
                                .overlay(
                                    Text("\(Int(moodRating))")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(userModel.activeTheme.colors[0])
                                )
                                .offset(x: thumbPosition)
                                .scaleEffect(isDragging ? 1.1 : 1.0)
                        }
                        .frame(width: sliderWidth)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    // Calculate position within the slider
                                    let xPos = min(max(0, value.location.x), sliderWidth)
                                    let percentage = Double(xPos / sliderWidth)
                                    let newRating = 1.0 + percentage * 9.0
                                    
                                    // Detect category changes
                                    let oldCategory = Int(moodRating) / 3
                                    let newCategory = Int(newRating) / 3
                                    
                                    // Update rating with minimal animation for smooth dragging
                                    withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.9, blendDuration: 0.1)) {
                                        moodRating = newRating.rounded()
                                        isDragging = true
                                    }
                                    
                                    if oldCategory != newCategory {
                                        animateEmoji = true
                                        
                                        // Add haptic feedback
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.impactOccurred()
                                        
                                        // Reset animation
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            animateEmoji = false
                                        }
                                    }
                                }
                                .onEnded { _ in
                                    // End dragging state when gesture ends
                                    withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                        isDragging = false
                                    }
                                }
                        )
                    }
                    .padding(.bottom, 5) // Add a little padding before next section
                    
                    // Tell me about it section
                    HStack {
                        Text("Tell me about it")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Image(systemName: "chevron.down")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                        
                        Button(action: {
                            isRecording.toggle()
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: isRecording ? "mic.fill" : "keyboard")
                                    .font(.subheadline)
                                Text(isRecording ? "Use Voice" : "Use Text")
                                    .font(.subheadline)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(15)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 4)
                    
                    if isRecording {
                        TextField("", text: $note)
                            .font(.body)
                            .foregroundColor(.white)
        .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(15)
                            .padding(.horizontal)
                    } else {
                        VStack(spacing: 8) {
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                }
                            }) {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 70, height: 70)
                                    .overlay(
                                        Image(systemName: "mic.fill")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                    )
                            }
                            .buttonStyle(ScaleButtonStyle())
                            
                            Text("Tap to start recording")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.top, 5)
                    }
                    
                    Spacer()
                    
                    // Save button
                    Button(action: {
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        
                        userModel.addMoodEntry(
                            rating: Int(moodRating),
                            note: note.isEmpty ? nil : note,
                            audioURL: nil,
                            checkInType: .morning
                        )
                        
                        moodRating = 7
                        note = ""
                        isRecording = false
                    }) {
                        Text("Save How I Feel")
                            .font(.body.weight(.medium))
                            .foregroundColor(userModel.activeTheme.colors[0])
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                Capsule()
                                    .fill(.white)
                                    .shadow(color: .black.opacity(0.1), radius: 5)
                            )
                            .padding(.horizontal)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.vertical, 15)
                }
                .padding(.vertical, 10)
            }
            .scrollIndicators(.hidden)
        }
    }
    
    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: Date())
    }
}

// Custom button style with scale animation
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
        .environmentObject(UserModel())
}