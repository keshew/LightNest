import SwiftUI

struct LightScreenImage: View {
    let portrait: String
    let landscape: String

    var body: some View {
        GeometryReader { proxy in
            let isLandscape = proxy.size.width > proxy.size.height
            Image(isLandscape ? landscape : portrait)
                .resizable()
                .scaledToFill()
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
        }
        .ignoresSafeArea()
    }
}
