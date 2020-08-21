//
//  DDDayScheduleView+TreeNode.swift
//  DDDayScheduleView
//
//  Created by huangxianhui on 2020/8/21.
//

import Foundation

/// 构造树的节点
private class DDDayScheduleItemNode {
    ///每个节点最小的时间长度,根据最小文本高度计算
    static var minTimeLength: CGFloat = {
        let minItemHeight = DDDayScheduleItemView.MinItemHeight
        //将高度转换为小时
        return minItemHeight / DDDayScheduleView.OneHourHeight
    }()
    
    let data: DDDayScheduleItemView
    ///为了性能,这里保存一份开始和结束的时间
    let timeInfo: DDScheduleTimeInfo
    ///最大的结束时间,在自己和所有孩子节点中,获取最大的,在每次插入子节点时都更新
    var maxEnd: CGFloat
    ///孩子节点
    var children: [DDDayScheduleItemNode] = []
    ///层级,用于计算作为父节点时应该平分多少宽度
    var level: Int = 1
    ///父节点,用于插入子节点时更新父节点的level
    weak var parent: DDDayScheduleItemNode?

    init(_ data: DDDayScheduleItemView) {
        self.data = data
        //若结束时间与开始时间太短,这里要求设计一个最小高度,
        let endTime = max(DDDayScheduleItemNode.minTimeLength + data.model.timeInfo.begin, data.model.timeInfo.end)
        self.timeInfo = DDScheduleTimeInfo(begin: data.model.timeInfo.begin, end: endTime)
        self.maxEnd = endTime
    }
    
    /// 判断此节点是否包含其他节点,就是判断其他节点的起点时间是否被此节点区间包含
    /// - Parameters:
    ///   - node: 其他节点
    ///   - useMaxEndTime: 是否使用子节点最大时间
    /// - Returns: true: 包含,false: 不包含
    func contains(_ node: DDDayScheduleItemNode, useMaxEndTime: Bool = false) -> Bool {
        let tempEndTime = useMaxEndTime ? maxEnd : timeInfo.end
        let value = node.data.model.timeInfo.begin >= timeInfo.begin && node.data.model.timeInfo.begin < tempEndTime
        return value
    }
}

/// 递归查找目标节点的合适父节点,
/// - Parameters:
///   - header: 最初的父节点,会递归改父节点的所有子节点,知道找到合适的目标节点的父节点
///   - targetNode: 被插入的节点
@discardableResult
private func insertNodeFrom(header: DDDayScheduleItemNode, targetNode: DDDayScheduleItemNode) -> Bool {
    if header.children.isEmpty {
        if header.contains(targetNode) {
            header.children.append(targetNode)
            targetNode.parent = header
            header.level += 1
            header.maxEnd = max(header.maxEnd, targetNode.data.model.timeInfo.end)
            
            var parent = header.parent
            while parent != nil {
                parent?.level += 1
                parent?.maxEnd = max(parent!.maxEnd, targetNode.data.model.timeInfo.end)
                parent = parent?.parent
            }
            return true
        }
        return false
    } else {
        var success = false
        //判断子节点是否包含该节点,由后往前
        for child in header.children.reversed() {
            let successInChild = insertNodeFrom(header: child, targetNode: targetNode)
            if successInChild {
                success = successInChild
                header.maxEnd = max(child.maxEnd, header.maxEnd)
                break
            }
        }
        if !success {
            //遍历所有孩子节点都不成功,就用本身节点来判断
            if header.contains(targetNode) {
                header.children.append(targetNode)
                targetNode.parent = header
                header.maxEnd = max(header.maxEnd, targetNode.data.model.timeInfo.end)
                //更新父节点的最大结束时间
                var parent = header.parent
                while parent != nil {
                    parent?.maxEnd = max(parent!.maxEnd, targetNode.data.model.timeInfo.end)
                    parent = parent?.parent
                }
                return true
            }
        }
        return success
    }
}

internal extension DDDayScheduleView {
    
    func layoutSubItems() {
        //添加之前先清除之前的编辑视图,和所有的item视图
        clearCurrentEditView()
        scheduleViews.forEach{ $0.removeFromSuperview() }
        scheduleViews.removeAll()
        _datasource.forEach {
            let itemView = DDDayScheduleItemView(model: $0)
            setupItemViewAction(itemView)
            scheduleItemSuperView.addSubview(itemView)
            scheduleViews.append(itemView)
            
            setupItemViewTopHeight(itemView)
        }
        updateItemsFrame()
    }
    
    func setupItemViewTopHeight(_ itemView: DDDayScheduleItemView) {
        let beginHourValue = itemView.model.timeInfo.begin
        //限定每个item需要最小高度,
        let endHourValue = max(itemView.model.timeInfo.end, beginHourValue + DDDayScheduleItemNode.minTimeLength)
        let x: CGFloat = 0
        let y = beginHourValue.verticalPosition
        let width = self.itemViewMaxWidth
        let height = (endHourValue - beginHourValue).verticalPosition
        itemView.frame = CGRect(x: x, y: y, width: width, height: height)
    }
    
