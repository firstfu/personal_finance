//
//  TimePeriodState.swift
//  personal_finance
//
//  Created by firstfu on 2026/2/17.
//

import Foundation

enum PeriodType: String, CaseIterable, Identifiable {
    case week = "週"
    case month = "月"
    case year = "年"
    case custom = "自訂"

    var id: String { rawValue }
}

struct TimePeriodState {
    var periodType: PeriodType
    var offset: Int = 0
    var customStart: Date = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: .now))!
    var customEnd: Date = .now

    init(periodType: PeriodType = .month) {
        self.periodType = periodType
    }

    var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date.now

        switch periodType {
        case .week:
            let currentWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let start = calendar.date(byAdding: .weekOfYear, value: offset, to: currentWeekStart)!
            let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start)!
            return (start, end)
        case .month:
            let currentMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let start = calendar.date(byAdding: .month, value: offset, to: currentMonthStart)!
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            return (start, end)
        case .year:
            let currentYearStart = calendar.date(from: calendar.dateComponents([.year], from: now))!
            let start = calendar.date(byAdding: .year, value: offset, to: currentYearStart)!
            let end = calendar.date(byAdding: .year, value: 1, to: start)!
            return (start, end)
        case .custom:
            let start = calendar.startOfDay(for: customStart)
            let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: customEnd))!
            return (start, end)
        }
    }

    var periodLabel: String {
        let calendar = Calendar.current
        let range = dateRange
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh-TW")

        switch periodType {
        case .week:
            formatter.dateFormat = "M/d"
            let startStr = formatter.string(from: range.start)
            let endDate = calendar.date(byAdding: .day, value: -1, to: range.end)!
            let endStr = formatter.string(from: endDate)
            return "\(startStr) - \(endStr)"
        case .month:
            let comps = calendar.dateComponents([.year, .month], from: range.start)
            return "\(comps.year!)年\(comps.month!)月"
        case .year:
            let comps = calendar.dateComponents([.year], from: range.start)
            return "\(comps.year!)年"
        case .custom:
            formatter.dateFormat = "yyyy/M/d"
            return "\(formatter.string(from: customStart)) - \(formatter.string(from: customEnd))"
        }
    }

    var isCurrentPeriod: Bool {
        offset >= 0
    }

    mutating func goBack() {
        guard periodType != .custom else { return }
        offset -= 1
    }

    mutating func goForward() {
        guard periodType != .custom, !isCurrentPeriod else { return }
        offset += 1
    }

    mutating func setPeriodType(_ type: PeriodType) {
        periodType = type
        offset = 0
    }
}
