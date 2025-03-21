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
        NavigationStack {
            if !userModel.isOnboarded {
                OnboardingView()
            } else {
                MainTabView()
            }
        }
        // Ensure the environment object is passed to the entire view hierarchy
        .environmentObject(userModel)
    }
}

// Separate TabView into its own component to avoid nesting navigation controllers
struct MainTabView: View {
    @EnvironmentObject private var userModel: UserModel
    
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Image(systemName: "sun.max.fill")
                Text("Today")
            }
            
            NavigationStack {
                TimelineView()
                    .navigationBarHidden(true)
            }
            .tabItem {
                Image(systemName: "calendar")
                Text("History")
            }
            
            NavigationStack {
                Text("Insights View")
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        userModel.activeTheme.mainColor
                        .ignoresSafeArea()
                    )
                    .navigationTitle("Insights")
            }
            .tabItem {
                Image(systemName: "chart.bar.fill")
                Text("Insights")
            }
        }
        .accentColor(.white)
        .onAppear {
            // Set the tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.black
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

struct OnboardingView: View {
    @EnvironmentObject private var userModel: UserModel
    @State private var currentPage = 0
    @State private var animateSelected = false
    
    var body: some View {
        ZStack {
            // Solid color background
            userModel.activeTheme.mainColor
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
                
                // Title
                Text("Boom - magic color change!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("CAN BE CHANGED LATER IN SETTINGS")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                // Color selection section - simplified
                VStack(spacing: 20) {
                    Text("Select Your Theme")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    // Horizontal scrolling theme selection
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(Array(userModel.themeGradients.enumerated()), id: \.element.id) { index, theme in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        userModel.selectedThemeIndex = index
                                        animateSelected = true
                                        
                                        // Haptic feedback
                                        let generator = UIImpactFeedbackGenerator(style: .medium)
                                        generator.impactOccurred()
                                        
                                        // Reset animation after a delay
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            animateSelected = false
                                        }
                                    }
                                }) {
                                    ZStack {
                                        // Outer circle
                                        Circle()
                                            .strokeBorder(.white, lineWidth: userModel.selectedThemeIndex == index ? 3 : 1)
                                            .frame(width: 65, height: 65)
                                        
                                        // Theme color - now using solid color
                                        Circle()
                                            .fill(theme.mainColor)
                                            .frame(width: userModel.selectedThemeIndex == index ? 59 : 61, height: userModel.selectedThemeIndex == index ? 59 : 61)
                                            .shadow(color: .black.opacity(0.1), radius: 5)
                                    }
                                    .scaleEffect(userModel.selectedThemeIndex == index && animateSelected ? 1.05 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: userModel.selectedThemeIndex)
                                    .padding(5) // Extra padding to ensure no cutoff during animation
                                }
                            }
                        }
                        .padding(.horizontal, 15)
                        .padding(.vertical, 10)
                    }
                    .padding(.bottom, 10)
                }
                .padding()
                .background(Color.white.opacity(0.15))
                .cornerRadius(20)
                .padding(.horizontal)
                
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
                        .foregroundColor(userModel.activeTheme.mainColor)
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

struct HomeView: View {
    @EnvironmentObject private var userModel: UserModel
    @State private var currentDate = Date()
    @State private var showSettings = false
    
