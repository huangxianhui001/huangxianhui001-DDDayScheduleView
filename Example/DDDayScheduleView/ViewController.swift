//
//  ViewController.swift
//  DDDayScheduleView
//
//  Created by 756673457@qq.com on 08/16/2020.
//  Copyright (c) 2020 756673457@qq.com. All rights reserved.
//

import UIKit
import DDDayScheduleView

class ViewController: UIViewController, DDDayScheduleViewDelegate {
    
    @IBOutlet weak var dayScheduleView: DDDayScheduleView!
    var datasource: [ScheduleModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        dayScheduleView.delegate = self
        /**
         用法:
         1.设置datasource属性,
         2.可设置delegate,监听不同事件
         3.可长按某个日程,进入日程编辑状态,手指触摸左上角附近位置,可编辑开始时间,触摸右下角位置可编辑结束时间,在编辑视图内,可修改整体开始结束时间
         3.1点击编辑位置外部,确认修改结果
         4.点击空白处,触发创建日程状态,同3一样,可修改开始和结束时间,或者整体时间
         4.1再次点击创建新的日程
         */
        var models: [ScheduleModel] = []
        var previous: CGFloat = 0
        for i in 1...5 {
            let model = ScheduleModel()
            model.id = i
            model.name = "计划 \(i)"
            model.timeInfo = DDScheduleTimeInfo(begin: previous, end: previous + 2)
            models.append(model)
            previous += 1
        }
        self.datasource = models
        dayScheduleView.datasource = models
    }
    
    func dayScheduleView(_ dayScheduleView: DDDayScheduleView, didSelectItem item: DDDayScheduleViewItemRepresentable) {
        print("点击某个日程\(item.name), 时间:\(item.timeInfo)")
    }
    
    func dayScheduleView(_ dayScheduleView: DDDayScheduleView, createNewItemWith timeInfo: DDScheduleTimeInfo) {
        let model = ScheduleModel()
        model.id = datasource.count + 1
        model.name = "新增计划 \(datasource.count)"
        model.timeInfo = timeInfo
        self.datasource.append(model)
        self.dayScheduleView.datasource = self.datasource
    }
    
    func dayScheduleView(_ dayScheduleView: DDDayScheduleView, editItem item: DDDayScheduleViewItemRepresentable, timeInfo: DDScheduleTimeInfo) {
        if let index = datasource.firstIndex(where: { $0.id == item.id }) {
            let model = datasource[index]
            model.timeInfo = timeInfo
            //重新赋值,会再次刷新
            self.dayScheduleView.datasource = self.datasource
        }
    }
    
}

