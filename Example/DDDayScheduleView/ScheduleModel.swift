//
//  ScheduleModel.swift
//  DDDayScheduleView_Example
//
//  Created by huangxianhui on 2020/8/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import DDDayScheduleView

class ScheduleModel: DDDayScheduleViewItemRepresentable {
    var id: Int = 0
    var name: String = ""
    var timeInfo: DDScheduleTimeInfo = .zero
}