    var body: some View {
        ZStack {
            // Solid color background
            userModel.activeTheme.mainColor
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header - centered VybeCheck title with settings button on right
                    HStack {
                        Spacer()
                        
                        Text("VybeCheck")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            showSettings = true
                        }) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // Today's Mood section
                    VStack(spacing: 12) {
                        Text("Today's Mood")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 40) {
                            // Morning mood
                            VStack(spacing: 8) {
                                Text("Morning")
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundColor(.white)
                                
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.3))
                                        .frame(width: 90, height: 90)
                                    
                                    if let morningMood = userModel.getTodayMood(forType: .morning) {
                                        VStack(spacing: 4) {
                                            Text(getMoodEmoji(rating: morningMood))
                                                .font(.system(size: 36))
                                            
                                            Text("\(morningMood)")
                                                .font(.system(size: 24, weight: .semibold))
                                                .foregroundColor(.white)
                                        }
                                    } else {
                                        Text("?")
                                            .font(.system(size: 42, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            
                            // Evening mood
                            VStack(spacing: 8) {
                                Text("Evening")
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundColor(.white)
                                
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.3))
                                        .frame(width: 90, height: 90)
                                    
                                    if let eveningMood = userModel.getTodayMood(forType: .evening) {
                                        VStack(spacing: 4) {
                                            Text(getMoodEmoji(rating: eveningMood))
                                                .font(.system(size: 36))
                                            
                                            Text("\(eveningMood)")
                                                .font(.system(size: 24, weight: .semibold))
                                                .foregroundColor(.white)
                                        }
                                    } else {
                                        Text("?")
                                            .font(.system(size: 42, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 5)
                        
                        // Overall mood
                        HStack(spacing: 5) {
                            Text("Overall Today:")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(.white)
                            
                            Text(getOverallMoodEmoji())
                                .font(.system(size: 24))
                            
                            Text("(\(getOverallMoodRating()))")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 5)
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(20)
                    .padding(.horizontal)
                    
                    // Timeline section
                    VStack(spacing: 12) {
                        HStack {
                            // Timeline label with dot
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 8, height: 8)
                                
                                Text("Timeline")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            // Updates count - use proper pluralization
                            if userModel.getTimelineUpdateCount() == 1 {
                                Text("1 update")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(15)
                            } else {
                                Text("\(userModel.getTimelineUpdateCount()) updates")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(15)
                            }
                            
                            Spacer()
                            
                            // Add button - now linked to QuickUpdateView
                            NavigationLink(destination: QuickUpdateView()) {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 14, weight: .semibold))
                                    
                                    Text("Add")
                                        .font(.system(size: 17, weight: .medium))
                                }
                                .foregroundColor(userModel.activeTheme.mainColor)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.white)
                                .cornerRadius(20)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Recent check-in - now linked to TimelineView
                        if let lastEntry = userModel.getLastEntry() {
                            HStack {
                                Text(formatTime(date: lastEntry.timestamp))
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Text("Check-in")
                                    .font(.system(size: 17))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                NavigationLink(destination: TimelineView()) {
                                    HStack(spacing: 4) {
                                        Text("View All")
                                            .font(.system(size: 17))
                                            .foregroundColor(.white)
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 6)
                        }
                    }
                    .padding(.vertical, 20)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(20)
                    .padding(.horizontal)
                    
                    // Action buttons
                    VStack(spacing: 16) {
                        // Edit Morning Mood
                        NavigationLink(destination: CheckInView(checkInType: .morning, isEditing: true)) {
                            HStack {
                                Image(systemName: "sunrise")
                                    .font(.system(size: 22))
                                    .foregroundColor(.white)
                                
                                Text("Edit Morning Mood")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(20)
                            .padding(.horizontal)
                        }
                        
                        // Evening Check-in
                        NavigationLink(destination: CheckInView(checkInType: .evening, isEditing: false)) {
                            HStack {
                                Image(systemName: "sunset")
                                    .font(.system(size: 22))
                                    .foregroundColor(.white)
                                
                                Text("Evening Check-in")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(20)
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
        .navigationBarHidden(true)
    }
    
    // Helper functions
    func getMoodEmoji(rating: Int) -> String {
        switch rating {
        case 1...3: return "😔"
        case 4...6: return "😐" 
        case 7...8: return "🙂"
        case 9...10: return "😄"
        default: return "🙂"
        }
    }
    
    func getOverallMoodEmoji() -> String {
        return getMoodEmoji(rating: getOverallMoodRating())
    }
    
    func getOverallMoodRating() -> Int {
        let morningRating = userModel.getTodayMood(forType: .morning) ?? 0
        let eveningRating = userModel.getTodayMood(forType: .evening) ?? 0
        
        if morningRating > 0 && eveningRating > 0 {
            return (morningRating + eveningRating) / 2
        } else if morningRating > 0 {
            return morningRating
        } else if eveningRating > 0 {
            return eveningRating
        } else {
            return 0
        }
    }
    
    func formatTime(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct CheckInView: View {
    @EnvironmentObject private var userModel: UserModel
    @Environment(\.dismiss) private var dismiss
    
    var checkInType: CheckInType
    var isEditing: Bool
    
    @State private var moodRating: Double = 7
    @State private var isRecording = false
    @State private var note: String = ""
    @State private var animateEmoji = false
    @State private var isDragging = false
    
    // Initialize with default values if not provided
    init(checkInType: CheckInType = .morning, isEditing: Bool = false) {
        self.checkInType = checkInType
        self.isEditing = isEditing
    }
    
    // Load existing data when view appears
    private func loadExistingData() {
        if let existingRating = userModel.getTodayMood(forType: checkInType) {
            moodRating = Double(existingRating)
        }
    }

    // Define slider dimensions as constants
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
            // Solid color background
            userModel.activeTheme.mainColor
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 12) {
                    // Main content section
                    VStack(spacing: 6) {
                        Text("How are you feeling?")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text(formattedDate())
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.top, 5)
                    
                    // Emoji with animation
                    Text(moodEmoji)
                        .font(.system(size: 80))
                        .padding(.vertical, 8)
                        .scaleEffect(animateEmoji ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: animateEmoji)
                    
                    // Mood text
                    Text(moodText)
                        .font(.title3)
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
                            let maxOffset = sliderWidth - thumbWidth
                            let percentage = (moodRating - 1.0) / 9.0
                            let thumbPosition = percentage * maxOffset
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
                                        .foregroundColor(userModel.activeTheme.mainColor)
                                )
                                .offset(x: thumbPosition)
                                .scaleEffect(isDragging ? 1.1 : 1.0)
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            // Calculate position within the slider bounds
                                            let newOffset = min(max(0, value.location.x - thumbWidth / 2), maxOffset)
                                            let newPercentage = newOffset / maxOffset
                                            let newRating = 1.0 + newPercentage * 9.0
                                            
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
                        .frame(width: sliderWidth)
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            let newOffset = min(max(0, location.x - thumbWidth / 2), sliderWidth - thumbWidth)
                            let newPercentage = newOffset / (sliderWidth - thumbWidth)
                            let newRating = 1.0 + newPercentage * 9.0
                            
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                moodRating = newRating.rounded()
                            }
                            
                            // Haptic feedback
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            
                            // Animate emoji if category changes
                            let oldCategory = Int(moodRating) / 3
                            let newCategory = Int(newRating) / 3
                            if oldCategory != newCategory {
                                animateEmoji = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    animateEmoji = false
                                }
                            }
                        }
                    }
                    .padding(.bottom, 15)
                    
                    // Tell me about it section
                    VStack(spacing: 10) {
                        HStack {
                            Text("Tell me about it")
                                .font(.system(size: 18, weight: .medium))
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
                        
                        if isRecording {
                            TextField("", text: $note)
                                .font(.body)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(15)
                                .padding(.horizontal)
                        } else {
                            VStack(spacing: 6) {
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
                    }
                    
                    Spacer(minLength: 30)
                    
                    // Save button
                    Button(action: {
                        // Haptic feedback
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        
                        // Save mood entry
                        userModel.addMoodEntry(
                            rating: Int(moodRating),
                            note: note.isEmpty ? nil : note,
                            audioURL: nil,
                            checkInType: checkInType
                        )
                        
                        // Navigate back
                        dismiss()
                    }) {
                        Text("Save How I Feel")
                            .font(.body.weight(.medium))
                            .foregroundColor(userModel.activeTheme.mainColor)
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
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("\(checkInType == .morning ? "Morning" : "Evening") Check-in")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadExistingData()
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

// Settings View
struct SettingsView: View {
    @EnvironmentObject private var userModel: UserModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingResetConfirmation = false
    @State private var animateSelected = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Solid color background
                userModel.activeTheme.mainColor
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Theme selection section
                        VStack(spacing: 15) {
                            Text("Change Theme")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 5)
                            
                            // Horizontal scrolling theme selection
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    ForEach(Array(userModel.themeGradients.enumerated()), id: \.element.id) { index, theme in
                                        Button(action: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                userModel.selectedThemeIndex = index
                                                animateSelected = true
                                            }
                                            
                                            // Save preferences immediately
                                            userModel.savePreferences()
                                            
                                            // Haptic feedback
                                            let generator = UIImpactFeedbackGenerator(style: .medium)
                                            generator.impactOccurred()
                                            
                                            // Reset animation after a delay
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                animateSelected = false
                                            }
                                        }) {
                                            ZStack {
                                                // Outer circle
                                                Circle()
                                                    .strokeBorder(.white, lineWidth: userModel.selectedThemeIndex == index ? 3 : 1)
                                                    .frame(width: 65, height: 65)
                                                    
                                                // Theme color - now using solid color
                                                Circle()
                                                    .fill(theme.mainColor)
                                                    .frame(width: userModel.selectedThemeIndex == index ? 59 : 61, height: userModel.selectedThemeIndex == index ? 59 : 61)
                                                    .shadow(color: .black.opacity(0.1), radius: 5)
                                            }
                                            .scaleEffect(userModel.selectedThemeIndex == index && animateSelected ? 1.05 : 1.0)
                                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: userModel.selectedThemeIndex)
                                            .padding(5) // Extra padding to ensure no cutoff during animation
                                        }
                                    }
                                }
                                .padding(.horizontal, 15)
                                .padding(.vertical, 10)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        // Reset onboarding option
                        Button(action: {
                            showingResetConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.headline)
                                Text("Reset Onboarding")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .foregroundColor(.white)
        .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(16)
                            .padding(.horizontal)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .alert("Reset Onboarding?", isPresented: $showingResetConfirmation) {
                            Button("Cancel", role: .cancel) { }
                            Button("Reset", role: .destructive) {
                                userModel.isOnboarded = false
                                userModel.savePreferences()
                                dismiss()
                            }
                        } message: {
                            Text("This will reset the app to the initial onboarding experience.")
                        }
                        
                        // App version
                        Text("VybeCheck v1.0")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.top)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
}

// QuickUpdateView for timeline updates
struct QuickUpdateView: View {
    @EnvironmentObject private var userModel: UserModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showMoodRating = false
    @State private var moodRating: Double = 7
    @State private var note: String = ""
    @State private var isUsingVoice = true
    @State private var animateEmoji = false
    @State private var isDragging = false
    
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
            // Background color
            userModel.activeTheme.mainColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("Quick Update")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Empty view for balance
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.clear)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Main content
                ScrollView {
                    VStack(spacing: 16) {
                        // What's on your mind?
                        Text("What's on your mind?")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.top, 20)
                        
                        // Current time - ensure it fits
                        Text(formattedTime())
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.bottom, 5)
                            .padding(.horizontal)
                        
                        // Optional Mood Rating
                        if showMoodRating {
                            VStack(spacing: 5) {
                                // Current Mood Section
                                HStack {
                                    Text("Current Mood")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    // Close button
                                    Button(action: {
                                        withAnimation {
                                            showMoodRating = false
                                        }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title3)
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                                .padding(.horizontal)
                                
                                // Emoji
                                Text(moodEmoji)
                                    .font(.system(size: 70))
                                    .padding(.vertical, 5)
                                
                                // Mood text
                                Text(moodText)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                // Custom slider for mood rating
                                ZStack(alignment: .leading) {
                                    // Background track
                                    Capsule()
                                        .frame(width: sliderWidth, height: trackHeight)
                                        .foregroundColor(.white.opacity(0.3))
                                    
                                    // Calculate exact positions for alignment
                                    let maxOffset = sliderWidth - thumbWidth
                                    let percentage = (moodRating - 1.0) / 9.0
                                    let thumbPosition = percentage * maxOffset
                                    let fillWidth = thumbPosition + (thumbWidth / 2)
                                    
                                    // Filled portion
                                    Capsule()
                                        .frame(width: fillWidth, height: trackHeight)
                                        .foregroundColor(moodRatingColor)
                                        
                                    // Slider thumb
                                    Circle()
                                        .fill(.white)
                                        .frame(width: thumbWidth, height: thumbWidth)
                                        .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 1)
                                        .overlay(
                                            Text("\(Int(moodRating))")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(userModel.activeTheme.mainColor)
                                        )
                                        .offset(x: thumbPosition)
                                        .scaleEffect(isDragging ? 1.1 : 1.0)
                                        .gesture(
                                            DragGesture(minimumDistance: 0)
                                                .onChanged { value in
                                                    // Calculate position within slider bounds
                                                    let newOffset = min(max(0, value.location.x - thumbWidth / 2), maxOffset)
                                                    let newPercentage = newOffset / maxOffset
                                                    let newRating = 1.0 + newPercentage * 9.0
                                                    
                                                    // Detect category changes
                                                    let oldCategory = Int(moodRating) / 3
                                                    let newCategory = Int(newRating) / 3
                                                    
                                                    // Update rating with minimal animation
                                                    withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.9, blendDuration: 0.1)) {
                                                        moodRating = newRating.rounded()
                                                        isDragging = true
                                                    }
                                                    
                                                    if oldCategory != newCategory {
                                                        animateEmoji = true
                                                        
                                                        // Haptic feedback
                                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                                        generator.impactOccurred()
                                                        
                                                        // Reset animation
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                            animateEmoji = false
                                                        }
                                                    }
                                                }
                                                .onEnded { _ in
                                                    // End dragging state
                                                    withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                                        isDragging = false
                                                    }
                                                }
                                        )
                                }
                                .frame(width: sliderWidth)
                                .contentShape(Rectangle())
                                .padding(.vertical, 15)
                            }
                            .padding(.vertical, 10)
                        } else {
                            // Button to add mood rating
                            Button(action: {
                                withAnimation {
                                    showMoodRating = true
                                }
                            }) {
                                HStack {
                                    Image(systemName: "plus")
                                        .font(.subheadline)
                                    
                                    Text("Add Current Mood Rating")
                                        .font(.subheadline)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(25)
                            }
                            .padding(.vertical, 15)
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.3))
                            .padding(.horizontal)
                        
