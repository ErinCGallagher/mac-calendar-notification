import SwiftUI

struct WavingShape: Shape {
    var phase: CGFloat
    
    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let waveHeight: CGFloat = 4
        let numWaves: CGFloat = 2
        
        // Start at top right
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        
        // Top edge
        path.addLine(to: CGPoint(x: rect.minX + 8, y: rect.minY))
        
        // Left (trailing) edge - the fluttery part
        for y in stride(from: rect.minY, through: rect.maxY, by: 1) {
            let relativeY = y / rect.height
            let sine = sin(relativeY * .pi * numWaves + phase)
            let xOffset = sine * waveHeight * (1.0 - relativeY * 0.2) // More flutter at the top/middle
            path.addLine(to: CGPoint(x: rect.minX + xOffset, y: y))
        }
        
        // Bottom edge
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        
        // Right edge (connected to tow bar)
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
            .padding(.leading, 24) // Extra padding for the waving edge
            .padding(.trailing, 16)
            .padding(.vertical, 12)
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
