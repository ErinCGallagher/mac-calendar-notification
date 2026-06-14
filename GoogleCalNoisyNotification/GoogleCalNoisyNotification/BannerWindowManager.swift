import SwiftUI
import AppKit

class BannerWindowManager {
    static var window: NSPanel?
    
    static func show(title: String, startTime: String) {
        DispatchQueue.main.async {
            window?.close()
            
            let bannerView = BannerView(title: title, startTime: startTime)
            let hostingView = NSHostingView(rootView: bannerView)
            
            // Use a panel for better overlay behavior
            let panel = NSPanel(
                contentRect: .zero,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            
            panel.isFloatingPanel = true
            panel.level = .floating
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = true
            panel.ignoresMouseEvents = true
            panel.isReleasedWhenClosed = false
            
            // Add hosting view to a container to buffer constraints
            let container = NSView()
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
            
            // Calculate size and position
            let size = hostingView.intrinsicContentSize
            if let screen = NSScreen.main {
                let screenFrame = screen.frame
                let x = (screenFrame.width - size.width) / 2
                let y = screenFrame.height - size.height - 100
                panel.setFrame(NSRect(x: x, y: y, width: size.width, height: size.height), display: true)
            }
            
            panel.orderFrontRegardless()
            self.window = panel
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                if self.window == panel {
                    panel.close()
                    self.window = nil
                }
            }
        }
    }
}
