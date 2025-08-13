import SwiftUI

struct RecentProgressView: View {
    let progress: [DailyProgress]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Progress")
                .font(.headline)
            
            VStack(spacing: 12) {
                ForEach(progress.suffix(7).reversed(), id: \.id) { dayProgress in
                    DailyProgressRow(progress: dayProgress)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct DailyProgressRow: View {
    let progress: DailyProgress
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(progress.date)
    }
    
    private var dayOfWeek: String {
        if isToday {
            return "Today"
        } else if Calendar.current.isDateInYesterday(progress.date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: progress.date)
        }
    }
    
    private var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: progress.date)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(dayOfWeek)
                    .font(.subheadline)
                    .fontWeight(isToday ? .semibold : .regular)
                    .foregroundStyle(isToday ? Color.accent : .primary)
                    
                
                Text(shortDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(progress.steps.formatted())")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("steps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            RoundedRectangle(cornerRadius: 4)
                .fill(stepColor(for: progress.steps))
                .frame(width: 4, height: 30)
        }
        .padding(.vertical, 4)
    }
    
    private func stepColor(for steps: Int) -> Color {
        switch steps {
        case 10000...: return .green
        case 7500..<10000: return Color.accent
        case 5000..<7500: return .orange
        default: return .gray
        }
    }
}

#Preview {
    let sampleProgress = [
        DailyProgress(date: Calendar.current.date(byAdding: .day, value: -6, to: Date())!, steps: 8542),
        DailyProgress(date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, steps: 12043),
        DailyProgress(date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!, steps: 6789),
        DailyProgress(date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, steps: 9876),
        DailyProgress(date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, steps: 15234),
        DailyProgress(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, steps: 7432),
        DailyProgress(date: Date(), steps: 4567)
    ]
    
    RecentProgressView(progress: sampleProgress)
        .padding()
}
