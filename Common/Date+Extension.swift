//
//  Date+Extension.swift
//  Bark
//
//  Created by huangfeng on 2020/5/26.
//  Copyright © 2020 Fin. All rights reserved.
//

import UIKit

extension Date {
    func formatString(format:String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(for: self) ?? ""
    }
    
    func agoFormatString() -> String {
        
        let clendar = NSCalendar(calendarIdentifier: .gregorian)
        let cps = clendar?.components([ .hour, .minute, .second, .day, .month, .year], from: self, to: Date(), options: .wrapComponents)
        
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
            return "\(hour)小时" + (minute > 0 ? "\(minute)分钟" : "") + "前"
        }
        if minute > 1 {
            return "\(minute)分钟前"
        }
        return "刚刚"
    }
}
