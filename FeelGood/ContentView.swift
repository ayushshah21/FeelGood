//
//  ContentView.swift
//  FeelGood
//
//  Created by Ayush Shah on 3/20/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var userModel: UserModel
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        NavigationStack {
            if !userModel.isOnboarded {
                OnboardingView()
            } else if !authViewModel.isAuthenticated {
                SignInView()
                    .environmentObject(authViewModel)
            } else {
                MainTabView()
                    .environmentObject(authViewModel)
            }
        }
        // Ensure the environment objects are passed to the entire view hierarchy
        .environmentObject(userModel)
        .environmentObject(authViewModel)
    }
}

// Separate TabView into its own component to avoid nesting navigation controllers
struct MainTabView: View {
    @EnvironmentObject private var userModel: UserModel
    
    var body: some View {
        ZStack {
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
                    BobbyAssistantView()
                }
                .tabItem {
                    Image(systemName: "waveform")
                    Text("Bobby")
                }
                
                NavigationStack {
                    InsightsDashboardView()
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
            
            // Loading overlay
            if userModel.isLoadingData {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .overlay(
                        VStack(spacing: 15) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                            
                            Text("Loading your data...")
                                .font(.callout)
                                .foregroundColor(.white)
                        }
                    )
            }
            
            // Error toast
            if let error = userModel.syncError {
                VStack {
                    Spacer()
                    
                    Text(error)
                        .font(.callout)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(10)
                        .padding()
                }
                .transition(.move(edge: .bottom))
                .animation(.spring(), value: userModel.syncError)
                .onAppear {
                    // Auto-dismiss after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        if userModel.syncError == error {
                            userModel.syncError = nil
                        }
                    }
                }
            }
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
            Color(userModel.activeTheme.mainColor)
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
            Color(userModel.activeTheme.mainColor)
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
                                Text(formatTime(date: lastEntry.date))
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
                        // Morning Check-in
                        NavigationLink(destination: CheckInView(checkInType: .morning, isEditing: true)) {
                            HStack {
                                Image(systemName: "sunrise")
                                    .font(.system(size: 22))
                                    .foregroundColor(.white)
                                
                                Text("Morning Check-in")
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
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showSettings) {
            SettingsView()
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
    @StateObject private var whisperService = WhisperService.shared
    
    var checkInType: CheckInType
    var isEditing: Bool
    
    @State private var moodRating: Double = 7
    @State private var isRecording = false
    @State private var note: String = ""
    @State private var animateEmoji = false
    @State private var isDragging = false
    @State private var showRecordingIndicator = false
    
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
            Color(userModel.activeTheme.mainColor)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("\(checkInType == .morning ? "Morning" : "Evening") Check-in")
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
                        .padding(.top, 20)
                        
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
                                    .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isDragging)
                                    .gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { value in
                                                let percentage = min(max(0, value.location.x / sliderWidth), 1)
                                                let newRating = 1.0 + percentage * 9.0
                                                if newRating != moodRating {
                                                    withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.7, blendDuration: 0.1)) {
                                                        moodRating = newRating
                                                        isDragging = true
                                                    }
                                                    // Add haptic feedback
                                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                                    generator.impactOccurred()
                                                }
                                            }
                                            .onEnded { _ in
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
                                    showRecordingIndicator.toggle()
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                    
                                    // Reset recording state when switching modes
                                    if !showRecordingIndicator {
                                        isRecording = false
                                        whisperService.resetState()
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: showRecordingIndicator ? "keyboard" : "mic.fill")
                                            .font(.subheadline)
                                        Text(showRecordingIndicator ? "Use Text" : "Use Voice")
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
                            
                            if !showRecordingIndicator {
                                TextField("", text: $note)
                                    .font(.body)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(15)
                                    .padding(.horizontal)
                            } else {
                                // Voice recording UI
                                VStack(alignment: .center, spacing: 10) {
                                    Button {
                                        if isRecording {
                                            // Stop recording
                                            whisperService.stopRecording()
                                            isRecording = false
                                        } else {
                                            // Start recording
                                            whisperService.transcriptionCompletionHandler = { transcription in
                                                note = transcription
                                            }
                                            whisperService.startRecording()
                                            isRecording = true
                                            // Haptic feedback
                                            let generator = UIImpactFeedbackGenerator(style: .medium)
                                            generator.impactOccurred()
                                        }
                                    } label: {
                                        VStack(alignment: .center, spacing: 8) {
                                            Circle()
                                                .fill(Color.white.opacity(0.2))
                                                .frame(width: 60, height: 60)
                                                .overlay(
                                                    Group {
                                                        if isRecording {
                                                            // Recording indicator
                                                            ZStack {
                                                                Circle()
                                                                    .fill(Color.red.opacity(0.8))
                                                                    .frame(width: 20, height: 20)
                                                                
                                                                Circle()
                                                                    .stroke(Color.red, lineWidth: 2)
                                                                    .frame(width: 36, height: 36)
                                                                    .scaleEffect(isRecording ? 1.5 : 1.0)
                                                                    .opacity(isRecording ? 0.0 : 1.0)
                                                                    .animation(
                                                                        Animation.easeOut(duration: 1)
                                                                            .repeatForever(autoreverses: false),
                                                                        value: isRecording
                                                                    )
                                                            }
                                                        } else if whisperService.isTranscribing {
                                                            // Transcribing indicator
                                                            ProgressView()
                                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                                .scaleEffect(1.2)
                                                        } else {
                                                            Image(systemName: "mic.fill")
                                                                .font(.title3)
                                                                .foregroundColor(.white)
                                                        }
                                                    }
                                                )
                                            
                                            Text(isRecording ? "Tap to stop" : whisperService.isTranscribing ? "Transcribing..." : "Tap to record")
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.8))
                                        }
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                    .frame(maxWidth: .infinity)
                                
                                    if !whisperService.permissionGranted && whisperService.errorMessage != nil {
                                        Text(whisperService.errorMessage ?? "Permission needed")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                            .padding(.top, 4)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                    }
                                    
                                    if !whisperService.transcription.isEmpty {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Transcription:")
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.8))
                                            
                                            Text(whisperService.transcription)
                                                .font(.body)
                                                .foregroundColor(.white)
                                                .padding()
                                                .background(Color.white.opacity(0.15))
                                                .cornerRadius(10)
                                            
                                            Button("Use This Text") {
                                                note = whisperService.transcription
                                                showRecordingIndicator = false // Switch to text mode
                                                whisperService.resetState()
                                            }
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 6)
                                            .background(Color.white.opacity(0.2))
                                            .cornerRadius(12)
                                            .padding(.top, 5)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding()
                                        .background(Color.white.opacity(0.1))
                                        .cornerRadius(12)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 30)
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
        }
        .navigationBarHidden(true)
        .onAppear {
            loadExistingData()
            whisperService.resetState()
            isRecording = false
            showRecordingIndicator = false
        }
        .onDisappear {
            if whisperService.isRecording {
                whisperService.stopRecording()
            }
            whisperService.resetState()
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
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingLogoutConfirmation = false
    @State private var showingResetConfirmation = false
    @State private var animateSelected = false
    @State private var showMockDataConfirmation = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Solid color background
                Color(userModel.activeTheme.mainColor)
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
                        
                        // Generate Mock Data button (temporary)
                        Button(action: {
                            showMockDataConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "square.and.pencil")
                                    .font(.headline)
                                Text("Generate Mock Data")
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
                        .alert("Generate Mock Data?", isPresented: $showMockDataConfirmation) {
                            Button("Cancel", role: .cancel) { }
                            Button("Generate", role: .destructive) {
                                userModel.generateMockMoodData()
                            }
                        } message: {
                            Text("This will replace all existing mood data with mock data for testing.")
                        }
                        
                        // Logout option
                        Button(action: {
                            showingLogoutConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.headline)
                                Text("Logout")
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
                        .alert("Logout", isPresented: $showingLogoutConfirmation) {
                            Button("Cancel", role: .cancel) { }
                            Button("Logout", role: .destructive) {
                                // Sign out user
                                authViewModel.signOut()
                                
                                // Clear user ID from model
                                userModel.userId = nil
                                userModel.savePreferences()
                                
                                dismiss()
                            }
                        } message: {
                            Text("Are you sure you want to logout?")
                        }
                        
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
    @StateObject private var whisperService = WhisperService.shared
    
    @State private var note = ""
    @State private var moodRating: Int = 7
    @State private var isExpanded = false
    @State private var isTextInputActive = false
    @State private var showRecordingUI = false
    @State private var isRecording = false
    @State private var isDragging = false
    
    // Define slider dimensions as constants
    private let thumbWidth: CGFloat = 35
    private let trackHeight: CGFloat = 8
    
    var body: some View {
        ZStack {
            // Background
            Color(userModel.activeTheme.mainColor)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom header
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
                
                ScrollView {
                    VStack(spacing: 20) {
                        HStack {
                            Text("How are you feeling right now?")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        // Compact mood slider
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("My mood:")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Spacer()
                                
                                Text("\(moodRating)/10")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                            }
                            
                            HStack(spacing: 8) {
                                Image(systemName: "😔")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                
                                // Custom slider
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        // Background track
                                        Capsule()
                                            .fill(Color.white.opacity(0.3))
                                            .frame(height: trackHeight)
                                        
                                        // Filled track - calculate width based on rating
                                        let fillWidth = ((CGFloat(moodRating) - 1) / 9) * geometry.size.width
                                        Capsule()
                                            .fill(moodColor(for: moodRating))
                                            .frame(width: fillWidth, height: trackHeight)
                                        
                                        // Add white circle thumb with number inside
                                        let thumbPosition = ((CGFloat(moodRating) - 1) / 9) * (geometry.size.width - thumbWidth)
                                        Circle()
                                            .fill(.white)
                                            .frame(width: thumbWidth, height: thumbWidth)
                                            .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 1)
                                            .overlay(
                                                Text("\(moodRating)")
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundColor(userModel.activeTheme.mainColor)
                                            )
                                            .offset(x: thumbPosition)
                                            .scaleEffect(isDragging ? 1.1 : 1.0)
                                            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isDragging)
                                    }
                                    .gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { value in
                                                let percentage = min(max(0, value.location.x / geometry.size.width), 1)
                                                let newRating = Int(percentage * 9) + 1
                                                if newRating != moodRating {
                                                    withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.7, blendDuration: 0.1)) {
                                                        moodRating = newRating
                                                        isDragging = true
                                                    }
                                                    // Add haptic feedback
                                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                                    generator.impactOccurred()
                                                }
                                            }
                                            .onEnded { _ in
                                                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                                    isDragging = false
                                                }
                                            }
                                    )
                                }
                                .frame(height: 30)
                                
                                Image(systemName: "😄")
                                    .font(.title3)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Input section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Share your thoughts")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Spacer()
                                
                                // Toggle between voice and text input
                                Button {
                                    showRecordingUI.toggle()
                                    if showRecordingUI {
                                        // Reset recording state when switching to voice
                                        isRecording = false
                                        whisperService.resetState()
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: showRecordingUI ? "mic.fill" : "keyboard")
                                            .foregroundColor(.white)
                                        Text(showRecordingUI ? "Voice" : "Text")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(12)
                                }
                            }
                            
                            if showRecordingUI {
                                // Voice recording UI
                                VStack(alignment: .center, spacing: 10) {
                                    Button {
                                        if isRecording {
                                            // Stop recording
                                            whisperService.stopRecording()
                                            isRecording = false
                                        } else {
                                            // Start recording
                                            whisperService.transcriptionCompletionHandler = { transcription in
                                                note = transcription
                                            }
                                            whisperService.startRecording()
                                            isRecording = true
                                            // Haptic feedback
                                            let generator = UIImpactFeedbackGenerator(style: .medium)
                                            generator.impactOccurred()
                                        }
                                    } label: {
                                        VStack(alignment: .center, spacing: 8) {
                                            Circle()
                                                .fill(Color.white.opacity(0.2))
                                                .frame(width: 60, height: 60)
                                                .overlay(
                                                    Group {
                                                        if isRecording {
                                                            // Recording indicator
                                                            ZStack {
                                                                Circle()
                                                                    .fill(Color.red.opacity(0.8))
                                                                    .frame(width: 20, height: 20)
                                                                
                                                                Circle()
                                                                    .stroke(Color.red, lineWidth: 2)
                                                                    .frame(width: 36, height: 36)
                                                                    .scaleEffect(isRecording ? 1.5 : 1.0)
                                                                    .opacity(isRecording ? 0.0 : 1.0)
                                                                    .animation(
                                                                        Animation.easeOut(duration: 1)
                                                                            .repeatForever(autoreverses: false),
                                                                        value: isRecording
                                                                    )
                                                            }
                                                        } else if whisperService.isTranscribing {
                                                            // Transcribing indicator
                                                            ProgressView()
                                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                                .scaleEffect(1.2)
                                                        } else {
                                                            Image(systemName: "mic.fill")
                                                                .font(.title3)
                                                                .foregroundColor(.white)
                                                        }
                                                    }
                                                )
                                            
                                            Text(isRecording ? "Tap to stop" : whisperService.isTranscribing ? "Transcribing..." : "Tap to record")
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.8))
                                        }
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                    .frame(maxWidth: .infinity)
                                
                                    if !whisperService.permissionGranted && whisperService.errorMessage != nil {
                                        Text(whisperService.errorMessage ?? "Permission needed")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                            .padding(.top, 4)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                    }
                                    
                                    if !whisperService.transcription.isEmpty {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Transcription:")
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.8))
                                            
                                            Text(whisperService.transcription)
                                                .font(.body)
                                                .foregroundColor(.white)
                                                .padding()
                                                .background(Color.white.opacity(0.15))
                                                .cornerRadius(10)
                                            
                                            Button("Use This Text") {
                                                note = whisperService.transcription
                                                showRecordingUI = false // Switch to text mode
                                                whisperService.resetState()
                                            }
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 6)
                                            .background(Color.white.opacity(0.2))
                                            .cornerRadius(12)
                                            .padding(.top, 5)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding()
                                        .background(Color.white.opacity(0.1))
                                        .cornerRadius(12)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 30)
                            } else {
                                // Text input
                                TextEditor(text: $note)
                                    .foregroundColor(.white)
                                    .scrollContentBackground(.hidden)
                                    .background(Color.white.opacity(0.15))
                                    .cornerRadius(10)
                                    .frame(minHeight: 120)
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                        
                        Button(action: {
                            // Save quick update
                            userModel.addQuickUpdate(rating: moodRating, note: note.isEmpty ? nil : note)
                            
                            // Haptic feedback
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                            
                            // Navigate back
                            dismiss()
                        }) {
                            Text("Save Update")
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
        }
        .navigationBarHidden(true)
        .onAppear {
            whisperService.resetState()
        }
        .onDisappear {
            if whisperService.isRecording {
                whisperService.stopRecording()
            }
            whisperService.resetState()
        }
    }
    
    private func moodColor(for rating: Int) -> Color {
        switch rating {
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
}

// TimelineView for displaying all entries
struct TimelineView: View {
    @EnvironmentObject private var userModel: UserModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date()
    @State private var showCalendar = false
    
    var body: some View {
        ZStack {
            // Background color
            Color(userModel.activeTheme.mainColor)
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
                    
                    Text(isToday ? "Today's Timeline" : "Timeline")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Calendar button
                    Button(action: {
                        showCalendar.toggle()
                    }) {
                        Image(systemName: "calendar")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Date navigation and update count
                HStack {
                    // Date navigation controls
                    HStack(spacing: 15) {
                        // Previous day button
                        Button(action: {
                            goToPreviousDay()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Circle().fill(Color.white.opacity(0.2)))
                        }
                        
                        // Date display with tap to show calendar
                        Button(action: {
                            showCalendar.toggle()
                        }) {
                            Text(formattedDate())
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        // Next day button (disabled if it's today)
                        Button(action: {
                            goToNextDay()
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Circle().fill(Color.white.opacity(0.2)))
                        }
                        .disabled(isToday)
                        .opacity(isToday ? 0.5 : 1.0)
                    }
                    
                    Spacer()
                    
                    // Use proper pluralization for updates count
                    let count = userModel.getTimelineUpdateCount(for: selectedDate)
                    if count == 1 {
                        Text("1 update")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(15)
                    } else {
                        Text("\(count) updates")
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
                
                // Today button (only visible when not on today)
                if !isToday {
                    Button(action: {
                        withAnimation {
                            selectedDate = Date()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 12))
                            Text("Today")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(userModel.activeTheme.mainColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(.white))
                    }
                    .padding(.bottom, 6)
                }
                
                // Timeline entries with floating button
                ZStack(alignment: .bottomTrailing) {
                    if userModel.getTimelineEntries(for: selectedDate).isEmpty {
                        // Empty state
                        VStack(spacing: 16) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.4))
                                .padding(.bottom, 10)
                            
                            Text("No entries for this date")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.8))
                            
                            if !isToday {
                                Text("Try another date or add an entry to today's timeline")
                                    .font(.subheadline)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.white.opacity(0.6))
                                    .padding(.horizontal, 20)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.bottom, 80)
                    } else {
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(userModel.getTimelineEntries(for: selectedDate)) { entry in
                                    TimelineEntryRow(entry: entry)
                                }
                            }
                            .padding(.bottom, 100) // Add padding for floating button
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    
                    // Only show floating add button when viewing today
                    if isToday {
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
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Date picker overlay
            if showCalendar {
                ZStack {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            showCalendar = false
                        }
                    
                    VStack {
                        // Calendar header
                        HStack {
                            Text("Select Date")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button("Done") {
                                showCalendar = false
                            }
                            .foregroundColor(userModel.activeTheme.mainColor)
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                        
                        // Date picker
                        DatePicker("", selection: $selectedDate, in: ...Date(), displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .tint(Color(userModel.activeTheme.mainColor))
                            .padding()
                    }
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)))
                    .padding()
                }
                .transition(.opacity)
                .animation(.easeInOut, value: showCalendar)
            }
        }
        .navigationBarHidden(true)
    }
    
    // Helper function to format date
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: selectedDate)
    }
    
    // Check if selected date is today
    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
    
    // Go to previous day
    private func goToPreviousDay() {
        withAnimation {
            if let newDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) {
                selectedDate = newDate
            }
        }
    }
    
    // Go to next day (should be disabled if it's today)
    private func goToNextDay() {
        withAnimation {
            if !isToday, let newDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) {
                selectedDate = newDate
            }
        }
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
                Text(formattedTime(date: entry.date))
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