//
//  AnniversaryCalendar.swift
//  Hongyeon
//

import SwiftUI

// A month grid in the app's own style (Apple's graphical DatePicker can only change its tint).
// Past days only. Nothing is selected until a day is tapped; the chosen day gets a thin red circle.
struct AnniversaryCalendar: View {
    @Binding var selection: Date?
    @State private var displayedMonth: Date // the first day of the month on screen

    // Gregorian in the phone's time zone, matching anniversaryFormatter, so a tapped day
    // turns into exactly that "yyyy-MM-dd".
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = .current
        return calendar
    }()

    init(selection: Binding<Date?>) {
        _selection = selection
        _displayedMonth = State(initialValue: Self.monthStart(of: selection.wrappedValue ?? Date()))
    }

    private static func monthStart(of date: Date) -> Date {
        let calendar = Calendar(identifier: .gregorian)
        return calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
    }

    private var today: Date { calendar.startOfDay(for: Date()) }
    private var currentMonth: Date { Self.monthStart(of: Date()) }
    private var shownYear: Int { calendar.component(.year, from: displayedMonth) }
    private var shownMonth: Int { calendar.component(.month, from: displayedMonth) }

    var body: some View {
        VStack(spacing: 12) {
            header
            weekdayRow
            dayGrid
        }
    }

    private var header: some View {
        HStack {
            arrowButton("chevron.left", label: "Previous month", months: -1)
                .disabled(shownYear <= 1900 && shownMonth == 1)

            Spacer()

            Menu {
                Picker("Month", selection: monthBinding) {
                    ForEach(selectableMonths, id: \.self) { month in
                        Text(calendar.standaloneMonthSymbols[month - 1]).tag(month)
                    }
                }
            } label: {
                dropdownLabel(calendar.standaloneMonthSymbols[shownMonth - 1])
            }

            Menu {
                Picker("Year", selection: yearBinding) {
                    ForEach((1900...calendar.component(.year, from: today)).reversed(), id: \.self) { year in
                        Text(String(year)).tag(year) // String(), or SwiftUI prints "2,026"
                    }
                }
            } label: {
                dropdownLabel(String(shownYear))
            }

            Spacer()

            arrowButton("chevron.right", label: "Next month", months: 1)
                .disabled(displayedMonth >= currentMonth)
        }
        .tint(Theme.textPrimary)
    }

    private var weekdayRow: some View {
        // Rotated so the row starts on the region's first weekday (Sunday in Korea and the US).
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        let ordered = Array(symbols[first...] + symbols[..<first])

        return HStack(spacing: 0) {
            ForEach(ordered.indices, id: \.self) { index in
                Text(ordered[index])
                    .frame(maxWidth: .infinity)
            }
        }
        .font(Theme.captionFont)
        .foregroundColor(Theme.textSecondary)
        .accessibilityHidden(true)
    }

    private var dayGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
            ForEach(dayCells.indices, id: \.self) { index in
                if let day = dayCells[index] {
                    dayButton(day)
                } else {
                    Color.clear.frame(height: 40)
                }
            }
        }
    }

    // Blank cells before day 1 line it up under the right weekday.
    private var dayCells: [Date?] {
        let weekdayOfFirst = calendar.component(.weekday, from: displayedMonth)
        let blanks = (weekdayOfFirst - calendar.firstWeekday + 7) % 7
        let dayCount = calendar.range(of: .day, in: .month, for: displayedMonth)!.count
        let days = (0..<dayCount).map { calendar.date(byAdding: .day, value: $0, to: displayedMonth) }
        return Array(repeating: nil, count: blanks) + days
    }

    private func dayButton(_ day: Date) -> some View {
        let isFuture = day > today
        let isSelected = selection.map { calendar.isDate($0, inSameDayAs: day) } ?? false

        return Button {
            selection = day
        } label: {
            Text(String(calendar.component(.day, from: day)))
                .font(isSelected ? Theme.bodyFont.weight(.semibold) : Theme.bodyFont)
                .foregroundColor(isSelected ? Theme.accent : isFuture ? Theme.textPrimary.opacity(0.35) : Theme.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background {
                    if isSelected {
                        Circle()
                            .stroke(Theme.accent, lineWidth: 1.5)
                            .frame(width: 38, height: 38)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
        .accessibilityLabel(day.formatted(date: .long, time: .omitted))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func arrowButton(_ systemName: String, label: String, months: Int) -> some View {
        Button {
            displayedMonth = calendar.date(byAdding: .month, value: months, to: displayedMonth)!
        } label: {
            Image(systemName: systemName)
                .font(.body.weight(.medium))
                .frame(width: 44, height: 44)
        }
        .accessibilityLabel(label)
    }

    private func dropdownLabel(_ text: String) -> some View {
        HStack(spacing: 6) {
            Text(text)
            Image(systemName: "chevron.down")
                .font(.caption.weight(.semibold))
        }
        .font(Theme.bodyFont)
        .foregroundColor(Theme.textPrimary)
    }

    // This year only offers the months up to now.
    private var selectableMonths: [Int] {
        let isThisYear = shownYear == calendar.component(.year, from: today)
        return Array(1...(isThisYear ? calendar.component(.month, from: today) : 12))
    }

    private var monthBinding: Binding<Int> {
        Binding(get: { shownMonth }, set: { show(year: shownYear, month: $0) })
    }

    private var yearBinding: Binding<Int> {
        Binding(get: { shownYear }, set: { show(year: $0, month: shownMonth) })
    }

    // Picking this year while a later month is shown lands on the current month instead.
    private func show(year: Int, month: Int) {
        let picked = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
        displayedMonth = min(picked, currentMonth)
    }
}

#Preview {
    @Previewable @State var selection: Date?
    AnniversaryCalendar(selection: $selection)
        .padding()
        .background(Theme.cardBackground)
}
