import SwiftUI

struct BannerAnimationView: View {
    let title: String
    let startTime: String
    let onComplete: () -> Void
    
    @State private var offset: CGFloat = 0
    
    // Get screen width
    private let screenWidth = NSScreen.main?.frame.width ?? 1920
    
    var body: some View {
        ZStack(alignment: .leading) {
            Color.clear
            
            BannerView(title: title, startTime: startTime)
                .offset(x: offset)
        }
        .frame(width: screenWidth, height: 80)
        .onAppear {
            print("Animation started. Screen width: \(screenWidth)")
            
            // Start AT the left edge
            offset = -200
            
            // Animate to the right edge
            withAnimation(.linear(duration: 15)) {
                offset = screenWidth
            }
            
            // Call completion after animation finishes
            DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
                print("Animation finished.")
                onComplete()
            }
        }
    }
}

#Preview {
    BannerAnimationView(title: "Product Design Review", startTime: "In 3 minutes — 2:30 PM") {
        print("Animation Complete")
    }
}
