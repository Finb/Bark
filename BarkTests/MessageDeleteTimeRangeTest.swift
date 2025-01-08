//
//  MessageDeleteTimeRangeTest.swift
//  BarkTests
//
//  Created by huangfeng on 1/8/25.
//  Copyright © 2025 Fin. All rights reserved.
//
@testable import Bark
import Testing

struct MessageDeleteTimeRangeTest {
    @Test("检查时间范围区间是否正确", arguments: [
        MessageDeleteTimeRange.lastHour,
        MessageDeleteTimeRange.today,
        MessageDeleteTimeRange.todayAndYesterday,
        MessageDeleteTimeRange.lastMonth,
        MessageDeleteTimeRange.allTime,
        MessageDeleteTimeRange.beforeOneHour,
        MessageDeleteTimeRange.beforeToday,
        MessageDeleteTimeRange.beforeYesterday,
        MessageDeleteTimeRange.beforeOneMonth
    ])
    func testRange(range: MessageDeleteTimeRange) async throws {
        let now = Date()
        let lastHour = Calendar.current.date(byAdding: .hour, value: -1, to: now)!
        let today = now.startOfDay
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!.startOfDay
        let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: now)!
        
        switch range {
        case .lastHour:
            let startDate = range.startDate
            let endDate = range.endDate
            #expect(startDate.timeInterval == lastHour.timeInterval && endDate.timeInterval == now.timeInterval)
        case .today:
            let startDate = range.startDate
            let endDate = range.endDate
            #expect(startDate.timeInterval == today.timeInterval && endDate.timeInterval == now.timeInterval)
        case .todayAndYesterday:
            let startDate = range.startDate
            let endDate = range.endDate
            #expect(startDate.timeInterval == yesterday.timeInterval && endDate.timeInterval == now.timeInterval)
        case .lastMonth:
            let startDate = range.startDate
            let endDate = range.endDate
            #expect(startDate.timeInterval == lastMonth.timeInterval && endDate.timeInterval == now.timeInterval)
        case .allTime:
            let startDate = range.startDate
            let endDate = range.endDate
            #expect(startDate.timeInterval == 0 && endDate.timeInterval == now.timeInterval)
        case .beforeOneHour:
            let startDate = range.startDate
            let endDate = range.endDate
            #expect(startDate.timeInterval == 0 && endDate.timeInterval == lastHour.timeInterval)
        case .beforeToday:
            let startDate = range.startDate
            let endDate = range.endDate
            #expect(startDate.timeInterval == 0 && endDate.timeInterval == today.timeInterval)
        case .beforeYesterday:
            let startDate = range.startDate
            let endDate = range.endDate
            #expect(startDate.timeInterval == 0 && endDate.timeInterval == yesterday.timeInterval)
        case .beforeOneMonth:
            let startDate = range.startDate
            let endDate = range.endDate
            #expect(startDate.timeInterval == 0 && endDate.timeInterval == lastMonth.timeInterval)
        }
    }
}
