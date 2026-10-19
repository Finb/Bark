//
//  QRCodeGenerator.swift
//  Bark
//
//  Created by xic on 2026/10/16.
//  Copyright © 2026 Fin. All rights reserved.
//

import CoreImage.CIFilterBuiltins
import UIKit

enum QRCodeGenerator {
    /// 生成二维码图片。使用系统内置 CIQRCodeGenerator，无需第三方依赖。
    /// 放大渲染时关闭插值，保证方块边缘锐利、便于扫码识别。
    /// - Parameters:
    ///   - string: 要编码的文本（如推送 URL 或 Key）
    ///   - size: 输出图片的边长（像素）
    static func image(for string: String, size: CGFloat) -> UIImage? {
        guard !string.isEmpty else { return nil }

        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        guard let outputImage = filter.outputImage else { return nil }

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { context in
            context.cgContext.interpolationQuality = .none
            UIImage(ciImage: outputImage).draw(in: CGRect(x: 0, y: 0, width: size, height: size))
        }
    }
}
