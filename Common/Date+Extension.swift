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
                return "timeMinHourAgo".localized(with: hour, minute)
            }
            return "timeHourAgo".localized(with: hour)
        }
        if minute > 1 {
            return "timeMinAgo".localized(with: minute)
        }
        return "timeJustNow".localized
    }

    var expiryTimeSinceNow: String {
        let timeInterval = timeIntervalSinceNow

        if timeInterval > 60 * 60 * 24 * 365 {
            return "expiryTimeYear".localized(with: Int(timeInterval / (60 * 60 * 24 * 365)))
        }
        if timeInterval > 60 * 60 * 24 * 30 {
            return "expiryTimeMonth".localized(with: Int(timeInterval / (60 * 60 * 24 * 30)))
        }
        if timeInterval > 60 * 60 * 24 {
            return "expiryTimeDay".localized(with: Int(timeInterval / (60 * 60 * 24)))
        }
        if timeInterval > 60 * 60 {
            return "expiryTimeHour".localized(with: Int(timeInterval / (60 * 60)))
        }
        if timeInterval > 60 {
            return "expiryTimeMinute".localized(with: Int(timeInterval / 60))
        }
        if timeInterval > 0 {
            return "expiryTimeSecond".localized(with: Int(timeInterval))
        }
        return "expired".localized
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
