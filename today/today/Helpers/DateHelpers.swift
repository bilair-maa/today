//
//  DateHelpers.swift
//  today
//

import Foundation

// Shifts the current time back by dayStartHour so that e.g. 2am still counts
// as "yesterday" if the user's day starts at 4am.
func adjustedDate(dayStartHour: Int) -> Date {
    Date().addingTimeInterval(-Double(dayStartHour) * 3600)
}

// Returns today's date as a string, adjusted for the user's day start hour
func todaysDateString(dayStartHour: Int = 0) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.calendar = Calendar.current
    return formatter.string(from: adjustedDate(dayStartHour: dayStartHour))
}

// The exact moment the user's "day" begins
func dayStartDate(dayStartHour: Int) -> Date {
    let calendar = Calendar.current
    let adjusted = adjustedDate(dayStartHour: dayStartHour)
    let startOfAdjusted = calendar.startOfDay(for: adjusted)
    return startOfAdjusted.addingTimeInterval(Double(dayStartHour) * 3600)
}

// 24 hours after the day start
func dayEndDate(dayStartHour: Int) -> Date {
    dayStartDate(dayStartHour: dayStartHour).addingTimeInterval(24 * 3600)
}

// Finds a valid future time within the user's day window.
// Checks today first, then tomorrow, to handle times crossing midnight.
func resolveTimeInDay(hour: Int, minute: Int, dayStartHour: Int) -> Date? {
    let calendar = Calendar.current
    let start = dayStartDate(dayStartHour: dayStartHour)
    let end = dayEndDate(dayStartHour: dayStartHour)

    let today = Date()
    var components = calendar.dateComponents([.year, .month, .day], from: today)
    components.hour = hour
    components.minute = minute
    components.second = 0

    guard let candidate = calendar.date(from: components) else { return nil }

    if candidate >= start && candidate <= end && candidate > today {
        return candidate
    }

    let tomorrow = candidate.addingTimeInterval(24 * 3600)
    if tomorrow >= start && tomorrow <= end && tomorrow > today {
        return tomorrow
    }

    return nil
}
