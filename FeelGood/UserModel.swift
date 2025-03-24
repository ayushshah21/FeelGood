//
//  UserModel.swift
//  FeelGood
//
//  Created for FeelGood on 3/20/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

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
    var id: UUID
    var date: Date
    var rating: Int
    var note: String?
    var audioURL: URL?
    var checkInType: CheckInType
    var transcription: String?
    
    init(id: UUID = UUID(), date: Date = Date(), rating: Int, note: String? = nil, audioURL: URL? = nil, checkInType: CheckInType, transcription: String? = nil) {
        self.id = id
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
    @Published var userId: String? = nil  // Store Firebase user ID
    @Published var isLoadingData: Bool = false
    @Published var syncError: String? = nil
    
    // Firestore reference
    private var db = Firestore.firestore()
    
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
        
        // Load user ID if saved
        userId = defaults.string(forKey: "userId")
        
        // Load local mood entries if any
        if let savedEntriesData = UserDefaults.standard.data(forKey: "moodEntries"),
           let decodedEntries = try? JSONDecoder().decode([MoodEntry].self, from: savedEntriesData) {
            moodEntries = decodedEntries
        }
        
        // If user is already authenticated, fetch their data from Firestore
        if let userId = userId {
            fetchUserData(userId: userId)
        }
        
        // Listen for auth state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let userId = user?.uid {
                self?.userId = userId
                self?.savePreferences()
                self?.fetchUserData(userId: userId)
            } else {
                self?.userId = nil
                self?.savePreferences()
            }
        }
    }
    
    // Fetch user data from Firestore
    func fetchUserData(userId: String) {
        isLoadingData = true
        syncError = nil
        
        // First, fetch user profile
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            if let error = error {
                self?.syncError = "Error fetching user data: \(error.localizedDescription)"
                self?.isLoadingData = false
                return
            }
            
            // If user document doesn't exist yet, create it
            guard let document = document, document.exists else {
                // Create user profile
                self?.createUserProfile(userId: userId)
                self?.fetchMoodEntries(userId: userId)
                return
            }
            
            // User profile exists, update local data if needed
            if let data = document.data() {
                // If theme color is stored in profile, use it
                if let themeIndex = data["themeIndex"] as? Int {
                    self?.selectedThemeIndex = themeIndex
                }
            }
            
            // Continue to fetch mood entries
            self?.fetchMoodEntries(userId: userId)
        }
    }
    
    // Create initial user profile in Firestore
    private func createUserProfile(userId: String) {
        let userData: [String: Any] = [
            "themeIndex": selectedThemeIndex,
            "isOnboarded": true,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        db.collection("users").document(userId).setData(userData) { [weak self] error in
            if let error = error {
                self?.syncError = "Error creating user profile: \(error.localizedDescription)"
            }
        }
    }
    
    // Fetch mood entries from Firestore
    private func fetchMoodEntries(userId: String) {
        print("🔍 fetchMoodEntries: Starting fetch for user \(userId)")
        
        db.collection("users").document(userId).collection("mood_logs")
            .order(by: "date", descending: true)
            .getDocuments { [weak self] querySnapshot, error in
                self?.isLoadingData = false
                if let error = error {
                    print("❌ fetchMoodEntries: Error fetching data: \(error.localizedDescription)")
                    self?.syncError = "Error fetching mood entries: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("❌ fetchMoodEntries: No documents found (querySnapshot.documents is nil)")
                    return
                }
                
                print("📊 fetchMoodEntries: Received \(documents.count) documents from Firestore")
                
                if documents.isEmpty {
                    print("⚠️ fetchMoodEntries: No entries yet in Firestore")
                    // No entries yet in Firestore, upload local entries if any
                    if let self = self, !self.moodEntries.isEmpty {
                        print("🔄 fetchMoodEntries: Found \(self.moodEntries.count) local entries, syncing to Firestore")
                        self.syncMoodEntriesToFirestore()
                    } else {
                        print("⚠️ fetchMoodEntries: No local entries to sync")
                    }
                    return
                }
                
                // Process fetched entries
                var firestoreEntries: [MoodEntry] = []
                
                for document in documents {
                    let data = document.data()
                    
                    // Convert Firestore data to MoodEntry
                    if let dateTimestamp = data["date"] as? Timestamp,
                       let rating = data["rating"] as? Int,
                       let checkInTypeRaw = data["checkInType"] as? String,
                       let checkInType = CheckInType(rawValue: checkInTypeRaw) {
                        
                        let entry = MoodEntry(
                            id: UUID(uuidString: document.documentID) ?? UUID(),
                            date: dateTimestamp.dateValue(),
                            rating: rating,
                            note: data["note"] as? String,
                            audioURL: nil, // We'll implement audio storage later
                            checkInType: checkInType,
                            transcription: data["transcription"] as? String
                        )
                        
                        firestoreEntries.append(entry)
                    } else {
                        print("⚠️ fetchMoodEntries: Skipping document \(document.documentID) due to missing or invalid fields")
                        // Debug the document content
                        print("Document data: \(data)")
                    }
                }
                
                print("✅ fetchMoodEntries: Successfully parsed \(firestoreEntries.count) entries from Firestore")
                
                // If we have entries from Firestore, use them
                if !firestoreEntries.isEmpty {
                    self?.moodEntries = firestoreEntries
                    self?.savePreferences() // Save to local storage as backup
                    print("💾 fetchMoodEntries: Updated local moodEntries array and saved to preferences")
                } else {
                    print("⚠️ fetchMoodEntries: No valid entries found in Firestore documents")
                }
            }
    }
    
    // Sync current mood entries to Firestore
    private func syncMoodEntriesToFirestore() {
        guard let userId = userId else {
            print("❌ syncMoodEntriesToFirestore: Cannot sync - userId is nil")
            return
        }
        
        print("🔄 syncMoodEntriesToFirestore: Starting sync for user \(userId)")
        
        let batch = db.batch()
        
        for entry in moodEntries {
            let entryRef = db.collection("users").document(userId).collection("mood_logs").document(entry.id.uuidString)
            
            // Convert MoodEntry to Firestore data
            var entryData: [String: Any] = [
                "date": Timestamp(date: entry.date),
                "rating": entry.rating,
                "checkInType": entry.checkInType.rawValue
            ]
            
            // Add optional fields
            if let note = entry.note {
                entryData["note"] = note
            }
            
            if let transcription = entry.transcription {
                entryData["transcription"] = transcription
            }
            
            batch.setData(entryData, forDocument: entryRef)
        }
        
        // Commit the batch
        batch.commit { [weak self] error in
            if let error = error {
                print("❌ syncMoodEntriesToFirestore: Error syncing data: \(error.localizedDescription)")
                self?.syncError = "Error syncing mood entries: \(error.localizedDescription)"
            } else {
                print("✅ syncMoodEntriesToFirestore: Successfully synced \(self?.moodEntries.count ?? 0) entries")
            }
        }
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
            
            // Save to Firestore
            saveEntryToFirestore(moodEntries[index])
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
            
            // Save to Firestore
            saveEntryToFirestore(newEntry)
        }
        
        // Also add to timeline
        addTimelineEntry(text: note ?? transcription ?? "Updated my mood to \(rating)/10", type: .moodUpdate)
        
        saveData()
    }
    
    // Save a single entry to Firestore
    private func saveEntryToFirestore(_ entry: MoodEntry) {
        guard let userId = userId else { return }
        
        let entryRef = db.collection("users").document(userId).collection("mood_logs").document(entry.id.uuidString)
        
        // Convert MoodEntry to Firestore data
        var entryData: [String: Any] = [
            "date": Timestamp(date: entry.date),
            "rating": entry.rating,
            "checkInType": entry.checkInType.rawValue
        ]
        
        // Add optional fields
        if let note = entry.note {
            entryData["note"] = note
        }
        
        if let transcription = entry.transcription {
            entryData["transcription"] = transcription
        }
        
        // Save to Firestore
        entryRef.setData(entryData) { [weak self] error in
            if let error = error {
                self?.syncError = "Error saving mood entry: \(error.localizedDescription)"
            }
        }
    }
    
    // Update user profile in Firestore when preferences change
    private func updateUserProfile() {
        guard let userId = userId else { return }
        
        let userData: [String: Any] = [
            "themeIndex": selectedThemeIndex,
            "isOnboarded": isOnboarded,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        // Use setData with merge option instead of updateData to handle non-existent documents
        db.collection("users").document(userId).setData(userData, merge: true) { [weak self] error in
            if let error = error {
                self?.syncError = "Error updating user profile: \(error.localizedDescription)"
            }
        }
    }
    
    // Save user preferences
    func savePreferences() {
        let defaults = UserDefaults.standard
        defaults.set(isOnboarded, forKey: "isOnboarded")
        defaults.set(selectedThemeIndex, forKey: "selectedThemeIndex")
        
        // Save userId if available
        if let userId = userId {
            defaults.set(userId, forKey: "userId")
            
            // Update user profile in Firestore
            updateUserProfile()
        } else {
            defaults.removeObject(forKey: "userId")
        }
        
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
        
        // Save to Firestore
        saveEntryToFirestore(newEntry)
        
        // Save changes
        savePreferences()
    }
    
    // Get timeline entries for today
    func getTimelineEntries() -> [MoodEntry] {
        return getTimelineEntries(for: Date())
    }
    
    // Get timeline entries for a specific date
    func getTimelineEntries(for date: Date) -> [MoodEntry] {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)
        
        // Get all entries from the specified date
        let dateEntries = moodEntries.filter { entry in
            let entryDay = calendar.startOfDay(for: entry.date)
            return calendar.isDate(entryDay, inSameDayAs: targetDay)
        }
        
        // Sort by date in descending order (newest first)
        return dateEntries.sorted { $0.date > $1.date }
    }
    
    // Get update count for the timeline
    func getTimelineUpdateCount() -> Int {
        // This returns the actual count of all meaningful entries for today
        return getTimelineEntries().count
    }
    
    // Get update count for a specific date
    func getTimelineUpdateCount(for date: Date) -> Int {
        // This returns the actual count of all meaningful entries for the specified date
        return getTimelineEntries(for: date).count
    }
    
    // Get entries for a specific date and type
    func getEntries(for date: Date, type: CheckInType?) -> [MoodEntry] {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)
        
        return moodEntries.filter { entry in
            let entryDay = calendar.startOfDay(for: entry.date)
            if let type = type {
                return calendar.isDate(entryDay, inSameDayAs: targetDay) && entry.checkInType == type
            } else {
                return calendar.isDate(entryDay, inSameDayAs: targetDay)
            }
        }.sorted { $0.date > $1.date }
    }
    
    // Get average mood for a date
    func getAverageMood(for date: Date) -> Double? {
        let entries = getEntries(for: date, type: nil)
        guard !entries.isEmpty else { return nil }
        
        let sum = entries.reduce(0) { $0 + $1.rating }
        return Double(sum) / Double(entries.count)
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
    
    // Generate mock mood data for testing
    func generateMockMoodData() {
        print("🔍 Starting generateMockMoodData")
        
        // Check if user is signed in
        guard let userId = userId else {
            print("❌ Error: userId is nil - user not signed in")
            syncError = "Error: Not signed in. Please sign in to generate mock data."
            return
        }
        
        print("✅ User is signed in with userId: \(userId)")
        
        // Clear existing entries first
        moodEntries.removeAll()
        
        // Create a calendar for date manipulation
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Mock data for March 13-22, 2025
        let mockData: [(date: String, morning: (rating: Int, note: String?), evening: (rating: Int, note: String?), quickUpdates: [(time: String, rating: Int, note: String)])] = [
            // March 13 (Thursday) - Heavy CS theory day
            (date: "2025-03-13", 
             morning: (5, "Another day of classes I don't care about. Dreading the algorithms lecture."),
             evening: (6, "At least the day is over. Studied with Sarah which made it slightly better."),
             quickUpdates: [("14:30", 3, "Just got my programming assignment back. I put in so many hours and only got a B-. Starting to think I'm not cut out for this.")]),
            
            // March 14 (Friday) - Presentation day
            (date: "2025-03-14",
             morning: (4, "Have to present in CS class today. Honestly don't even understand what I'm talking about."),
             evening: (7, "Friday night! Going out with friends. At least the weekend is here."),
             quickUpdates: []),
             
            // March 15 (Saturday) - Weekend but with project work
            (date: "2025-03-15",
             morning: (6, "No classes today, but have to work on this programming project that makes no sense to me."),
             evening: (8, "Hung out at the lake with friends. Wish life could be more like this and less coding."),
             quickUpdates: [("16:00", 7, "Taking a break from coding. Maybe I should explore other majors...")]),
             
            // March 16 (Sunday) - Reflection day
            (date: "2025-03-16",
             morning: (5, "Thinking about talking to my advisor about switching majors. Feel so lost."),
             evening: (6, "Looked at some psychology courses online. They actually seem interesting."),
             quickUpdates: []),
             
            // March 17 (Monday) - Start of new week
            (date: "2025-03-17",
             morning: (4, "Monday again. Can't focus in Data Structures class."),
             evening: (5, "Tried to do the coding homework but just felt overwhelmed."),
             quickUpdates: [("13:15", 3, "Failed another pop quiz in CS. When will this get easier?")]),
             
            // March 18 (Tuesday) - Slightly better day
            (date: "2025-03-18",
             morning: (5, "At least today's classes are more manageable."),
             evening: (6, "Had a good conversation with my roommate about maybe switching to Business major."),
             quickUpdates: []),
             
            // March 19 (Wednesday) - Mixed feelings
            (date: "2025-03-19",
             morning: (5, "Had a dream I switched to psychology. Woke up feeling confused about my future."),
             evening: (6, "Talked to my advisor about possibly exploring other classes next semester. Still uncertain."),
             quickUpdates: [("15:45", 7, "Art history elective was actually interesting today. First time I've been engaged in class all week.")]),
             
            // March 20 (Thursday) - Group project day
            (date: "2025-03-20",
             morning: (4, "Group project meeting for CS today. I feel like everyone knows more than me."),
             evening: (5, "My part of the project is due tomorrow and I'm struggling to understand the requirements."),
             quickUpdates: [("14:00", 3, "My group members seem frustrated with my lack of progress.")]),
             
            // March 21 (Friday) - End of week reflection
            (date: "2025-03-21",
             morning: (5, "Last day of the week. Just need to get through this."),
             evening: (7, "Weekend plans with non-CS friends! Need this break from thinking about code."),
             quickUpdates: [("12:30", 4, "Professor asked why I've been so quiet in class lately.")]),
             
            // March 22 (Saturday) - Weekend relief
            (date: "2025-03-22",
             morning: (6, "No coding today. Going to explore some other interests."),
             evening: (8, "Spent the day at an art museum. Haven't felt this peaceful in weeks."),
             quickUpdates: [("15:00", 7, "Found some interesting psychology podcasts. Maybe this is a sign?")])
        ]
        
        // Date formatter for parsing mock dates
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Time formatter for quick updates
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        // Generate entries from mock data
        for dayData in mockData {
            // Get base date from string
            guard let baseDate = dateFormatter.date(from: dayData.date) else { continue }
            
            // Morning entry (8 AM)
            let morningDate = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: baseDate)!
            let morningEntry = MoodEntry(
                date: morningDate,
                rating: dayData.morning.rating,
                note: dayData.morning.note,
                checkInType: .morning
            )
            moodEntries.append(morningEntry)
            
            // Evening entry (8 PM)
            let eveningDate = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: baseDate)!
            let eveningEntry = MoodEntry(
                date: eveningDate,
                rating: dayData.evening.rating,
                note: dayData.evening.note,
                checkInType: .evening
            )
            moodEntries.append(eveningEntry)
            
            // Quick updates throughout the day
            for quickUpdate in dayData.quickUpdates {
                guard let time = timeFormatter.date(from: quickUpdate.time) else { continue }
                let quickUpdateDate = calendar.date(
                    bySettingHour: calendar.component(.hour, from: time),
                    minute: calendar.component(.minute, from: time),
                    second: 0,
                    of: baseDate
                )!
                
                let quickUpdateEntry = MoodEntry(
                    date: quickUpdateDate,
                    rating: quickUpdate.rating,
                    note: quickUpdate.note,
                    checkInType: .quickUpdate
                )
                moodEntries.append(quickUpdateEntry)
            }
        }
        
        // Sort entries by date (newest first)
        moodEntries.sort { $0.date > $1.date }
        
        // Save to local storage
        saveData()
        
        print("📝 Created \(moodEntries.count) mood entries locally, preparing to sync to Firestore")
        
        // Show loading indicator
        isLoadingData = true
        
        // Sync to Firestore with completion handler
        let batch = db.batch()
        
        for entry in moodEntries {
            let entryRef = db.collection("users").document(userId).collection("mood_logs").document(entry.id.uuidString)
            
            // Convert MoodEntry to Firestore data
            var entryData: [String: Any] = [
                "date": Timestamp(date: entry.date),
                "rating": entry.rating,
                "checkInType": entry.checkInType.rawValue
            ]
            
            // Add optional fields
            if let note = entry.note {
                entryData["note"] = note
            }
            
            if let transcription = entry.transcription {
                entryData["transcription"] = transcription
            }
            
            batch.setData(entryData, forDocument: entryRef)
        }
        
        print("🔄 Committing batch with \(moodEntries.count) entries to Firestore...")
        
        // Commit the batch
        batch.commit { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoadingData = false
                
                if let error = error {
                    print("❌ Error syncing mock data to Firestore: \(error.localizedDescription)")
                    self?.syncError = "Error syncing mock data: \(error.localizedDescription)"
                } else {
                    print("✅ Successfully synced mock data to Firestore")
                    // Verify the data was saved by fetching it
                    if let userId = self?.userId {
                        print("🔍 Verifying data by fetching from Firestore...")
                        self?.fetchMoodEntries(userId: userId)
                    } else {
                        print("❌ Cannot verify data - userId is nil after sync")
                    }
                }
            }
        }
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