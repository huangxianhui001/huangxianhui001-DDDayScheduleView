//
//  DDDayScheduleView.swift
//  DDDayScheduleView
//
//  Created by huangxianhui on 2020/8/16.
//

import UIKit

/// 是否是 iPhone X 系列手机
private let IS_IPHONE_XSERIES = UIApplication.shared.statusBarFrame.size.height == 44.0
/// 屏幕高度
private let SCREEN_HEIGHT = UIScreen.main.bounds.height
/// SafeArea 底部边距
private let SAFEAREA_BOTTOM_HEIGHT: CGFloat = (IS_IPHONE_XSERIES ? 34.0 : 0.0)

/// 显示一天的日程安排视图,以时间轴格式,从每天的0点到第二天的0点,展示一天的日程安排
open class DDDayScheduleView: UIView {
    
    // MARK: - public
    ///数据源,set方法内做了排序,所以不是与外部引用了相同对象,外部要查找某个日程所在的下标只能通过ID匹配
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
    var _datasource: [DDDayScheduleViewItemRepresentable] = []
    
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
        
        //添加日程view的父视图
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

    let baselineView = DDDayScheduleBaseLineView()
    ///当前时间指示器
    private let timeIndicatorView = DDDayScheduleTimeIndicatorView()
    ///所有日程Item的父视图
    let scheduleItemSuperView = UIView()
    ///保存具体日程view的数组,用于添加日程之前清空之前的view
    var scheduleViews: [DDDayScheduleItemView] = []
    
    // MARK: - datas
    ///已布局标志位
    private var layouted = false
    ///当前可编辑类型view,手势拖动时就是处理该view,可以是已存在的日程事项,也可以是新建日程view
    var currentEditableView: DDScheduleEditableView?
    ///触摸手势开始时,手指的位置
    private var touchBeginPosition: CGPoint = .zero

    typealias TouchBeginViewOffset = (top: CGFloat, bottom: CGFloat)
    ///手指触摸开始时,触摸点距离当前编辑view的顶部距离和底部距离
    private var touchBeginViewOffset: TouchBeginViewOffset = (top: 0, bottom: 0)
    ///编辑view触摸开始时的时间数据
    var touchBeginEditViewTimeData: DDScheduleTimeInfo = .zero
    ///触摸过程中临时保存的增量时间数据
    var touchMovingEditViewTimeData: DDScheduleTimeInfo = .zero
    ///编辑拖动手势
    var editingPanGest: UIPanGestureRecognizer!
    
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
        setupPlanItemSuperViewGesture()
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationDidBecomeActive, object: nil, queue: OperationQueue.main) { [weak self](_) in
            self?.timeIndicatorView.updateTime()
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        if !layouted {
            layouted = true
            layoutSubItems()
        }
    }
}

// MARK: - 手势代理
extension DDDayScheduleView: UIGestureRecognizerDelegate {
    open override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == editingPanGest {
            guard let editView = self.currentEditableView?.editMaskView else { return false }
            let position = gestureRecognizer.view?.convert(gestureRecognizer.location(in: gestureRecognizer.view), to: editView)
            return editView.containsPoint(position)
        }
        return true
    }
}

