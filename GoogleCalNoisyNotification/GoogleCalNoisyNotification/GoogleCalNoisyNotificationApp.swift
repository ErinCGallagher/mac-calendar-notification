//
//  GoogleCalNoisyNotificationApp.swift
//  GoogleCalNoisyNotification
//
//  Created by Erin Gallagher on 2026-06-14.
//

import SwiftUI
import EventKit

@main
struct GoogleCalNoisyNotificationApp: App {
    @State private var calendarManager = CalendarManager()
    
    var body: some Scene {
        MenuBarExtra("GoogleCalNoisyNotificationsApp", systemImage: "calendar.badge.clock") {
            Button("GoogleCalNoisyNotificationsApp") { }
                .disabled(true)
            
            Divider()
            
            if calendarManager.authStatus == .denied || calendarManager.authStatus == .restricted {
                Button("⚠️ Calendar Access Denied") { }
                    .disabled(true)
                Button("Enable in System Settings...") {
                    calendarManager.openSystemSettingsCalendars()
                }
            } else if calendarManager.authStatus == .notDetermined {
                Button("Grant Calendar Access...") {
                    calendarManager.requestAccess()
                }
            } else {
                if calendarManager.allCalendars.isEmpty {
                    Button("No Calendars Found") { }
                        .disabled(true)
                    Button("Link Google Account in Settings...") {
                        calendarManager.openSystemSettingsInternetAccounts()
                    }
                } else {
                    Menu("Select Calendars") {
                        let grouped = Dictionary(grouping: calendarManager.allCalendars, by: { $0.source?.title ?? "Other" })
                        ForEach(grouped.keys.sorted(), id: \.self) { sourceTitle in
                            Menu(sourceTitle) {
                                ForEach(grouped[sourceTitle] ?? [], id: \.calendarIdentifier) { calendar in
                                    Toggle(calendar.title, isOn: Binding(
                                        get: { calendarManager.isCalendarSelected(calendar.calendarIdentifier) },
                                        set: { _ in calendarManager.toggleCalendar(calendar.calendarIdentifier) }
                                    ))
                                }
                            }
                        }
                    }
                }
            }
            
            Divider()
            
            Toggle("Play Notification Sound", isOn: Binding(
                get: { calendarManager.isSoundEnabled },
                set: { _ in calendarManager.toggleSound() }
            ))
            
            Divider()
            
            Menu("Test") {
                Button("Test Banner") {
                    BannerWindowManager.show(
                        title: "Test Meeting",
                        location: "Room 101",
                        startTime: "In 3 minutes — 2:30 PM"
                    )
                }
                
                Button("Test Long Banner") {
                    BannerWindowManager.show(
                        title: "Quarterly Global Strategy Alignment and Resource Planning Session",
                        location: "Main Auditorium - Building B",
                        startTime: "In 3 minutes — 10:00 AM"
                    )
                }
            }
            
            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}

