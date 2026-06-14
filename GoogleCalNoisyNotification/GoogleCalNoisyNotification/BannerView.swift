import SwiftUI

struct WavingShape: Shape {
    var phase: CGFloat
    
    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let waveHeight: CGFloat = 1.5
        let numWaves: CGFloat = 1.5
        
        // --- Top Edge ---
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        for x in stride(from: rect.maxX, through: rect.minX, by: -2) {
            let relativeX = (rect.maxX - x) / rect.width
            let sine = sin(relativeX * .pi * numWaves + phase)
            let yOffset = sine * waveHeight * relativeX
            path.addLine(to: CGPoint(x: x, y: rect.minY + yOffset))
        }
        
        // --- Left (Trailing) Edge ---
        for y in stride(from: rect.minY, through: rect.maxY, by: 1) {
            let relativeY = y / rect.height
            let sine = sin(relativeY * .pi * numWaves + phase)
            let xOffset = sine * waveHeight * 1.5
            path.addLine(to: CGPoint(x: rect.minX + xOffset, y: y))
        }
        
        // --- Bottom Edge ---
        for x in stride(from: rect.minX, through: rect.maxX, by: 2) {
            let relativeX = (rect.maxX - x) / rect.width
            let sine = sin(relativeX * .pi * numWaves + phase + .pi)
            let yOffset = sine * waveHeight * relativeX
            path.addLine(to: CGPoint(x: x, y: rect.maxY + yOffset))
        }
        
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

struct BannerView: View {
    let title: String
    let location: String?
    let startTime: String
    
    @State private var phase: CGFloat = 0
    
    var body: some View {
        HStack(spacing: -12) {
            // The Flag
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                if let location = location, !location.isEmpty {
                    Text(location)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(1)
                }
                
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
        location: "Conference Room A",
        startTime: "In 3 minutes — 2:30 PM"
    )
    .padding()
}
