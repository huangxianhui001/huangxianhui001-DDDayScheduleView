//
//  DDDayScheduleView.swift
//  DDDayScheduleView
//
//  Created by huangxianhui on 2020/8/16.
//

import UIKit

/// 显示一天的日程安排视图,以时间轴格式,从每天的0点到第二天的0点,展示一天的日程安排
open class DDDayScheduleView: UIView {
    
    // MARK: - public
    public var datasource: [DDDayScheduleViewItemRepresentable] {
        get {
            return _datasource
        }
        set {
            _datasource = newValue.sorted(by: { (l, r) -> Bool in
                return l.timeInfo.begin < r.timeInfo.begin
            })
            layouted = false
            setNeedsLayout()
        }
    }
    
    public weak var delegate: DDDayScheduleViewDelegate?
    
    // MARK: - private
    private var _datasource: [DDDayScheduleViewItemRepresentable] = []
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.contentInset = DDDayScheduleView.ScrollViewContentInset
        //添加基尺view
        scrollView.addSubview(baselineView)
        baselineView.snp.makeConstraints { (maker) in
            maker.edges.equalTo(0)
            maker.width.equalToSuperview()
            maker.height.equalTo(DDDayScheduleView.ScrollContentViewHeight)
        }
        
        //添加计划view的父视图
        scrollView.addSubview(scheduleItemSuperView)
        scheduleItemSuperView.snp.makeConstraints { (maker) in
            maker.edges.equalTo(DDDayScheduleView.ItemSuperViewEdgeInsets)
        }
        
        //添加时间指示view,第一次添加会自动设置frame
        scrollView.addSubview(timeIndicatorView)
        timeIndicatorView.snp.makeConstraints { (maker) in
            maker.left.equalTo(DDDayScheduleBaseLineView.TimeLabelLeft)
            maker.right.equalTo(-DDDayScheduleView.ItemSuperViewEdgeInsets.right)
            maker.centerY.equalTo(0)
            maker.height.equalTo(20)
        }
        return scrollView
    }()

    private let baselineView = DDDayScheduleBaseLineView()
    ///当前时间指示器
    private let timeIndicatorView = DDDayScheduleTimeIndicatorView()
    ///所有日程Item的父视图
    private let scheduleItemSuperView = UIView()
    ///保存具体计划view的数组,用于添加计划之前清空之前的view
    private var scheduleViews: [DDDayScheduleItemView] = []
    
    ///已布局标志位
    private var layouted = false
    
    // MARK: - life cycle
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        addSubview(scrollView)
        scrollView.snp.updateConstraints { (make) in
            make.edges.equalTo(UIEdgeInsets.zero)
        }
//        bindViewEven()
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        if !layouted {
            layouted = true
            
        }
    }
}

internal extension DDDayScheduleView {
    static var ScrollViewContentInset: UIEdgeInsets {
        return UIEdgeInsets(top: 6, left: 0, bottom: 6, right: 0)
    }
    
    ///一小时间隔的高度
    static var OneHourHeight: CGFloat {
        return 44
    }
    
    /// 创建/编辑 事件允许的最小时间间隔是0.5小时
    static var MinPlanHourValue: CGFloat {
        return 0.5
    }
    
    /// 一天的小时数
    static var HourAmoutOneDay: Int {
        return 24
    }
    
    /// 计划itemsuperView到scrollview的间距
    static var ItemSuperViewEdgeInsets: UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 57, bottom: 0, right: 16)
    }
    
    /// 内容视图高度
    static var ScrollContentViewHeight: CGFloat {
        return DDDayScheduleView.OneHourHeight * 24
    }
    
    /// 计划ItemView的最大宽度
    var ItemViewMaxWidth: CGFloat {
        return self.bounds.width - DDDayScheduleView.ItemSuperViewEdgeInsets.horizontal
    }
}

// MARK: - layoutSubViews
private extension DDDayScheduleView {
    
    
}


// MARK: - 一些辅助计算方法
internal extension DDDayScheduleView {
    
    /// 根据纵坐标位置,算出当前的时间值,如果是11时30分,则返回(11, 0.5)
    /// - Parameter position: 触摸纵坐标
    /// - Returns: 时间值
    static func hourValueFrom(position: CGFloat) -> (hourValue: CGFloat, minuteFloatValue: CGFloat) {
        let hourValue = position / OneHourHeight //如果触摸在11.30的位置,这里的hourValue就是11.5
        //分离出小时数和分钟数,分钟数是小数部分
        let float = separateFloat(hourValue)
        return (hourValue: float.integerValue, minuteFloatValue: float.decimalValue)
    }
    
    /// 分离浮点数,返回整数部分和小数部分
    /// - Parameter floatValue: 被分离的浮点数
    /// - Returns: 包含整数部分和小数部分的
    static func separateFloat(_ floatValue: CGFloat) -> (integerValue: CGFloat, decimalValue: CGFloat) {
        let intValue = CGFloat(Int(floatValue))
        let decimalValue = floatValue - intValue
        return (intValue, decimalValue)
    }
    
    ///从触摸位置,计算合适放置的纵坐标
    func propositionalTopFromPosition(_ position: CGFloat) -> CGFloat {
        let value = propositionalHourValueFromPosition(position) * DDDayScheduleView.OneHourHeight
        return value
    }
    
    /// 根据触摸位置,计算合适的小时数值
    /// - Parameter position: 触摸位置
    /// - Returns: 小时数值
    func propositionalHourValueFromPosition(_ position: CGFloat) -> CGFloat {
        if position < 0 { return 0 }
        if position > 24 * DDDayScheduleView.OneHourHeight {
            return 24
        }
        
        //将触摸的位置,计算出是第几小时
        let hourMinuteValue = DDDayScheduleView.hourValueFrom(position: position)
        let hourValue = hourMinuteValue.hourValue
        let minuteValue = hourMinuteValue.minuteFloatValue
        
        let minuteHeight = minuteValue * DDDayScheduleView.OneHourHeight
        //创建计划或者移动计划以15分钟为步长
        let minuteStep = DDDayScheduleView.OneHourHeight / 4
        
        var index = 0
        var inCreateHourVallue: CGFloat = 0
        while inCreateHourVallue <= DDDayScheduleView.OneHourHeight {
            if minuteHeight < inCreateHourVallue {
                
                break
            }
            index += 1
            
            inCreateHourVallue += minuteStep
        }
        let propositionMinuteValue = CGFloat(index) / 4.0
        let propositionHourValue = hourValue + propositionMinuteValue
        return propositionHourValue
    }
}

