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
    
    var expiryTimeSinceNow: String {
        let timeInterval = self.timeIntervalSinceNow
        if timeInterval > 60 * 60 * 24 * 365 {
            return String(format: NSLocalizedString("expiryTimeYear"), Int(timeInterval / (60 * 60 * 24 * 365)))
        } else if timeInterval > 60 * 60 * 24 * 30 {
            return String(format: NSLocalizedString("expiryTimeMonth"), Int(timeInterval / (60 * 60 * 24 * 30)))
        } else if timeInterval > 60 * 60 * 24 {
            return String(format: NSLocalizedString("expiryTimeDay"), Int(timeInterval / (60 * 60 * 24)))
        } else if timeInterval > 60 * 60 {
            return String(format: NSLocalizedString("expiryTimeHour"), Int(timeInterval / (60 * 60)))
        } else if timeInterval > 60 {
            return String(format: NSLocalizedString("expiryTimeMinute"), Int(timeInterval / 60))
        } else if timeInterval > 0 {
            return String(format: NSLocalizedString("expiryTimeSecond"), Int(timeInterval))
        } else {
            return NSLocalizedString("expired")
        }
    }
}

extension Date {
    static var yesterday: Date { return Date().dayBefore }
    static var tomorrow: Date { return Date().dayAfter }
    static var lastHour: Date { return Calendar.current.date(byAdding: .hour, value: -1, to: Date())! }
    var dayBefore: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: noon)!
    }

    var dayAfter: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: noon)!
    }

    var noon: Date {
        return Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: self)!
    }

    var month: Int {
        return Calendar.current.component(.month, from: self)
    }

    var isLastDayOfMonth: Bool {
        return dayAfter.month != month
    }
}
