import SwiftUI
import UIKit

/// 优先从 App Group 图片缓存读取的图片视图，未命中时下载并缓存。
struct WatchCachedImage: View {
    let url: URL
    let cornerRadius: CGFloat

    @State private var image: UIImage?
    @State private var failed = false

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            } else if !failed {
                ProgressView()
            }
        }
        .task(id: url) {
            image = nil
            failed = false

            guard let data = await WatchImageCache.data(for: url),
                  let loaded = UIImage(data: data)
            else {
                failed = true
                return
            }
            image = loaded
        }
    }
}
