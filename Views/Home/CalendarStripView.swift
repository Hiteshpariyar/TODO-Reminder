// CalendarStripView.swift
// Horizontal strip showing 7 days centered on the selected date

import SwiftUI

struct CalendarStripView: View {
    @Binding var selectedDate: Date
    private let daysToShow = 7
    
    var body: some View {
        let dates = generateDates(around: selectedDate, count: daysToShow)
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(dates, id: \ .self) { date in
                    DayCell(date: date, isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate))
                        .onTapGesture { selectedDate = date }
                }
            }
            .padding(.horizontal, 12)
        }
    }
    
    // Generate a range of dates centered on a given date
    private func generateDates(around date: Date, count: Int) -> [Date] {
        var result: [Date] = []
        let half = count / 2
        for i in -half...half {
            if let newDate = Calendar.current.date(byAdding: .day, value: i, to: date) {
                result.append(newDate)
            }
        }
        return result
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    var body: some View {
        VStack(spacing: 4) {
            Text(date, format: Date.FormatStyle().day(.defaultDigits))
                .font(.title3.bold().rounded())
                .foregroundColor(isSelected ? .white : .white.opacity(0.7))
            Text(date, format: Date.FormatStyle().weekday(.abbreviated))
                .font(.caption.bold())
                .foregroundColor(isSelected ? .white : .white.opacity(0.5))
        }
        .frame(width: 44, height: 64)
        .background(
            ZStack {
                if isSelected {
                    AngularGradient(colors: [Color("PrimaryStart"), Color("PrimaryEnd")], center: .center)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                } else {
                    Color.black.opacity(0.2)
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(isSelected ? Color.white.opacity(0.5) : Color.clear, lineWidth: 2)
        )
    }
}

struct CalendarStripView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarStripView(selectedDate: .constant(Date()))
    }
}

