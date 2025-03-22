//
//  UserModel.swift
//  FeelGood
//
//  Created for FeelGood on 3/20/25.
//

import SwiftUI

// Theme gradient structure
struct ThemeGradient: Identifiable, Equatable {
    var id = UUID().uuidString
    var name: String
    var colors: [Color]
    var startPoint: UnitPoint = .top
    var endPoint: UnitPoint = .bottom
    
    // Helper computed property to access main color
    var mainColor: Color {
        return colors[0]
    }
    
    static func == (lhs: ThemeGradient, rhs: ThemeGradient) -> Bool {
        return lhs.name == rhs.name
    }
}

// Structure for mood entries
struct MoodEntry: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var rating: Int
    var note: String?
    var audioURL: URL?
    var checkInType: CheckInType
    var transcription: String?
    
    init(date: Date = Date(), rating: Int, note: String? = nil, audioURL: URL? = nil, checkInType: CheckInType, transcription: String? = nil) {
        self.date = date
        self.rating = rating
        self.note = note
        self.audioURL = audioURL
        self.checkInType = checkInType
        self.transcription = transcription
    }
}

// Make CheckInType accessible outside MoodEntry
enum CheckInType: String, Codable {
    case morning
    case evening
    case quickUpdate
}

// Define timeline entry types
enum TimelineEntryType: String, Codable {
    case moodUpdate
    case checkIn
    case note
}

// Main user model for preferences and data
class UserModel: ObservableObject {
    @Published var isOnboarded: Bool = false
    @Published var selectedThemeIndex: Int = 0
    @Published var moodEntries: [MoodEntry] = []
    
    // Theme options with carefully selected soothing colors
    let themeGradients: [ThemeGradient] = [
        // Calming Purple - promotes creativity and peace
        ThemeGradient(name: "calmPurple", colors: [Color(hex: "7E5BE3")]),
        
        // Serene Blue - promotes relaxation and tranquility
        ThemeGradient(name: "sereneBlue", colors: [Color(hex: "4A90E2")]),
        
        // Soothing Green - promotes balance and harmony
        ThemeGradient(name: "soothingGreen", colors: [Color(hex: "66BB6A")]),
        
        // Warm Peach - promotes comfort and safety
        ThemeGradient(name: "warmPeach", colors: [Color(hex: "FFAB91")]),
        
        // Gentle Lavender - promotes calmness and serenity
        ThemeGradient(name: "gentleLavender", colors: [Color(hex: "9575CD")]),
        
        // Soft Teal - promotes mental clarity and stability
        ThemeGradient(name: "softTeal", colors: [Color(hex: "4DB6AC")]),
        
        // Tranquil Rose - promotes love and compassion
        ThemeGradient(name: "tranquilRose", colors: [Color(hex: "F06292")]),
        
        // Comfort Orange - promotes enthusiasm and energy
        ThemeGradient(name: "comfortOrange", colors: [Color(hex: "FF9800")]),
        
        // Mindful Indigo - promotes intuition and deep thought
        ThemeGradient(name: "mindfulIndigo", colors: [Color(hex: "5C6BC0")]),
        
        // Blissful Mint - promotes freshness and clarity
        ThemeGradient(name: "blissfulMint", colors: [Color(hex: "4DD0E1")]),
    ]
    
    // Active theme gradient
    var activeTheme: ThemeGradient {
        return themeGradients[selectedThemeIndex]
    }
    
    // Initialize from UserDefaults for local preferences
    init() {
        // Load user preferences
        let defaults = UserDefaults.standard
        isOnboarded = defaults.bool(forKey: "isOnboarded")
        
        // Load theme color
        if let themeIndex = defaults.object(forKey: "selectedThemeIndex") as? Int {
            selectedThemeIndex = themeIndex < themeGradients.count ? themeIndex : 0
        }
        
        // Load local mood entries if any
        if let savedEntriesData = UserDefaults.standard.data(forKey: "moodEntries"),
           let decodedEntries = try? JSONDecoder().decode([MoodEntry].self, from: savedEntriesData) {
            moodEntries = decodedEntries
        }
    }
    
    // Save user preferences
    func savePreferences() {
        let defaults = UserDefaults.standard
        defaults.set(isOnboarded, forKey: "isOnboarded")
        defaults.set(selectedThemeIndex, forKey: "selectedThemeIndex")
        
        // Save mood entries locally
        if let encodedData = try? JSONEncoder().encode(moodEntries) {
            defaults.set(encodedData, forKey: "moodEntries")
        }
    }
    
