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
    
    static func == (lhs: ThemeGradient, rhs: ThemeGradient) -> Bool {
        return lhs.name == rhs.name
    }
}

// Structure for mood entries
struct MoodEntry: Identifiable, Codable {
    var id: String = UUID().uuidString
    var rating: Int
    var note: String?
    var audioURL: String?
    var timestamp: Date
    var checkInType: CheckInType
    
    enum CheckInType: String, Codable {
        case morning
        case evening
    }
}

// Main user model for preferences and data
class UserModel: ObservableObject {
    @Published var isOnboarded: Bool = false
    @Published var selectedThemeIndex: Int = 0
    @Published var moodEntries: [MoodEntry] = []
    
    // Theme gradient options
    let themeGradients: [ThemeGradient] = [
        ThemeGradient(name: "lavender", colors: [Color(hex: "8B7FF0"), Color(hex: "7E6EF4")]),
        ThemeGradient(name: "sunset", colors: [Color(hex: "FF9190"), Color(hex: "FFC389")]),
        ThemeGradient(name: "ocean", colors: [Color(hex: "00B4DB"), Color(hex: "0083B0")]),
        ThemeGradient(name: "mint", colors: [Color(hex: "A1DEA8"), Color(hex: "57C478")]),
        ThemeGradient(name: "rose", colors: [Color(hex: "FF5E7E"), Color(hex: "FF99AC")]),
        ThemeGradient(name: "midnight", colors: [Color(hex: "232526"), Color(hex: "414345")]),
        ThemeGradient(name: "sunshine", colors: [Color(hex: "FFDE59"), Color(hex: "FFB830")]),
        ThemeGradient(name: "purple", colors: [Color(hex: "A742EB"), Color(hex: "7F45E8")]),
        ThemeGradient(name: "tranquil", colors: [Color(hex: "74EBD5"), Color(hex: "9FACE6")]),
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
    
    // Add a new mood entry
    func addMoodEntry(rating: Int, note: String? = nil, audioURL: String? = nil, checkInType: MoodEntry.CheckInType) {
        // Create new entry
        let newEntry = MoodEntry(
            rating: rating,
            note: note,
            audioURL: audioURL,
            timestamp: Date(),
            checkInType: checkInType
        )
        
        // Add to local array
        moodEntries.append(newEntry)
        
        // Save changes
        savePreferences()
    }
    
    // Get average mood for a specific time period
    func getAverageMood(for days: Int) -> Double {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!
        
        let filteredEntries = moodEntries.filter { $0.timestamp >= startDate }
        
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