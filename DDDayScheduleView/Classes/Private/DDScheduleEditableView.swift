//
//  DDScheduleEditableView.swift
//  DDDayScheduleView
//
//  Created by huangxianhui on 2020/8/20.
//

import UIKit
/**
    编辑事件类型
 - edit: 更改已有日程的时间
 - add: 新增日程
 */
enum DDScheduleEditableType {
    ///更改已有日程的时间
    case edit
    ///新增日程
    case add
}

/**
    编辑日程时间类型
 - begin: 更改开始时间
 - end: 更改结束时间
 - beginEnd: 更改开始和结束时间
 */
enum DDScheduleEditableEvenType {
    ///更改开始时间
    case begin
    ///更改结束时间
    case end
    ///更改开始和结束时间
    case beginEnd
}

/// 单击DDDayScheduleView时,出现的创建计划view,或者长按某个计划时出现的可编辑View,可上下拖动,可修改开始时间和结束时间
class DDScheduleEditableView: UIView {
    static var TintColor: UIColor {
        return UIColor.systemGreen
    }
    
    // MARK: - public
    ///点击事件,进入创建事件页面
    var tapAction: (() -> Void)?
    let editType: DDScheduleEditableType
    var editEvenType: DDScheduleEditableEvenType?
    var editView = DDScheduleEditMaskView()
    ///关联日程View,只有editType是.edit类型时才有值
    weak var associateItemView: DDDayScheduleItemView?
    
    // MARK: - private
    private var titleLabelInset: UIEdgeInsets {
        return UIEdgeInsets(top: 3, left: 4, bottom: 3, right: 4)
    }
    
    //容器view
    private let containerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 2
        view.backgroundColor = DDScheduleEditableView.TintColor
        view.layer.masksToBounds = true
        return view
    }()
    
    ///标题label
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .white
        label.numberOfLines = 0
        label.text = "再次点击创建计划"
        return label
    }()
    
    // MARK: - life cycle
    required init?(coder: NSCoder) {
        fatalError("no implement")
    }
    
    init(type: DDScheduleEditableType, associateItemView: DDDayScheduleItemView? = nil) {
        self.editType = type
        self.associateItemView = associateItemView
        if type == .edit {
            assert(associateItemView != nil, "为编辑类型时,关联日程view不能为空")
        }
        super.init(frame: .zero)
        commonInit()
    }
    
    private override init(frame: CGRect) {
        self.editType = .add
        super.init(frame: frame)
        commonInit()
    }
    
    private func commonInit() {
        
        addSubview(containerView)
        containerView.snp.makeConstraints { (make) in
            make.edges.equalTo(0)
        }
        if editType == .add {
            containerView.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { (make) in
                make.left.equalTo(titleLabelInset.left)
                make.top.equalTo(titleLabelInset.top)
                make.right.equalTo(titleLabelInset.right)
                make.bottom.lessThanOrEqualTo(-titleLabelInset.bottom)
            }
        }
        
        //添加编辑view
        editView.layer.cornerRadius = containerView.layer.cornerRadius
        addSubview(editView)
        editView.snp.makeConstraints { (make) in
            make.edges.equalTo(0)
        }
        
        if editType == .add {
            //添加点击手势
            let tapGest = UITapGestureRecognizer(target: self, action: #selector(onGestureAction(_:)))
            addGestureRecognizer(tapGest)
        }
    }
    
    @objc func onGestureAction(_ sender: UIGestureRecognizer) {
        guard sender.state == .ended else { return }
        self.tapAction?()
    }
}

// MARK: - public func
extension DDScheduleEditableView {
    
    var timeData: DDScheduleTimeInfo {
        return editView.timeData
    }
    
    var editMaskView: DDScheduleEditMaskView {
        return editView
    }
    
    func becomeEditStatus(timeData: DDScheduleTimeInfo) {
        self.isHidden = false
        
        //重设高度和位置
        self.top = timeData.begin.verticalPosition
        self.height = timeData.length.verticalPosition
        updateViewData(timeData)
    }
    
    func resignEditStatus() {
//        self.associateItemView?.resignEditStatus()
        self.removeFromSuperview()
    }
    
    func updateViewData(_ data: DDScheduleTimeInfo) {
        editView.timeData = data
        
    }
}
