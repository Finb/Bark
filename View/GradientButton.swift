//
//  UIView+Gradient.swift
//  Bark
//
//  Created by huangfeng on 2023/2/10.
//  Copyright © 2023 Fin. All rights reserved.
//

import UIKit

typealias GradientPoints = (startPoint: CGPoint, endPoint: CGPoint)

enum GradientOrientation {
    case topRightBottomLeft
    case topLeftBottomRight
    case horizontal
    case vertical

    var startPoint: CGPoint {
        return points.startPoint
    }

    var endPoint: CGPoint {
        return points.endPoint
    }

    var points: GradientPoints {
        switch self {
        case .topRightBottomLeft:
            return (CGPoint(x: 0.0, y: 1.0), CGPoint(x: 1.0, y: 0.0))
        case .topLeftBottomRight:
            return (CGPoint(x: 0.0, y: 0.0), CGPoint(x: 1, y: 1))
        case .horizontal:
            return (CGPoint(x: 0.0, y: 0.5), CGPoint(x: 1.0, y: 0.5))
        case .vertical:
            return (CGPoint(x: 0.0, y: 0.0), CGPoint(x: 0.0, y: 1.0))
        }
    }
}

class GradientButton: UIButton {
    lazy var gradient: CAGradientLayer = {
        let gradient = CAGradientLayer()
        return gradient
    }()

    func applyGradient(withColours colours: [UIColor], gradientOrientation orientation: GradientOrientation) {
        gradient.frame = self.bounds
        gradient.colors = colours.map { $0.cgColor }
        gradient.startPoint = orientation.startPoint
        gradient.endPoint = orientation.endPoint

        if gradient.superlayer == nil {
            self.layer.insertSublayer(gradient, at: 0)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = self.bounds
    }
}
