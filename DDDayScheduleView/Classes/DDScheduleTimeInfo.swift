//
//  DDScheduleTimeInfo.swift
//  DDDayScheduleView
//
//  Created by huangxianhui on 2020/8/16.
//

import Foundation

/// 一个日程所需要的时间信息,需包含该日程在一天当中的开始时间和结束时间
/// 一天24小时,就以0到24之间的浮点数来表示具体某个时间,浮点数的小数部分,为不足一小时的分钟部分占一小时的几分之几
/// 如半小时就为0.5; 45分钟就为0.75
public struct DDScheduleTimeInfo: Equatable, CustomDebugStringConvertible {
    public var debugDescription: String {
        let beginTime = DDScheduleTimeInfo.separateTime(begin)
        let endTime = DDScheduleTimeInfo.separateTime(end)
        return "\n开始:\(beginTime.hourValue):\(beginTime.minuteValue)\n结束:\(endTime.hourValue):\(endTime.minuteValue)"
    }
    
    public static var zero: DDScheduleTimeInfo {
        return DDScheduleTimeInfo(begin: 0, end: 0)
    }
   
    /// 开始时间,为0~24之间的浮点数
    public var begin: CGFloat
    /// 结束时间,为0~24之间的浮点数
    public var end: CGFloat
    
    public init(begin: CGFloat, end: CGFloat) {
        self.begin = begin
        self.end = end
    }
    
    /// 日程的时长
    public var length: CGFloat {
        return end - begin
    }
    
    /// 检查起止时间是否有效
    public var availability: Bool {
        return begin >= 0 && end <= 24
    }
    
    /// 判断是否包含其他时间,只要其他时间的起点时间在当前时间段内,即返回true
    /// - Returns: true,包含,false,不包含
    public func contains(otherTimeData: DDScheduleTimeInfo) -> Bool {
        return otherTimeData.begin >= begin && otherTimeData.begin <= end
    }
    
    /// 分割时间时间值,范围小时数值和分钟数值
    /// - Parameter timeValue: 时间值,如果是11:30分,则为11.5
    /// - Returns: 返回时间值的小时部分和分钟部分,如timeValue为11.5,则返回(11,30)
    public static func separateTime(_ timeValue: CGFloat) -> (hourValue: Int, minuteValue: Int) {
        let hourValue = CGFloat(Int(timeValue))
        let minuteValue = (timeValue - hourValue) * 60
        return (Int(timeValue), Int(minuteValue))
    }
}

internal extension CGFloat {
    
    /// 由时间值,转换为纵坐标
    var verticalPosition: CGFloat {
        return DDDayScheduleView.OneHourHeight * self
    }
}
