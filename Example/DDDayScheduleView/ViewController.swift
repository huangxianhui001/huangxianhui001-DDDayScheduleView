//
//  ViewController.swift
//  DDDayScheduleView
//
//  Created by 756673457@qq.com on 08/16/2020.
//  Copyright (c) 2020 756673457@qq.com. All rights reserved.
//

import UIKit
import DDDayScheduleView

class ViewController: UIViewController {
    @IBOutlet weak var dayScheduleView: DDDayScheduleView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        var models: [DDDayScheduleViewItemRepresentable] = []
        var previous: CGFloat = 0
        for i in 0...10 {
            let model = ScheduleModel()
            model.name = "计划 \(i)"
            model.timeInfo = DDScheduleTimeInfo(begin: previous, end: previous + 1)
            models.append(model)
            previous += 1
        }
        dayScheduleView.datasource = models
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

