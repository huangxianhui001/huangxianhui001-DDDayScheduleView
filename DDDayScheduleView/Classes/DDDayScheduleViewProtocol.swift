//
//  DDDayScheduleViewProtocol.swift
//  DDDayScheduleView
//
//  Created by huangxianhui on 2020/8/16.
//

import Foundation

public protocol DDDayScheduleViewItemRepresentable {
    var name: String { get }
    var timeInfo: DDScheduleTimeInfo { get }
}

public protocol DDDayScheduleViewDelegate: AnyObject {
    func dayScheduleView(_ dayScheduleView: DDDayScheduleView, didSelectItemAt index: Int)
    func dayScheduleView(_ dayScheduleView: DDDayScheduleView, createNewItemWith timeInfo: DDScheduleTimeInfo)
    func dayScheduleView(_ dayScheduleView: DDDayScheduleView, editItem item: DDDayScheduleViewItemRepresentable)
}