// MARK: - gesture even
private extension DDDayScheduleView {
    /// 设置planItemSuperView的点击手势和拖动手势
    private func setupPlanItemSuperViewGesture() {
        //添加点击手势,用于退出某个日程View的编辑状态,或者显示创建日程view
        let tapGest = UITapGestureRecognizer(target: self, action: #selector(onItemSuperViewTapGestureAction(_:)))
        scheduleItemSuperView.addGestureRecognizer(tapGest)
        
        //item的容器视图添加拖动手势,用于编辑currentEditableView的起止时间
        let panGest = UIPanGestureRecognizer(target: self, action: #selector(onItemSuperViewPanGestureAction(_:)))
        panGest.minimumNumberOfTouches = 1
        panGest.maximumNumberOfTouches = 1
        panGest.delegate = self
        editingPanGest = panGest
        scheduleItemSuperView.addGestureRecognizer(panGest)
        scrollView.panGestureRecognizer.require(toFail: panGest)
    }
    
    /// 设置创建日程的点击手势事件
    private func setupCreateScheduleViewAction(_ view: DDScheduleEditableView) {
        view.tapAction = { [unowned self] in
            self.delegate?.dayScheduleView(self, createNewItemWith: view.timeData)
        }
    }
    
    /// 添加创建日程view
    private func createPlanView() -> DDScheduleEditableView {
        let createPlanView = DDScheduleEditableView(type: .add)
        setupCreateScheduleViewAction(createPlanView)
        scheduleItemSuperView.addSubview(createPlanView)
        createPlanView.frame = CGRect(x: 0, y: 0, width: self.itemViewMaxWidth, height: DDDayScheduleView.OneHourHeight)
        return createPlanView
    }
    
    @objc private func onItemSuperViewTapGestureAction(_ gesture: UIGestureRecognizer) {
        guard gesture.state == .ended else { return }
        /// 点击背景,处理手势事件,
        /// 1.若currentEditableView不为空,,则将currentEditableView退出编辑状态,并清空当前currentEditableView引用,
        /// 2.否则设置为新建任务,将currentEditableView指向新的内容
        if self.currentEditableView != nil {
            //判断点击位置是否在编辑view上
            let touchPosition = gesture.location(in: gesture.view)
            if self.currentEditableView?.frame.contains(touchPosition) ?? false {
                self.currentEditableView?.editMaskView.shakeFeedback()
            } else {
                if let itemView = self.currentEditableView?.associateItemView {
                    //只有编辑已有的日程,才需要走这里
                    self.delegate?.dayScheduleView(self, editItem: itemView.model, timeInfo: self.currentEditableView!.editMaskView.timeData)
                } else {
                    self.clearCurrentEditView()
                }
            }
            
        } else {
            self.currentEditableView = self.createPlanView()
            //这里要注意,因为创建日程的间隔是1小时,开始时间不能超过23小时,否则结束时间会超过24小时
            let beginTime = min(CGFloat(DDDayScheduleView.HourAmoutOneDay - 1), self.propositionalHourValueFromPosition(gesture.location(in: gesture.view).y))
            self.currentEditableView?.becomeEditStatus(timeData: DDScheduleTimeInfo(begin: beginTime, end: beginTime + 1))
            self.scheduleItemSuperView.bringSubview(toFront: self.currentEditableView!)
            //设置baseLineView的editTimeData属性
            self.baselineView.editTimeData = self.currentEditableView?.editMaskView.timeData
        }
    }
    
    @objc private func onItemSuperViewPanGestureAction(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            self.touchBeginEditViewTimeData = self.currentEditableView!.timeData
            //给touchMovingEditViewTimeData赋初始值,用于后续计算结束和开始时间
            self.touchMovingEditViewTimeData = self.touchBeginEditViewTimeData
            self.touchBeginPosition = gesture.location(in: gesture.view)
            
            //触摸开始,计算触摸点与编辑view的上下距离
            let topPosition = self.touchBeginEditViewTimeData.begin.verticalPosition
            let bottomPosition = self.touchBeginEditViewTimeData.end.verticalPosition
            let topOffset = self.touchBeginPosition.y - topPosition
            let bottomOffset = bottomPosition - self.touchBeginPosition.y
            self.touchBeginViewOffset = (top: topOffset, bottom: bottomOffset)
            
            //根据触摸位置,判断事件类型
            let position = gesture.view?.convert(gesture.location(in: gesture.view), to: self.currentEditableView?.editMaskView)
            self.currentEditableView?.editEvenType = self.currentEditableView?.editMaskView.editEvenTypeWithTouchPosition(position)
        case .changed:
            //没有编辑事件,退出手势处理
            guard let editEvenType = self.currentEditableView?.editEvenType else { return }
            let isMoveTop = gesture.translation(in: gesture.view).y < 0
            let moveDirect: VKPlanTimelineViewPanGestureMoveDirect = isMoveTop ? .top : .bottom
            let touchPosition = gesture.location(in: gesture.view)
            
            ///根据触摸位置,判断是否需要自动滚动
            self.setupAutoScrollWith(touchPosition: touchPosition, moveDirect: moveDirect, gestureView: gesture.view)
            
            ///处理手势移动中的事件
            self.handleCurrentEditableViewWith(editEvenType: editEvenType, touchPosition: touchPosition, moveDirect: moveDirect)
            
        default:
            self.currentEditableView?.editEvenType = nil
        }
        gesture.setTranslation(.zero, in: gesture.view)
    }
    
    enum VKPlanTimelineViewPanGestureMoveDirect {
        case unknow
        case top
        case bottom
    }
    
    /// 根据手势位置判断是否需要自动滚动ScrollView
    private func setupAutoScrollWith(touchPosition: CGPoint, moveDirect: VKPlanTimelineViewPanGestureMoveDirect, gestureView: UIView?) {
        //判断当前触摸点是否快要到屏幕边缘
        let minOffset: CGFloat = 20
        switch moveDirect {
        case .top:
            let needAutoScroll = touchPosition.y - self.touchBeginViewOffset.top - self.scrollView.contentOffset.y < minOffset
            if needAutoScroll {
                self.autoScrollWith(direction: .top)
            }
            
        case .bottom:
            let positionInWindow = self.window?.convert(touchPosition, from: gestureView).y ?? touchPosition.y
            let offset = SCREEN_HEIGHT - self.frame.maxY
            // FIXME: 可能某些是显示在tabbar页面上
            let tabbarHeight: CGFloat = 0
            if positionInWindow + minOffset + self.touchBeginViewOffset.bottom > SCREEN_HEIGHT - offset - tabbarHeight {
                self.autoScrollWith(direction: .bottom)
            }
            
        case .unknow: break
            
        }
    }
    
    enum VKPlanTimelineViewAutoScrollDirection {
        case top
        case bottom
    }
    
    /// 自动滚动scrollView,每次滚动半个小时高度
    /// - Parameter direction: 自动滚动方向
    private func autoScrollWith(direction: VKPlanTimelineViewAutoScrollDirection) {
        var contentOffset = self.scrollView.contentOffset
        var y = contentOffset.y
        let step = DDDayScheduleView.OneHourHeight * 0.5
        switch direction {
        case .top:
            y -= step
            contentOffset.y = max(0 - DDDayScheduleView.ScrollViewContentInset.top, y)
            self.scrollView.setContentOffset(contentOffset, animated: false)
            
        case .bottom:
            y += step
            contentOffset.y = min(y, self.scrollView.contentSize.height + DDDayScheduleView.ScrollViewContentInset.bottom - self.scrollView.height)
            self.scrollView.setContentOffset(contentOffset, animated: false)
        }
    }
    
    private func handleCurrentEditableViewWith(editEvenType: DDScheduleEditableEvenType, touchPosition: CGPoint, moveDirect: VKPlanTimelineViewPanGestureMoveDirect) {
        //先取出当前timeData,后续要赋值回去
        var timeData = self.currentEditableView!.timeData
        switch editEvenType {
        case .begin:
            //编辑开始时间,需要改动当前编辑view的top和高度
            let propositionalBeginTime = propositionalHourValueFromPosition(touchPosition.y - self.touchBeginViewOffset.top)
            let timeLength = self.touchMovingEditViewTimeData.end - propositionalBeginTime
            guard timeLength >= DDDayScheduleView.MinPlanHourValue else {
                //时间小于半小时了,不允许
                print("修改开始时间,不允许小于半小时的宽度")
                return
            }
            
            self.touchMovingEditViewTimeData.begin = propositionalBeginTime
            
            guard self.touchMovingEditViewTimeData.availability else { return }
            
            let height = self.touchMovingEditViewTimeData.length.verticalPosition
            let top = self.touchMovingEditViewTimeData.begin.verticalPosition
            self.currentEditableView?.top = top
            self.currentEditableView?.height = height
            timeData.begin = self.touchMovingEditViewTimeData.begin
            
        case .beginEnd:
            //更改开始和结束时间,不更改时间间隔
            let timeLength = self.touchMovingEditViewTimeData.length
            
            switch moveDirect {
            case .top:
                //往上移,用开始时间判断
                let propositionalBeginTime = propositionalHourValueFromPosition(touchPosition.y - self.touchBeginViewOffset.top)
                
                self.touchMovingEditViewTimeData.begin = propositionalBeginTime
                //由开始时间,确定结束时间
                self.touchMovingEditViewTimeData.end = self.touchMovingEditViewTimeData.begin + timeLength
                
            case .bottom:
                //往下移,用结束时间判断
                let propositionalEndTime = propositionalHourValueFromPosition(touchPosition.y + self.touchBeginViewOffset.bottom)
                
                self.touchMovingEditViewTimeData.end = propositionalEndTime
                //由结束时间,确定开始时间
                self.touchMovingEditViewTimeData.begin = self.touchMovingEditViewTimeData.end - timeLength
            case .unknow: return
                
            }
            guard self.touchMovingEditViewTimeData.availability else { return }
            
            let top = self.touchMovingEditViewTimeData.begin.verticalPosition
            self.currentEditableView?.top = top
            timeData = self.touchMovingEditViewTimeData
        case .end:
            let propositionalEndTime = propositionalHourValueFromPosition(touchPosition.y + self.touchBeginViewOffset.bottom)
            let timeLength = propositionalEndTime - self.touchMovingEditViewTimeData.begin
            guard timeLength >= DDDayScheduleView.MinPlanHourValue else {
                //时间小于半小时了,不允许
                print("修改结束时间,不允许小于半小时的宽度")
                return
            }
            
            self.touchMovingEditViewTimeData.end = propositionalEndTime
            guard self.touchMovingEditViewTimeData.availability else { return }
            
            let height = self.touchMovingEditViewTimeData.length.verticalPosition
            self.currentEditableView?.height = height
            timeData.end = self.touchMovingEditViewTimeData.end
        }
        
        self.currentEditableView?.updateViewData(timeData)
        //设置baseLineView的editTimeData属性
        self.baselineView.editTimeData = timeData
    }
}

// MARK: - public func
public extension DDDayScheduleView {
    /// 清除当前编辑的日程view
    func clearCurrentEditView() {
        self.currentEditableView?.resignEditStatus()
        self.currentEditableView = nil
        self.baselineView.editTimeData = nil
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
    
    /// 日程itemsuperView到scrollview的间距
    static var ItemSuperViewEdgeInsets: UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 57, bottom: 0, right: 16)
    }
    
    /// 内容视图高度
    static var ScrollContentViewHeight: CGFloat {
        return DDDayScheduleView.OneHourHeight * 24
    }
    
    /// 日程ItemView的最大宽度
    var itemViewMaxWidth: CGFloat {
        return self.bounds.width - DDDayScheduleView.ItemSuperViewEdgeInsets.horizontal
    }
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
        //创建日程或者移动日程以15分钟为步长
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

