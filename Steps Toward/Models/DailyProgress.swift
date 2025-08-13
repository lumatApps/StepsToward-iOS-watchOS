import Foundation

/// Represents daily step progress.
struct DailyProgress: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let steps: Int
    
    /// Formatted date string.
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
