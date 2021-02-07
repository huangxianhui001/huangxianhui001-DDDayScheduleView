//
//  UIEdgeInset+DDExtension.swift
//  DDDayScheduleView
//
//  Created by huangxianhui on 2020/8/17.
//

import Foundation

internal extension UIEdgeInsets {
    var horizontal: CGFloat {
        return self.left + self.right
    }
    var vertical: CGFloat {
        return self.top + self.bottom
    }
}
