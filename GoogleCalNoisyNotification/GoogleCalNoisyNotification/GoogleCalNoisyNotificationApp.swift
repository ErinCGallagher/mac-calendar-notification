//
//  GoogleCalNoisyNotificationApp.swift
//  GoogleCalNoisyNotification
//
//  Created by Erin Gallagher on 2026-06-14.
//

import SwiftUI

@main
struct GoogleCalNoisyNotificationApp: App {
    @State private var calendarManager = CalendarManager()
    
    var body: some Scene {
        MenuBarExtra("GoogleCalNoisyNotificationsApp", systemImage: "calendar.badge.clock") {
            Button("GoogleCalNoisyNotificationsApp") { }
                .disabled(true)
            
            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}