                        // What's happening section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("What's happening?")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            // Toggle between voice and text
                            HStack {
                                Spacer()
                                
                                Button(action: {
                                    withAnimation {
                                        isUsingVoice.toggle()
                                    }
                                    
                                    // Haptic feedback
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                }) {
                                    HStack(spacing: 5) {
                                        Image(systemName: isUsingVoice ? "keyboard" : "mic.fill")
                                            .font(.system(size: 15))
                                        
                                        Text(isUsingVoice ? "Use Text" : "Use Voice")
                                            .font(.system(size: 15, weight: .medium))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 15)
                                    .padding(.vertical, 8)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(20)
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                            
                            if isUsingVoice {
                                // Voice recording UI
                                VStack(spacing: 15) {
                                    // Microphone button
                                    Button(action: {
                                        // Handle voice recording
                                        // (Will be implemented in future)
                                    }) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.white.opacity(0.2))
                                                .frame(width: 90, height: 90)
                                            
                                            Image(systemName: "mic.fill")
                                                .font(.system(size: 32))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    
                                    Text("Tap the microphone to start recording")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .padding(.vertical, 30)
                                .frame(maxWidth: .infinity)
                            } else {
                                // Text input UI - simplified with no placeholder
                                TextEditor(text: $note)
                                    .foregroundColor(.white)
                                    .scrollContentBackground(.hidden)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(15)
                                    .frame(minHeight: 120)
                                    .padding(.horizontal)
                                    .padding(.vertical, 10)
                            }
                        }
                        
                        Spacer(minLength: 30)
                        
                        // Add to Timeline button
                        Button(action: {
                            // Add to timeline
                            userModel.addQuickUpdate(
                                rating: showMoodRating ? Int(moodRating) : nil,
                                note: note.isEmpty ? nil : note,
                                audioURL: nil // Will be implemented with voice recording
                            )
                            
                            // Haptic feedback
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                            
                            // Dismiss view
                            dismiss()
                        }) {
                            Text("Add to Timeline")
                                .font(.headline)
                                .foregroundColor(userModel.activeTheme.mainColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    Capsule()
                                        .fill(.white)
                                        .shadow(color: .black.opacity(0.1), radius: 5)
                                )
                                .padding(.horizontal)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    // Helper function to format current time
    private func formattedTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: Date())
    }
}

