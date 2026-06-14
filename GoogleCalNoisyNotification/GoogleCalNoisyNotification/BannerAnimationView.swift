import SwiftUI

struct BannerAnimationView: View {
    let title: String
    let location: String?
    let startTime: String
    let onComplete: () -> Void
    
    @State private var offset: CGFloat = 0
    
    private let screenWidth = NSScreen.main?.frame.width ?? 1920
    
    var body: some View {
        ZStack(alignment: .leading) {
            Color.clear
            
            BannerView(title: title, location: location, startTime: startTime)
                .offset(x: offset)
        }
        .frame(width: screenWidth, height: 120)
        .onAppear {
            // Start at the left edge
            offset = 0
            
            // Animate to the right edge
            withAnimation(.linear(duration: 15)) {
                offset = screenWidth
            }
            
            // Call completion after animation finishes
            DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
                onComplete()
            }
        }
    }
}

#Preview {
    BannerAnimationView(title: "Product Design Review", location: "Conference Room A", startTime: "In 3 minutes — 2:30 PM") {
        print("Animation Complete")
    }
}
