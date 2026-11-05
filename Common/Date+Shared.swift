//
//  Date+Shared.swift
//  Bark
//

import Foundation

extension Date {
    static var yesterday: Date { return Date().dayBefore }
    static var tomorrow: Date { return Date().dayAfter }
    static var lastHour: Date { return Calendar.current.date(byAdding: .hour, value: -1, to: Date())! }
    static var lastMonth: Date { return Calendar.current.date(byAdding: .month, value: -1, to: Date())! }

    var dayBefore: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: startOfDay)!
    }

    var dayAfter: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
    }

    var startOfDay: Date {
        return Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: self)!
    }

    var endOfDay: Date {
        return Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: self)!
    }
}
