import SwiftUI
import AppKit

class BannerWindowManager {
    static var window: NSPanel?
    
    static func show(title: String, location: String?, startTime: String) {
        DispatchQueue.main.async {
            window?.close()
            
            // Play a premium native alert sound
            NSSound(named: "Glass")?.play()
            
            let animationView = BannerAnimationView(title: title, location: location, startTime: startTime) {
                window?.close()
                window = nil
            }
            
            let hostingView = NSHostingView(rootView: animationView)
            
            let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
            let bannerHeight: CGFloat = 120 
            
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: (screenFrame.height - bannerHeight) / 2, width: screenFrame.width, height: bannerHeight),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            
            panel.isFloatingPanel = true
            panel.level = .floating
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = false
            panel.ignoresMouseEvents = true
            panel.isReleasedWhenClosed = false
            
            // Re-apply the container strategy to prevent the layout loop
            let container = NSView(frame: NSRect(x: 0, y: 0, width: screenFrame.width, height: bannerHeight))
            container.translatesAutoresizingMaskIntoConstraints = false
            panel.contentView = container
            
            hostingView.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(hostingView)
            
            NSLayoutConstraint.activate([
                hostingView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                hostingView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                hostingView.topAnchor.constraint(equalTo: container.topAnchor),
                hostingView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])
            
            panel.orderFrontRegardless()
            self.window = panel
        }
    }
}