// TimelineView for displaying all entries
struct TimelineView: View {
    @EnvironmentObject private var userModel: UserModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background color
            userModel.activeTheme.mainColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("Today's Timeline")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Empty space for visual balance
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.clear)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Date and update count
                HStack {
                    Text(formattedDate())
                        .font(.title3)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Use proper pluralization for updates count
                    if userModel.getTimelineUpdateCount() == 1 {
                        Text("1 update")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(15)
                    } else {
                        Text("\(userModel.getTimelineUpdateCount()) updates")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(15)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 15)
                
                // Timeline entries with floating button
                ZStack(alignment: .bottomTrailing) {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(userModel.getTimelineEntries()) { entry in
                                TimelineEntryRow(entry: entry)
                            }
                        }
                        .padding(.bottom, 100) // Add padding for floating button
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Floating add button
                    NavigationLink(destination: QuickUpdateView()) {
                        ZStack {
                            Circle()
                                .fill(.white)
                                .frame(width: 60, height: 60)
                                .shadow(color: .black.opacity(0.15), radius: 5)
                            
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(userModel.activeTheme.mainColor)
                        }
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationBarHidden(true)
    }
    
    // Helper function to format date
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: Date())
    }
}

// Timeline entry row component
struct TimelineEntryRow: View {
    let entry: MoodEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Time stamp
            HStack(alignment: .center) {
                // Time
                Text(formattedTime(date: entry.timestamp))
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Entry type with emoji if rating exists
                HStack(spacing: 5) {
                    Text(entryTypeText)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if entry.rating > 0 {
                        Text(moodEmoji)
                            .font(.title3)
                    }
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.2))
                .cornerRadius(20)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            
            // Note content (if exists)
            if let note = entry.note, !note.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    // Vertical line connector
                    HStack(alignment: .top) {
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 2)
                            .frame(height: 25)
                            .padding(.leading, 32)
                        
                        Spacer()
                    }
                    
                    // Note content
                    Text(note)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 15)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.leading, 42)
                        .padding(.trailing, 20)
                        .padding(.bottom, 15)
                }
            }
        }
        .padding(.vertical, 5)
        .background(Color.clear) // Ensure clear background
    }
    
    // Helper computed properties
    private var entryTypeText: String {
        switch entry.checkInType {
        case .morning:
            return "Morning Check-in"
        case .evening:
            return "Evening Check-in"
        case .quickUpdate:
            return "Quick Update"
        }
    }
    
    private var moodEmoji: String {
        switch entry.rating {
        case 1...3: return "😔"
        case 4...6: return "😐" 
        case 7...8: return "🙂"
        case 9...10: return "😄"
        default: return ""
        }
    }
    
    // Helper function to format time
    private func formattedTime(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

#Preview {
    ContentView()
        .environmentObject(UserModel())
}