//
//  BigButtonView.swift
//  Bark
//
//  Created by Jian Qin on 9/30/26.
//


import SwiftUI
import WatchKit

/// A full-page layout with a caption, a large title, an optional message, and
/// an optional button that fills the remaining height.
///
/// Pass a `Button` or `NavigationLink` with a plain label; it is styled with
/// `buttonShape` in `tint`. The caller supplies the page's container background.
struct BigButtonView<Action: View>: View {
    let caption: LocalizedStringKey
    let title: LocalizedStringKey
    var buttonColor: Color = .blue
    var message: Text?
    @ViewBuilder var action: Action

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(caption)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(title)
                        .font(.system(.title, design: .default, weight: .heavy))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)

                if let message {
                    message
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding([.bottom, .horizontal], 8)
            .frame(maxWidth: .infinity, alignment: .leading)

            // Push the button to the bottom of the screen when it's shorter
            // than the remaining space.
            Spacer(minLength: 0)

            action
                .buttonStyle(BigButtonStyle(tint: buttonColor))
                .padding([.horizontal, .bottom], 8)
                .ignoresSafeArea(edges: [.horizontal, .bottom])
        }
        // Pin to the top so the header stays put whether or not the button
        // is present to fill the remaining height.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}


private struct BigButtonStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.title2, design: .default, weight: .black))
            .foregroundStyle(.white)
            // Cap the height at 2/5 of the screen so the button doesn't dominate
            // larger watches; it still shrinks when less space is available.
            .frame(maxWidth: .infinity,
                   maxHeight: WKInterfaceDevice.current().screenBounds.height * 2 / 5)
            .background(tint, in: RoundedRectangle(cornerRadius: 38, style: .continuous))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
#Preview("With button") {
    BigButtonView(caption: "Servers", title: "None yet") {
        Button {} label: {
            Label("Add", systemImage: "plus")
        }
    }
}
