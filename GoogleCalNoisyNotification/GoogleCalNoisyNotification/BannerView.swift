import SwiftUI

struct BannerView: View {
    let title: String
    let startTime: String
    
    var body: some View {
        HStack(spacing: -8) { // Negative spacing to bring elements together
            // The Flag (Now on the left because we are traveling right)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(startTime)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.75))
            )
            .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
            .zIndex(1) // Keep flag above tow bar

            // The Tow Bar
            Capsule()
                .fill(Color.black.opacity(0.75))
                .frame(width: 40, height: 4)
                .zIndex(0) // Behind plane and flag

            // The Plane (Now an image)
            Image("CustomPlane")
                .resizable()
                .scaledToFit()
                .frame(height: 80)
                .zIndex(1) // Keep plane above tow bar
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
