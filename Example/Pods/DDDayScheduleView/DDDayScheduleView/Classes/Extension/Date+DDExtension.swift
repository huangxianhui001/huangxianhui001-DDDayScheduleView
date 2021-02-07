//
//  Date+Ex.swift
//  DDDayScheduleView
//
//  Created by huangxianhui on 2020/8/16.
//

import Foundation

internal extension Calendar {
    static let `default`: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale.current
        calendar.timeZone = TimeZone.current
        return calendar
    }()
}

internal extension DateFormatter {
    static let `default`: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.timeZone = TimeZone.current
        ///使用阳历日历
        dateFormatter.calendar = Calendar.default
        return dateFormatter
    }()
    
    static func formatterWithdDteFormat(_ string: String) -> DateFormatter {
        DateFormatter.default.dateFormat = string
        return DateFormatter.default
    }
}

internal extension Date {
    static var Today: Date {
        return Date()
    }
    
    func stringWith(dateFormat: String) -> String {
        let dateFormatter: DateFormatter = .formatterWithdDteFormat(dateFormat)
        return dateFormatter.string(from: self)
    }
    
    /// 返回当前时间在一天中的小时数值
    var hourValue: CGFloat {
        let string = self.stringWith(dateFormat: "HH:mm")
        let array = string.split(separator: ":")
        guard array.count == 2 else {
            return 0
        }
        
        let minute = (Double(String(array.last!)) ?? 0) / 60.0
        let hour = Double(String(array.first!)) ?? 0
        return CGFloat(hour + minute)
    }
    
}
