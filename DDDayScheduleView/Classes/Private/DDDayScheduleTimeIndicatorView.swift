//
//  DDDayScheduleTimeIndicatorView.swift
//  DDDayScheduleView
//
//  Created by huangxianhui on 2020/8/16.
//

import Foundation

///显示当前时间和红点红线的View
internal class DDDayScheduleTimeIndicatorView: UIView {
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        return label
    }()

    private let circleView: UIView = UIView()
    
    private let lineView: UIView = UIView()
    
    override var tintColor: UIColor! {
        didSet {
            timeLabel.textColor = tintColor
            lineView.backgroundColor = tintColor
            circleView.backgroundColor = tintColor
        }
    }
    
    // MARK: - life cycle
    required init?(coder: NSCoder) {
        fatalError("no implement")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(timeLabel)
        addSubview(circleView)
        addSubview(lineView)
       
        tintColor = .systemRed
        
        timeLabel.snp.makeConstraints { (make) in
            make.left.equalTo(0)
            make.centerY.equalTo(self.snp.centerY)
        }
        circleView.snp.makeConstraints { (make) in
            make.left.equalTo(timeLabel.snp.right).offset(2)
            make.size.equalTo(CGSize(width: 5, height: 5))
            make.centerY.equalTo(self.snp.centerY)
        }
        circleView.layer.cornerRadius = 2.5
        
        lineView.snp.makeConstraints { (make) in
            make.left.equalTo(circleView.snp.right)
            make.right.equalTo(0)
            make.height.equalTo(1)
            make.centerY.equalTo(self.snp.centerY)
        }
    }
    
    override func layoutSubviews() {
        superview?.layoutSubviews()
        updateTime()
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return nil
    }
}

// MARK: - public func
extension DDDayScheduleTimeIndicatorView {
    
    public func updateTime() {
        let now = Date.Today
        let string = now.stringWith(dateFormat: "HH:mm")
        timeLabel.text = string
        let hourValue = now.hourValue
        if self.superview != nil {
            let y = hourValue * DDDayScheduleView.OneHourHeight
            self.snp.updateConstraints { (maker) in
                maker.centerY.equalTo(y)
            }
        }
    }
}
