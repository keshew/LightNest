import SwiftUI

struct LightOfflineView: View {
    var body: some View {
        LightScreenImage(portrait: "inprt", landscape: "inlan")
            .preferredColorScheme(.dark)
    }
}

#Preview("No Internet") {
    LightOfflineView()
}
