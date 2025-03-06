//
//  DateFormatter+Extensions.swift
//  iconink
//
//  Created by Garot Conklin on 2/27/25.
//

import Foundation

extension DateFormatter {
    
    /// Standard date formatter for displaying dates (e.g., Feb 27, 2025)
    static let standardDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    /// Date formatter with time (e.g., Feb 27, 2025 at 3:30 PM)
    static let standardDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    /// Short date formatter (e.g., 2/27/25)
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    /// ISO date formatter for storing dates (e.g., 2025-02-27T15:30:00Z)
    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
    
    /// Year-only formatter (e.g., 2025)
    static let yearOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter
    }()
    
    /// Month and year formatter (e.g., February 2025)
    static let monthAndYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    /// Day and month formatter (e.g., 27 Feb)
    static let dayAndMonth: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter
    }()
    
    /// Time only formatter (e.g., 3:30 PM)
    static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    /// Relative date formatter (e.g., Today, Yesterday, etc.)
    static let relative: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter
    }()
}

extension Date {
    
    /// Returns the age in years from the date
    var age: Int {
        return Calendar.current.dateComponents([.year], from: self, to: Date()).year ?? 0
    }
    
    /// Returns true if the date is today
    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    /// Returns true if the date is yesterday
    var isYesterday: Bool {
        return Calendar.current.isDateInYesterday(self)
    }
    
    /// Returns true if the date is in the future
    var isFuture: Bool {
        return self > Date()
    }
    
    /// Returns true if the date is in the past
    var isPast: Bool {
        return self < Date()
    }
    
    /// Returns a formatted string representation of the date
    func formatted(style: DateFormatStyle = .standard) -> String {
        switch style {
        case .standard:
            return DateFormatter.standardDate.string(from: self)
        case .standardWithTime:
            return DateFormatter.standardDateTime.string(from: self)
        case .short:
            return DateFormatter.shortDate.string(from: self)
        case .iso8601:
            return DateFormatter.iso8601.string(from: self)
        case .yearOnly:
            return DateFormatter.yearOnly.string(from: self)
        case .monthAndYear:
            return DateFormatter.monthAndYear.string(from: self)
        case .dayAndMonth:
            return DateFormatter.dayAndMonth.string(from: self)
        case .timeOnly:
            return DateFormatter.timeOnly.string(from: self)
        case .relative:
            return DateFormatter.relative.localizedString(for: self, relativeTo: Date())
        }
    }
    
    /// Returns a date with the time set to the start of the day
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    /// Returns a date with the time set to the end of the day
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }
    
    /// Returns a date with the specified number of days added
    func addingDays(_ days: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
    
    /// Returns a date with the specified number of months added
    func addingMonths(_ months: Int) -> Date {
        return Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }
    
    /// Returns a date with the specified number of years added
    func addingYears(_ years: Int) -> Date {
        return Calendar.current.date(byAdding: .year, value: years, to: self) ?? self
    }
}

/// Date format styles for the formatted method
enum DateFormatStyle {
    case standard           // Feb 27, 2025
    case standardWithTime   // Feb 27, 2025 at 3:30 PM
    case short              // 2/27/25
    case iso8601            // 2025-02-27T15:30:00Z
    case yearOnly           // 2025
    case monthAndYear       // February 2025
    case dayAndMonth        // 27 Feb
    case timeOnly           // 3:30 PM
    case relative           // Today, Yesterday, etc.
} 
