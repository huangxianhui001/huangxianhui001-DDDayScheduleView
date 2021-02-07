//
//  DDDayScheduleViewProtocol.swift
//  DDDayScheduleView
//
//  Created by huangxianhui on 2020/8/16.
//

import Foundation

public protocol DDDayScheduleViewItemRepresentable {
    var id: Int { get }
    var name: String { get }
    var timeInfo: DDScheduleTimeInfo { get }
}

public protocol DDDayScheduleViewDelegate: AnyObject {
    ///点击某个日程
    func dayScheduleView(_ dayScheduleView: DDDayScheduleView, didSelectItem item: DDDayScheduleViewItemRepresentable)
    ///新建日程
    func dayScheduleView(_ dayScheduleView: DDDayScheduleView, createNewItemWith timeInfo: DDScheduleTimeInfo)
    ///编辑已有日程,timeInfo是编辑后的时间
    func dayScheduleView(_ dayScheduleView: DDDayScheduleView, editItem item: DDDayScheduleViewItemRepresentable, timeInfo: DDScheduleTimeInfo)
}

internal protocol DDDayScheduleItemViewActionProtocl {
    typealias TapAction = ((DDDayScheduleViewItemRepresentable) -> Void)
    ///itemView动作回调,目前仅支持点击事件
    var itemViewAction: TapAction? { get set }
}
