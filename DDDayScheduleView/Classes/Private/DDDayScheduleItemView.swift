//
//  DDDayScheduleItemView.swift
//  DDDayScheduleView
//
//  Created by huangxianhui on 2020/8/17.
//

import UIKit

private enum VKPlanTimelineItemViewStatus {
    case normal
    case edit
    
    mutating func reset() {
        self = .normal
    }
}

class DDDayScheduleItemView: UIView {
    ///item的最小高度
    static var MinItemHeight: CGFloat {
        return TitleLabelFont.lineHeight + TitleLabelInset.vertical
    }
    
    private static var TitleLabelInset: UIEdgeInsets {
        return UIEdgeInsets(top: 3, left: 7, bottom: 3, right: 5)
    }
    
    private static var TitleLabelFont: UIFont {
        return .systemFont(ofSize: 12)
    }
    
    // MARK: - public var
    let model: DDDayScheduleViewItemRepresentable
    ///当编辑状态改变时调用的回调方法,用于告知外部,需要更改编辑视图了
    var editStatusChangeAction: ((_ item: DDDayScheduleItemView) -> Void)?
    ///点击事件,进入事件详情,实现VKPlanViewActionProtocl协议所需属性
    private var _tapAction: ((DDDayScheduleViewItemRepresentable) -> Void)?
    
    // MARK: - private var
    private var viewStatus: VKPlanTimelineItemViewStatus = .normal {
        didSet {
            updateViewStatus()
            if viewStatus == .edit {
                self.editStatusChangeAction?(self)
            }
        }
    }
    
    ///容器view
    private let containerView: UIView = {
        let view = UIView()
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor.gray.cgColor
        view.layer.cornerRadius = 2
        view.backgroundColor = .white
        view.layer.masksToBounds = true
        //添加左边的标志
        let leftView = UIView()
        leftView.backgroundColor = DDScheduleEditableView.TintColor
        view.addSubview(leftView)
        leftView.snp.makeConstraints { (make) in
            make.left.top.bottom.equalTo(0)
            make.width.equalTo(3)
        }
        return view
    }()
    
    ///标题label
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = DDDayScheduleItemView.TitleLabelFont
        label.textColor = .black
        label.numberOfLines = 0
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    // MARK: - life cycle
    required init?(coder: NSCoder) {
        fatalError("no implement")
    }
    
    required init(model: DDDayScheduleViewItemRepresentable) {
        self.model = model
        super.init(frame: .zero)
        commonInit()
        updateModel()
    }
    
    private func commonInit() {
        addSubview(containerView)
        containerView.snp.makeConstraints { (make) in
            make.edges.equalTo(0)
        }
        
        containerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(DDDayScheduleItemView.TitleLabelInset.left)
            make.top.equalTo(DDDayScheduleItemView.TitleLabelInset.top)
            make.right.equalTo(-DDDayScheduleItemView.TitleLabelInset.right)
            make.bottom.lessThanOrEqualTo(-DDDayScheduleItemView.TitleLabelInset.bottom)
        }
        
        //设置view状态为默认,
        viewStatus = .normal
        
        //添加长按手势,触发编辑状态
        let longPressGest = UILongPressGestureRecognizer(target: self, action: #selector(onLongPressGestureAction(_:)))
        containerView.addGestureRecognizer(longPressGest)
        
        //添加点击手势
        let tapGest = UITapGestureRecognizer(target: self, action: #selector(onTapGestureAction(_:)))
        containerView.addGestureRecognizer(tapGest)
        
        tapGest.shouldRequireFailure(of: longPressGest)
    }
    
    @objc private func onLongPressGestureAction(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, self.viewStatus == .normal else { return }
        //将当前view置为编辑状态,会触发editStatusChangeAction回调
        self.viewStatus = .edit
    }
    
    @objc private func onTapGestureAction(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else { return }
        self._tapAction?(self.model)
    }
}

private extension DDDayScheduleItemView {
    
     func updateViewStatus() {
        switch viewStatus {
        case .edit:
            self.alpha = 0.6
        case .normal:
            self.alpha = 1
        }
    }
    
    /// 设置内容,如标题,当前所处的状态
    func updateModel() {
        self.titleLabel.text = model.name
    }
}

extension DDDayScheduleItemView: DDDayScheduleItemViewActionProtocl {
    
    var itemViewAction: TapAction? {
        get {
            return _tapAction
        }
        set {
            _tapAction = newValue
        }
    }
}

// MARK: - public func
extension DDDayScheduleItemView {
    
    func resignEditStatus() {
        self.viewStatus.reset()
    }
}
