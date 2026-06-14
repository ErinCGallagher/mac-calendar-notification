import SwiftUI

struct BannerView: View {
    let title: String
    let startTime: String
    
    var body: some View {
        HStack(spacing: 0) {
            // The Plane
            Text("✈️")
                .font(.system(size: 28))
            
            // The Flag
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(startTime)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.75))
            )
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
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