    // Save data to persistent storage
    func saveData() {
        savePreferences()
    }
    
    // Add an entry to the timeline
    func addTimelineEntry(text: String, type: TimelineEntryType) {
        // In the current implementation, this is handled through addQuickUpdate or addMoodEntry
        // This method can be extended later if needed
    }
    
    // Add a new mood entry
    func addMoodEntry(rating: Int, note: String? = nil, audioURL: URL? = nil, transcription: String? = nil, checkInType: CheckInType = .morning) {
        // Check if we already have an entry for today of the same type
        if let index = moodEntries.firstIndex(where: { 
            Calendar.current.isDate($0.date, inSameDayAs: Date()) && 
            $0.checkInType == checkInType
        }) {
            // Update existing entry
            moodEntries[index].rating = rating
            moodEntries[index].note = note
            
            // Only update audio URL if provided
            if let audioURL = audioURL {
                moodEntries[index].audioURL = audioURL
            }
            
            // Only update transcription if provided
            if let transcription = transcription {
                moodEntries[index].transcription = transcription
            }
        } else {
            // Create new entry
            let newEntry = MoodEntry(
                rating: rating,
                note: note,
                audioURL: audioURL,
                checkInType: checkInType,
                transcription: transcription
            )
            moodEntries.append(newEntry)
        }
        
        // Also add to timeline
        addTimelineEntry(text: note ?? transcription ?? "Updated my mood to \(rating)/10", type: .moodUpdate)
        
        saveData()
    }
    
    // Get today's entry index for a specific check-in type (morning/evening)
    private func getTodayEntryIndex(forType type: CheckInType) -> Int? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return moodEntries.firstIndex(where: { entry in
            let entryDay = calendar.startOfDay(for: entry.date)
            return calendar.isDate(entryDay, inSameDayAs: today) && entry.checkInType == type
        })
    }
    
    // Get today's mood rating for a specific check-in type
    func getTodayMood(forType type: CheckInType) -> Int? {
        if let index = getTodayEntryIndex(forType: type) {
            return moodEntries[index].rating
        }
        return nil
    }
    
    // Get number of entries for today
    func getTodayEntriesCount() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return moodEntries.filter { entry in
            let entryDay = calendar.startOfDay(for: entry.date)
            return calendar.isDate(entryDay, inSameDayAs: today)
        }.count
    }
    
    // Get the most recent entry
    func getLastEntry() -> MoodEntry? {
        return moodEntries.sorted { $0.date > $1.date }.first
    }
    
    // Get today's entries
    func getTodayEntries() -> [MoodEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return moodEntries.filter { entry in
            let entryDay = calendar.startOfDay(for: entry.date)
            return calendar.isDate(entryDay, inSameDayAs: today)
        }.sorted { $0.date > $1.date }
    }
    
    // Add a quick update to the timeline
    func addQuickUpdate(rating: Int? = nil, note: String? = nil, audioURL: URL? = nil) {
        // Create new entry with optional rating
        let newEntry = MoodEntry(
            rating: rating ?? 0, // Use 0 to indicate no rating provided
            note: note,
            audioURL: audioURL,
            checkInType: .quickUpdate,
            transcription: nil
        )
        
        // Add to local array
        moodEntries.append(newEntry)
        
        // Save changes
        savePreferences()
    }
    
    // Get timeline entries for today
    func getTimelineEntries() -> [MoodEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Get all entries from today
        let todayEntries = moodEntries.filter { entry in
            let entryDay = calendar.startOfDay(for: entry.date)
            return calendar.isDate(entryDay, inSameDayAs: today)
        }
        
        // Sort by date in descending order (newest first)
        return todayEntries.sorted { $0.date > $1.date }
    }
    
    // Get update count for the timeline
    func getTimelineUpdateCount() -> Int {
        // This returns the actual count of all meaningful entries
        return getTimelineEntries().count
    }
    
    // Get average mood for a specific time period
    func getAverageMood(for days: Int) -> Double {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!
        
        let filteredEntries = moodEntries.filter { $0.date >= startDate }
        
        guard !filteredEntries.isEmpty else { return 0 }
        
        let sum = filteredEntries.reduce(0) { $0 + $1.rating }
        return Double(sum) / Double(filteredEntries.count)
    }
}

// Helper extension for hex color support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 