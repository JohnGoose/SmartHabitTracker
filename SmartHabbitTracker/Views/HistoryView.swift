import SwiftUI
import CoreData
import Charts

struct HistoryView: View {
  @Environment(\.managedObjectContext) private var viewContext
  @FetchRequest(
    entity: CompletionEntity.entity(),
    sortDescriptors: [NSSortDescriptor(keyPath: \CompletionEntity.date, ascending: true)]
  ) private var completions: FetchedResults<CompletionEntity>

  private let calendar = Calendar.current

  var body: some View {
    VStack(spacing: 16) {
      Text("Last 7 Days")
        .font(.title2).bold()

      chartCard
        .frame(height: 180)           // ← fixed height
        .padding(.horizontal, 16)

      Spacer()
    }
    .padding(.top)
  }

  // MARK: - Chart in a card
  private var chartCard: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 12)
        .fill(Color(.secondarySystemBackground))
        .shadow(radius: 4)

      Chart {
        ForEach(weekData) { day in
          BarMark(
            x: .value("Day", day.date, unit: .day),
            y: .value("Completion %", day.percent * 100)
          )
          .foregroundStyle(Color.blue.gradient)
          .cornerRadius(4)
        }
      }
      // clamp exactly 0–100%
      .chartYScale(domain: 0...100)
      // show only each day, no extras
      .chartXAxis {
        AxisMarks(values: weekData.map { $0.date }) { _ in
          AxisGridLine()
          AxisValueLabel(format: .dateTime.day(.defaultDigits))
        }
      }
      // show 0, 50, 100 on the leading edge
      .chartYAxis {
        AxisMarks(position: .leading, values: [0,50,100]) { value in
          AxisGridLine()
          AxisValueLabel("\(Int(value.as(Double.self) ?? 0))%")
        }
      }
      .padding(8)
    }
  }

  // Build data for the past 7 days
  private var weekData: [DayCompletion] {
    let today = calendar.startOfDay(for: Date())
    let days  = (0...6).map {
      calendar.date(byAdding: .day, value: -$0, to: today)!
    }.reversed()

    return days.map { date in
      let start = date
      let end   = calendar.date(byAdding: .day, value: 1, to: start)!
      let count = completions.filter { $0.date >= start && $0.date < end }.count
      return DayCompletion(date: date, percent: Double(count) / 3.0)
    }
  }
}

struct DayCompletion: Identifiable {
  let date: Date
  let percent: Double   // 0.0 … 1.0
  var id: Date { date }
}
