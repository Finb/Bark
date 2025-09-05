//
//  MessageDeleteTimeRange.swift
//  Bark
//
//  Created by huangfeng on 1/7/25.
//  Copyright © 2025 Fin. All rights reserved.
//

import Foundation

enum MessageDeleteTimeRange {
    /// 最近一小时
    case lastHour
    /// 今天
    case today
    /// 今天和昨天
    case todayAndYesterday
    /// 最近一个月
    case lastMonth
    /// 全部时间
    case allTime
    
    /// 一小时之前
    case beforeOneHour
    /// 一天之前
    case beforeToday
    /// 昨天之前
    case beforeYesterday
    /// 一月之前
    case beforeOneMonth
     
    var string: String {
        switch self {
        case .lastHour:
            return "lastHour".localized
        case .today:
            return "today".localized
        case .todayAndYesterday:
            return "todayAndYesterday".localized
        case .lastMonth:
            return "lastMonth".localized
        case .allTime:
            return "allTime".localized
        case .beforeOneHour:
            return "beforeAnHour".localized
        case .beforeToday:
            return "beforeToday".localized
        case .beforeYesterday:
            return "beforeYesterday".localized
        case .beforeOneMonth:
            return "beforeAMonth".localized
        }
    }
    
    var startDate: Date {
        switch self {
        case .lastHour:
            return Date.lastHour
        case .today:
            return Date().startOfDay
        case .todayAndYesterday:
            return Date.yesterday
        case .lastMonth:
            return Date.lastMonth
        case .allTime,
             .beforeOneHour,
             .beforeToday,
             .beforeYesterday,
             .beforeOneMonth:
            return Date(timeIntervalSince1970: 0)
        }
    }

    var endDate: Date {
        switch self {
        case .lastHour,
             .today,
             .todayAndYesterday,
             .lastMonth,
             .allTime:
            return Date()
        case .beforeOneHour:
            return Date.lastHour
        case .beforeToday:
            return Date().startOfDay
        case .beforeYesterday:
            return Date.yesterday
        case .beforeOneMonth:
            return Date.lastMonth
        }
    }
}
