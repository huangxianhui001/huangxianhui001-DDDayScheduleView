//
//  DDDayScheduleBaseLineView.swift
//  DDDayScheduleView
//
//  Created by huangxianhui on 2020/8/16.
//

import Foundation
import SnapKit

/// 基尺view,包含1~24小时的文字和分割线,并包含一些从小时数转换为坐标的方法
internal class DDDayScheduleBaseLineView: UIView {
    // MARK: - public
    static var TimeLabelLeft: CGFloat {
        return 16
    }
    
    var editTimeData: DDScheduleTimeInfo? {
        didSet {
            updateTimeLabelStatus()
        }
    }
    
    // MARK: - private
    /// 小时数与label的映射字典
    private var timeLabelMap: [Int: UILabel] = [:]
    
    // MARK: - life cycle
    required init?(coder: NSCoder) {
        fatalError("no implement")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubViews()
    }
    
    private func setupSubViews() {
        for i in 0...DDDayScheduleView.HourAmoutOneDay {
            let lineView = UIView()
            lineView.backgroundColor = .lightGray
            self.addSubview(lineView)
            lineView.snp.makeConstraints { (maker) in
                maker.left.equalTo(DDDayScheduleView.ItemSuperViewEdgeInsets.left)
                maker.right.equalTo(-DDDayScheduleView.ItemSuperViewEdgeInsets.right)
                maker.height.equalTo(1)
                maker.top.equalTo(CGFloat(i) * DDDayScheduleView.OneHourHeight)
            }
            
            let label = UILabel()
            label.font = .systemFont(ofSize: 12)
            label.textColor = .gray
            label.text = String(format: "%02d:00", i)
            label.sizeToFit()
            self.addSubview(label)
            label.snp.makeConstraints { (maker) in
                maker.left.equalTo(DDDayScheduleBaseLineView.TimeLabelLeft)
                maker.centerY.equalTo(lineView.snp.centerY)
            }
            
            //添加进字典
            timeLabelMap[i] = label
        }
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return nil
    }
    
    ///当在编辑状态时,隐藏左边的小时label
    private func updateTimeLabelStatus() {
        resetTimeLabelStatus()
        if let timeData = self.editTimeData {
            //将开始时间分隔出整数部分和小数部分
            let beginTimeValue = DDDayScheduleView.separateFloat(timeData.begin)
            if beginTimeValue.decimalValue == 0 {
                let intHourValue = Int(beginTimeValue.integerValue)
                timeLabelMap[intHourValue]?.isHidden = true
            }
            //同理,分隔出结束时间的整数部分和小数部分
            let endTimeValue = DDDayScheduleView.separateFloat(timeData.end)
            if endTimeValue.decimalValue == 0 {
                let intHourValue = Int(endTimeValue.integerValue)
                timeLabelMap[intHourValue]?.isHidden = true
            }
        }
    }
    
    private func resetTimeLabelStatus() {
        for label in timeLabelMap.values {
            label.isHidden = false
        }
    }
}
