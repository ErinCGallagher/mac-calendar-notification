import SwiftUI

struct WavingShape: Shape {
    var phase: CGFloat
    
    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let waveHeight: CGFloat = 2
        let numWaves: CGFloat = 1.5
        
        // --- Top Edge ---
        // Move to top right (fixed point)
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        
        // Top edge with vertical ripples
        for x in stride(from: rect.maxX, through: rect.minX, by: -2) {
            let relativeX = (rect.maxX - x) / rect.width
            let sine = sin(relativeX * .pi * numWaves + phase)
            // Ripple gets stronger as we move left (away from the tow bar)
            let yOffset = sine * waveHeight * relativeX
            path.addLine(to: CGPoint(x: x, y: rect.minY + yOffset))
        }
        
        // --- Left (Trailing) Edge ---
        // Horizontal ripples on the left edge
        for y in stride(from: rect.minY, through: rect.maxY, by: 1) {
            let relativeY = y / rect.height
            let sine = sin(relativeY * .pi * numWaves + phase)
            // Maximum flutter on the far left edge
            let xOffset = sine * waveHeight * 1.5
            path.addLine(to: CGPoint(x: rect.minX + xOffset, y: y))
        }
        
        // --- Bottom Edge ---
        // Bottom edge with vertical ripples
        for x in stride(from: rect.minX, through: rect.maxX, by: 2) {
            let relativeX = (rect.maxX - x) / rect.width
            let sine = sin(relativeX * .pi * numWaves + phase + .pi) // phase shift for variety
            let yOffset = sine * waveHeight * relativeX
            path.addLine(to: CGPoint(x: x, y: rect.maxY + yOffset))
        }
        
        // --- Right Edge ---
        // Back to top right
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        
        path.closeSubpath()
        return path
    }
}

struct BannerView: View {
    let title: String
    let startTime: String
    
    @State private var phase: CGFloat = 0
    
    var body: some View {
        HStack(spacing: -12) { // Tighter spacing for the custom shape
            // The Flag
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(startTime)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(.leading, 24)
            .padding(.trailing, 16)
            .padding(.vertical, 24)
            .background(
                WavingShape(phase: phase)
                    .fill(Color.black)
                    .shadow(color: .black.opacity(0.3), radius: 6, x: -2, y: 3)
            )
            .zIndex(1)
            .onAppear {
                withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                    phase = .pi * 2
                }
            }

            // The Tow Bar
            Capsule()
                .fill(Color.black)
                .frame(width: 40, height: 4)
                .zIndex(0)

            // The Plane
            Image("CustomPlane")
                .resizable()
                .scaledToFit()
                .frame(height: 80)
                .zIndex(1)
        }
    }
}

#Preview {
    BannerView(
        title: "Product Design Review",
        startTime: "In 3 minutes — 2:30 PM"
    )
    .padding()
}
