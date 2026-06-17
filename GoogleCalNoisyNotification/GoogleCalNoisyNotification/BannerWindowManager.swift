import SwiftUI
import AppKit

class BannerWindowManager {
    struct NotificationItem {
        let title: String
        let location: String?
        let startTime: String
    }
    
    private static var queue: [NotificationItem] = []
    private static var isDisplaying = false
    static var window: NSPanel?
    
    static func show(title: String, location: String?, startTime: String) {
        DispatchQueue.main.async {
            let item = NotificationItem(title: title, location: location, startTime: startTime)
            queue.append(item)
            processQueue()
        }
    }
    
    private static func processQueue() {
        assert(Thread.isMainThread)
        
        guard !isDisplaying else { return }
        guard !queue.isEmpty else { return }
        
        isDisplaying = true
        let item = queue.removeFirst()
        
        // Play a premium native alert sound if enabled in settings
        let isSoundEnabled = UserDefaults.standard.object(forKey: "IsSoundEnabled") as? Bool ?? true
        if isSoundEnabled {
            NSSound(named: "Glass")?.play()
        }
        
        let animationView = BannerAnimationView(title: item.title, location: item.location, startTime: item.startTime) {
            DispatchQueue.main.async {
                window?.close()
                window = nil
                isDisplaying = false
                
                // Allow a small delay (0.5s) between banners for a polished transition
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    processQueue()
                }
            }
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
