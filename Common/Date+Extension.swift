//
//  Date+Extension.swift
//  Bark
//
//  Created by huangfeng on 2020/5/26.
//  Copyright © 2020 Fin. All rights reserved.
//

import UIKit

extension Date {
    func formatString(format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(for: self) ?? ""
    }

    func agoFormatString() -> String {
        let clendar = NSCalendar(calendarIdentifier: .gregorian)
        let cps = clendar?.components([.hour, .minute, .second, .day, .month, .year], from: self, to: Date(), options: .wrapComponents)

        let year = cps!.year!
        let month = cps!.month!
        let day = cps!.day!
        let hour = cps!.hour!
        let minute = cps!.minute!

        if year > 0 || month > 0 || day > 0 || hour > 12 {
            return formatString(format: "yyyy-MM-dd HH:mm")
        }
        if hour > 1 {
            return formatString(format: "HH:mm")
        }
        if hour > 0 {
            if minute > 0 {
                return String(format: NSLocalizedString("timeMinHourAgo"), hour, minute)
            }
            return String(format: NSLocalizedString("timeHourAgo"), hour)
        }
        if minute > 1 {
            return String(format: NSLocalizedString("timeMinAgo"), minute)
        }
        return NSLocalizedString("timeJustNow")
    }
}

extension Date {
    var month: Int {
        return Calendar.current.component(.month, from: self)
    }

    var timeInterval: Int {
        return Int(timeIntervalSince1970)
    }
    
    var isLastDayOfMonth: Bool {
        return dayAfter.month != month
    }
}

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