    private func updateItemsFrame() {
        guard !self.scheduleViews.isEmpty else { return }
                
        //从0开始,向后遍历self.scheduleViews
        //1.若rootNode若空,初始化一个节点并赋值给rootNode,继续下一轮循环
        //2.初始化一个节点node,
        //2.1若rootNode能包含node,则node要么是rootNode的一个孩子节点,
        //   也可能是rootNode孩子节点链上的某个节点,因此这里要递归的查找node的合适父节点
        //2.2调用insertNodeFrom(header:targetNode:)方法递归查找node的合适父节点
        //   在将node添加到合适的节点后,会更新父节点链上的最大结束时间,用于后续判断是否包含某节点时用到
        //3.若node不被rootNode节点包含,则初始化一个新的节点,并更新rootNode指向为新初始化的节点,继续下轮循环
        
        var itemNodeArray: [DDDayScheduleItemNode] = []
        var rootNode: DDDayScheduleItemNode?
        for itemView in self.scheduleViews {
            if rootNode == nil {
                //1.若rootNode为空,初始化一个节点并赋值给rootNode,继续下一轮循环
                rootNode = DDDayScheduleItemNode(itemView)
                itemNodeArray.append(rootNode!)
                continue
            }
            //2.初始化一个节点node,
            let node = DDDayScheduleItemNode(itemView)
            //2.1若rootNode能包含node
            if rootNode?.contains(node, useMaxEndTime: true) ?? false {
                //2.2递归查找node的合适父节点
                insertNodeFrom(header: rootNode!, targetNode: node)
            } else {
                //3.若node不被rootNode节点包含
                rootNode = DDDayScheduleItemNode(itemView)
                itemNodeArray.append(rootNode!)
                continue
            }
        }

        for node in itemNodeArray {
            guard !node.children.isEmpty else {
                //没有孩子节点,略过,因为上面的setupItemViewTopHeight方法已经设置了正确的frame
                continue
            }
            
            setupNodeWidthFrom(node: node, left: 0, maxWidth: self.itemViewMaxWidth, level: node.level)
        }
    }
    
    /// 设置节点包含数据的宽度和横坐标,如果节点有子节点,需要递归设置
    /// - Parameters:
    ///   - node: 节点
    ///   - left: 节点开始的横坐标
    ///   - maxWidth: 节点的最大宽度
    ///   - level: 节点的子孩子数
    private func setupNodeWidthFrom(node: DDDayScheduleItemNode, left: CGFloat, maxWidth: CGFloat, level: Int) {
        guard level > 1 else {
            var frame = node.data.frame
            frame.origin.x = left
            frame.size.width = maxWidth
            node.data.frame = frame
            return
        }
        
        let space: CGFloat = 2
        let count = CGFloat(level)
        //因包含子节点导致根节点的宽度为最小
        let minwidth = (maxWidth - (count - 1) * space) / count
        
        //设置根节点的frame
        var frame = node.data.frame
        frame.origin.x = left
        frame.size.width = minwidth
        node.data.frame = frame
        
        let childLeft = frame.maxX + space
        let childMaxWidth = maxWidth - minwidth - space
        for child in node.children {
            //若此节点有子节点,则递归设置孩子节点的横坐标和宽度,这里要减去本身父节点的高度和横坐标偏差,
            setupNodeWidthFrom(node: child, left: childLeft, maxWidth: childMaxWidth, level: child.level)
        }
    }

    /// 设置ItemView的点击事件和编辑事件回调
    /// - Parameter itemView: 被设置的ItemView
    private func setupItemViewAction(_ itemView: DDDayScheduleItemView) {
        ///点击item的动作
        ///1.若当前有编辑任务,则判断是否点击的是同个任务
        ///1.1.若点击的不是当前编辑的任务,则退出编辑状态
        ///2.若当前有新建任务,则退出新建任务,
        ///3.否则执行点击任务回调事件
        itemView.itemViewAction = { [weak self] model in
            guard let self = self else { return }
            if self.currentEditableView != nil {
                if self.currentEditableView?.associateItemView === itemView {
                    // TODO: 若是选中了当前正在编辑的,这里用震动提示
                    self.currentEditableView?.editMaskView.shakeFeedback()
                } else {
                    self.clearCurrentEditView()
                }
            } else {
                self.delegate?.dayScheduleView(self, didSelectItem: model)
            }
        }
        
        itemView.editStatusChangeAction = { [weak self] itemView in
            guard let self = self else { return }
            self.clearCurrentEditView()
            self.currentEditableView = DDScheduleEditableView(type: .edit, associateItemView: itemView)
            self.currentEditableView?.frame = CGRect(x: 0, y: 0, width: self.itemViewMaxWidth, height: DDDayScheduleView.OneHourHeight)
            self.currentEditableView?.alpha = 0.6
            self.scheduleItemSuperView.addSubview(self.currentEditableView!)
            self.currentEditableView?.becomeEditStatus(timeData: itemView.model.timeInfo)
            //设置baseLineView的editTimeData属性
            self.baselineView.editTimeData = self.currentEditableView?.editMaskView.timeData
        }
    }
}
