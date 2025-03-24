//
//  InsightsDashboardView.swift
//  FeelGood
//
//  Created for FeelGood.
//

import SwiftUI
import Charts

struct InsightsDashboardView: View {
    @EnvironmentObject private var userModel: UserModel
    @State private var selectedTimeRange: TimeRange = .week
    @State private var isLoading = false
    
    enum TimeRange: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Section
                headerSection
                
                // Primary Visualization - Mood Timeline Chart
                moodTimelineSection
                
                // Key Metrics Cards
                keyMetricsSection
                
                // Recent Patterns
                recentPatternsSection
                
                // Recent Entries Quick View
                recentEntriesSection
            }
            .padding()
        }
        .background(
            Color(userModel.activeTheme.mainColor)
                .ignoresSafeArea()
        )
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Text("Mood Insights")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            // Time Range Selector
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .background(Color.white.opacity(0.2))
            .cornerRadius(8)
            .tint(.white)
            
            // Mood based on selected time range
            if selectedTimeRange == .week, let todayMood = todaysAverageMood {
                HStack {
                    Text("Today's mood:")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("\(todayMood, specifier: "%.1f")")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(moodEmoji(for: Int(todayMood)))
                        .font(.system(size: 28))
                }
                .padding(.vertical, 8)
            } else if let avgMood = averageMood {
                HStack {
                    Text(selectedTimeRange == .month ? "Monthly average:" : "Yearly average:")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("\(avgMood, specifier: "%.1f")")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(moodEmoji(for: Int(avgMood)))
                        .font(.system(size: 28))
                }
                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.15))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    // MARK: - Mood Timeline Chart
    
    private var moodTimelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mood Timeline")
                .font(.headline)
                .foregroundColor(.white)
            
            moodChart
                .frame(height: 240)
                .padding(.top, 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.15))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    private var moodChart: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.15))
            
            if filteredMoodEntries.isEmpty {
                Text("No mood data available for this time period")
                    .foregroundColor(.white.opacity(0.7))
                    .padding()
            } else {
                Chart {
                    ForEach(filteredMoodEntries.sorted(by: { $0.date < $1.date })) { entry in
                        LineMark(
                            x: .value("Date", entry.date),
                            y: .value("Mood", entry.rating)
                        )
                        .foregroundStyle(.white)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                        
                        AreaMark(
                            x: .value("Date", entry.date),
                            y: .value("Mood", entry.rating)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .white.opacity(0.3),
                                    .white.opacity(0.0)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        
                        PointMark(
                            x: .value("Date", entry.date),
                            y: .value("Mood", entry.rating)
                        )
                        .foregroundStyle(.white)
                        .symbolSize(20)
                    }
                }
                .chartYScale(domain: 0...10)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: dateStrideCount)) { value in
                        AxisGridLine(centered: true, stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.white.opacity(0.3))
                        
                        let date = value.as(Date.self)!
                        AxisValueLabel {
                            VStack {
                                Text(formatAxisDate(date))
                                    .font(.caption)
                                    .foregroundStyle(Color.white)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(values: [0, 2, 4, 6, 8, 10]) { value in
                        AxisGridLine(centered: true, stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.white.opacity(0.3))
                        
                        AxisValueLabel()
                            .foregroundStyle(Color.white)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(8)
            }
        }
    }
    
    // Helper for X-axis date stride
    private var dateStrideCount: Int {
        switch selectedTimeRange {
        case .week:
            return 1  // Show every day in a week
        case .month:
            return 3  // Show every 3 days in a month
        case .year:
            return 30 // Show every month in a year
        }
    }
    
    // Format dates for the chart axis
    private func formatAxisDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        switch selectedTimeRange {
        case .week:
            // For week view, show day of week abbreviation (e.g., "Mon")
            formatter.dateFormat = "E"
        case .month:
            // For month view, show day and month (e.g., "15 Jun")
            formatter.dateFormat = "d MMM"
        case .year:
            // For year view, show month abbreviation (e.g., "Jan")
            formatter.dateFormat = "MMM"
        }
        
        return formatter.string(from: date)
    }
    
    // MARK: - Key Metrics Section
    
    private var keyMetricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Metrics")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                // Average Mood
                metricCard(
                    title: "Average Mood",
                    value: averageMood != nil ? String(format: "%.1f", averageMood!) : "N/A",
                    icon: "chart.bar.fill",
                    trendText: trendText
                )
                
                // Consistency
                metricCard(
                    title: "Consistency",
                    value: "\(consistencyPercentage)%",
                    icon: "calendar.badge.clock",
                    trendText: nil
                )
            }
            
            // Mood Range
            if let (lowest, highest) = moodRange {
                metricCard(
                    title: "Mood Range",
                    value: "\(lowest) - \(highest)",
                    icon: "arrow.up.and.down",
                    trendText: nil,
                    fullWidth: true
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.15))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    private func metricCard(title: String, value: String, icon: String, trendText: String?, fullWidth: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            if let trend = trendText {
                Text(trend)
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
        .padding()
        .frame(maxWidth: fullWidth ? .infinity : nil)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.15))
        )
    }
    
    // MARK: - Recent Patterns Section
    
    private var recentPatternsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Patterns")
                .font(.headline)
                .foregroundColor(.white)
            
            // Pattern cards
            ForEach(moodPatterns, id: \.self) { pattern in
                patternCard(pattern: pattern)
            }
            
            if moodPatterns.isEmpty {
                Text("Not enough data to identify patterns")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.15))
                    )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.15))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    private func patternCard(pattern: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: patternIconFor(pattern))
                .font(.title2)
                .foregroundColor(.white)
            
            Text(pattern)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.15))
        )
    }
    
    // MARK: - Recent Entries Section
    
    private var recentEntriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Entries")
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(recentEntries) { entry in
                recentEntryCard(entry: entry)
            }
            
            if recentEntries.isEmpty {
                Text("No recent entries")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.15))
                    )
            }
            
            // View All button
            if !recentEntries.isEmpty {
                NavigationLink(destination: TimelineView()) {
                    Text("View All Entries")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.15))
                        )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.15))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    private func recentEntryCard(entry: MoodEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Date and time
                Text(formatDate(entry.date))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                // Check-in type
                Text(entry.checkInType.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.3))
                    )
                    .foregroundColor(.white)
            }
            
            HStack {
                // Mood rating
                Text("Mood: \(entry.rating)/10")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Text(moodEmoji(for: entry.rating))
                    .font(.system(size: 20))
                
                Spacer()
            }
            
            // Note preview (if available)
            if let note = entry.note, !note.isEmpty {
                Text(note.prefix(50) + (note.count > 50 ? "..." : ""))
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.15))
        )
    }
    
    // MARK: - Helper Methods and Computed Properties
    
    // Get mood entries for the selected time range
    private var filteredMoodEntries: [MoodEntry] {
        let calendar = Calendar.current
        let today = Date()
        let startDate: Date
        
        switch selectedTimeRange {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: today)!
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: today)!
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: today)!
        }
        
        return userModel.moodEntries.filter { $0.date >= startDate && $0.date <= today }
    }
    
    // Calculate today's average mood
    private var todaysAverageMood: Double? {
        let todayEntries = userModel.moodEntries.filter {
            Calendar.current.isDateInToday($0.date)
        }
        
        guard !todayEntries.isEmpty else { return nil }
        
        let sum = todayEntries.reduce(0) { $0 + $1.rating }
        return Double(sum) / Double(todayEntries.count)
    }
    
    // Calculate average mood for selected time range
    private var averageMood: Double? {
        guard !filteredMoodEntries.isEmpty else { return nil }
        
        let sum = filteredMoodEntries.reduce(0) { $0 + $1.rating }
        return Double(sum) / Double(filteredMoodEntries.count)
    }
    
    // Calculate trend compared to previous period
    private var trendText: String? {
        guard let currentAvg = averageMood else { return nil }
        
        let calendar = Calendar.current
        let today = Date()
        let currentStartDate: Date
        let previousStartDate: Date
        let previousEndDate: Date
        
        switch selectedTimeRange {
        case .week:
            currentStartDate = calendar.date(byAdding: .day, value: -7, to: today)!
            previousStartDate = calendar.date(byAdding: .day, value: -14, to: today)!
            previousEndDate = calendar.date(byAdding: .day, value: -8, to: today)!
        case .month:
            currentStartDate = calendar.date(byAdding: .month, value: -1, to: today)!
            previousStartDate = calendar.date(byAdding: .month, value: -2, to: today)!
            previousEndDate = calendar.date(byAdding: .day, value: -1, to: currentStartDate)!
        case .year:
            currentStartDate = calendar.date(byAdding: .year, value: -1, to: today)!
            previousStartDate = calendar.date(byAdding: .year, value: -2, to: today)!
            previousEndDate = calendar.date(byAdding: .day, value: -1, to: currentStartDate)!
        }
        
        let previousEntries = userModel.moodEntries.filter { 
            $0.date >= previousStartDate && $0.date <= previousEndDate 
        }
        
        guard !previousEntries.isEmpty else { return "No previous data" }
        
        let previousSum = previousEntries.reduce(0) { $0 + $1.rating }
        let previousAvg = Double(previousSum) / Double(previousEntries.count)
        
        let difference = ((currentAvg - previousAvg) / previousAvg) * 100
        
        if difference > 0 {
            return "↑ \(String(format: "%.1f", abs(difference)))% from previous"
        } else if difference < 0 {
            return "↓ \(String(format: "%.1f", abs(difference)))% from previous"
        } else {
            return "No change from previous"
        }
    }
    
    // Calculate consistency percentage
    private var consistencyPercentage: Int {
        let calendar = Calendar.current
        let today = Date()
        let numberOfDays: Int
        let startDate: Date
        
        switch selectedTimeRange {
        case .week:
            numberOfDays = 7
            startDate = calendar.date(byAdding: .day, value: -6, to: today)!
        case .month:
            // Approximate a month as 30 days
            numberOfDays = 30
            startDate = calendar.date(byAdding: .day, value: -29, to: today)!
        case .year:
            // Approximate a year as 365 days
            numberOfDays = 365
            startDate = calendar.date(byAdding: .day, value: -364, to: today)!
        }
        
        var daysWithEntries = Set<Date>()
        
        for entry in filteredMoodEntries {
            let day = calendar.startOfDay(for: entry.date)
            daysWithEntries.insert(day)
        }
        
        // If no entries or no days in range, return 0
        guard !daysWithEntries.isEmpty, numberOfDays > 0 else { return 0 }
        
        return Int(Double(daysWithEntries.count) / Double(numberOfDays) * 100)
    }
    
    // Calculate mood range (lowest to highest)
    private var moodRange: (lowest: Int, highest: Int)? {
        guard !filteredMoodEntries.isEmpty else { return nil }
        
        let sortedRatings = filteredMoodEntries.map { $0.rating }.sorted()
        return (lowest: sortedRatings.first!, highest: sortedRatings.last!)
    }
    
    // Get recent entries (last 5)
    private var recentEntries: [MoodEntry] {
        Array(userModel.moodEntries.prefix(5))
    }
    
    // Identify patterns in mood data
    private var moodPatterns: [String] {
        var patterns: [String] = []
        
        // Need minimum amount of data to detect patterns
        guard filteredMoodEntries.count >= 10 else { return [] }
        
        // Morning vs Evening pattern
        let morningEntries = filteredMoodEntries.filter { $0.checkInType == .morning }
        let eveningEntries = filteredMoodEntries.filter { $0.checkInType == .evening }
        
        if !morningEntries.isEmpty && !eveningEntries.isEmpty {
            let morningAvg = morningEntries.reduce(0) { $0 + $1.rating } / morningEntries.count
            let eveningAvg = eveningEntries.reduce(0) { $0 + $1.rating } / eveningEntries.count
            
            if morningAvg > eveningAvg + 1 {
                patterns.append("Your mood tends to be better in the mornings")
            } else if eveningAvg > morningAvg + 1 {
                patterns.append("Your mood tends to improve in the evenings")
            }
        }
        
        // Weekday vs Weekend pattern
        let calendar = Calendar.current
        let weekdayEntries = filteredMoodEntries.filter {
            let weekday = calendar.component(.weekday, from: $0.date)
            return weekday >= 2 && weekday <= 6 // Monday to Friday
        }
        
        let weekendEntries = filteredMoodEntries.filter {
            let weekday = calendar.component(.weekday, from: $0.date)
            return weekday == 1 || weekday == 7 // Sunday or Saturday
        }
        
        if !weekdayEntries.isEmpty && !weekendEntries.isEmpty {
            let weekdayAvg = weekdayEntries.reduce(0) { $0 + $1.rating } / weekdayEntries.count
            let weekendAvg = weekendEntries.reduce(0) { $0 + $1.rating } / weekendEntries.count
            
            if weekendAvg > weekdayAvg + 1 {
                patterns.append("Your mood is typically higher on weekends")
            } else if weekdayAvg > weekendAvg + 1 {
                patterns.append("Your mood is typically higher on weekdays")
            }
        }
        
        // Recent trend pattern
        if filteredMoodEntries.count >= 14 {
            let recentEntries = Array(filteredMoodEntries.prefix(7))
            let olderEntries = Array(filteredMoodEntries.dropFirst(7).prefix(7))
            
            let recentAvg = recentEntries.reduce(0) { $0 + $1.rating } / recentEntries.count
            let olderAvg = olderEntries.reduce(0) { $0 + $1.rating } / olderEntries.count
            
            if recentAvg >= olderAvg + 1 {
                patterns.append("Your mood has been improving recently")
            } else if olderAvg >= recentAvg + 1 {
                patterns.append("Your mood has been declining recently")
            } else {
                patterns.append("Your mood has been stable recently")
            }
        }
        
        return patterns
    }
    
    // Helper function to format dates
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Helper function to get emoji for mood rating
    private func moodEmoji(for rating: Int) -> String {
        switch rating {
        case 1...3: return "😔"
        case 4...6: return "😐"
        case 7...8: return "🙂"
        case 9...10: return "😄"
        default: return "🙂"
        }
    }
    
    // Helper function to get color for check-in type
    private func checkInTypeColor(for type: CheckInType) -> Color {
        switch type {
        case .morning:
            return Color.orange
        case .evening:
            return Color.indigo
        case .quickUpdate:
            return Color.green
        }
    }
    
    // Helper function to get icon for pattern
    private func patternIconFor(_ pattern: String) -> String {
        if pattern.contains("morning") {
            return "sunrise.fill"
        } else if pattern.contains("evening") {
            return "sunset.fill"
        } else if pattern.contains("weekend") {
            return "calendar.badge.clock"
        } else if pattern.contains("improving") {
            return "chart.line.uptrend.xyaxis"
        } else if pattern.contains("declining") {
            return "chart.line.downtrend.xyaxis"
        } else if pattern.contains("stable") {
            return "equal.square.fill"
        } else {
            return "sparkles"
        }
    }
}

#Preview {
    NavigationStack {
        InsightsDashboardView()
            .environmentObject(UserModel())
    }
} 