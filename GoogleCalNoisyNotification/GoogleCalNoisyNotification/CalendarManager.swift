//
//  CalendarManager.swift
//  GoogleCalNoisyNotification
//
//  How Calendar Integration and Notifications Work:
//
//  1. Event Polling & Syncing:
//     - Real-time: Listens to `.EKEventStoreChanged` notifications. When macOS syncs in the background
//       or you edit an event, updates are pulled instantly.
//     - Fallback: A background timer polls the local macOS event database every 5 minutes.
//     - On-demand: Re-fetches events whenever the app becomes active (e.g., clicking the menu bar icon).
//
//  2. Notification Decision Logic:
//     - Target Time: Computes a target alert time exactly 3 minutes before the meeting starts.
//     - Future events: Schedules a precise Swift `Timer` to fire at that exact target time.
//     - Near-future/just-started events: Triggers the notification immediately if the event starts
//       in less than 3 minutes (or started within the last 60 seconds) and hasn't been alerted yet.
//     - Past events: Ignored if started more than 60 seconds ago.
//     - Rescheduling: Automatically invalidates and recreates timers if a meeting time is updated.
//

import Foundation
import EventKit
import Observation
import AppKit

@Observable
class CalendarManager {
    private let eventStore = EKEventStore()
    
    // Current permission status
    var authStatus: EKAuthorizationStatus = .notDetermined
    
    // All available calendars found in the system
    var allCalendars: [EKCalendar] = []
    
    // User's selected calendar IDs
    var selectedCalendarIdentifiers: Set<String> = []
    
    // Upcoming events sorted by start date
    var events: [EKEvent] = []
    
    // Timers for scheduled notifications, keyed by eventIdentifier
    private var notificationTimers: [String: Timer] = [:]
    
    // Keep track of which event IDs we've already shown a banner for in this session
    private var notifiedEventIDs: Set<String> = []
    
    // Observers for system updates and periodic refreshing
    private var storeChangeObserver: Any?
    private var appActiveObserver: Any?
    private var periodicFetchTimer: Timer?
    
    // Persistent key for UserDefaults
    private let selectedCalendarsKey = "SelectedCalendarIdentifiers"
    
    init() {
        loadSettings()
        checkAuthStatus()
        setupNotificationObservers()
        setupPeriodicFetch()
    }
    
    deinit {
        if let observer = storeChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let activeObserver = appActiveObserver {
            NotificationCenter.default.removeObserver(activeObserver)
        }
        periodicFetchTimer?.invalidate()
        cancelAllTimers()
    }
    
    // Sound alert preferences
    var isSoundEnabled: Bool = true
    
    private func loadSettings() {
        if let savedIds = UserDefaults.standard.stringArray(forKey: selectedCalendarsKey) {
            self.selectedCalendarIdentifiers = Set(savedIds)
        }
        self.isSoundEnabled = UserDefaults.standard.object(forKey: "IsSoundEnabled") as? Bool ?? true
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(Array(selectedCalendarIdentifiers), forKey: selectedCalendarsKey)
    }
    
    func toggleSound() {
        isSoundEnabled.toggle()
        UserDefaults.standard.set(isSoundEnabled, forKey: "IsSoundEnabled")
    }
    
    func checkAuthStatus() {
        let status = EKEventStore.authorizationStatus(for: .event)
        DispatchQueue.main.async {
            self.authStatus = status
            
            let hasAccess: Bool
            if #available(macOS 14.0, *) {
                hasAccess = (status == .fullAccess || status == .authorized)
            } else {
                hasAccess = (status == .authorized)
            }
            
            if hasAccess {
                self.updateAvailableCalendars()
            }
        }
    }
    
    func requestAccess() {
        let status = EKEventStore.authorizationStatus(for: .event)
        if status == .notDetermined {
            if #available(macOS 14.0, *) {
                eventStore.requestFullAccessToEvents { [weak self] granted, error in
                    self?.checkAuthStatus()
                }
            } else {
                eventStore.requestAccess(to: .event) { [weak self] granted, error in
                    self?.checkAuthStatus()
                }
            }
        } else {
            checkAuthStatus()
        }
    }
    
    func openSystemSettingsCalendars() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
            NSWorkspace.shared.open(url)
        }
    }
    
    func openSystemSettingsInternetAccounts() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Internet-Accounts-Settings.extension") {
            NSWorkspace.shared.open(url)
        } else if let url = URL(string: "x-apple.systempreferences:") {
            NSWorkspace.shared.open(url)
        }
    }
    
    func updateAvailableCalendars() {
        let fetchedCalendars = eventStore.calendars(for: .event)
        
        DispatchQueue.main.async {
            self.allCalendars = fetchedCalendars.sorted { $0.title.localizedCompare($1.title) == .orderedAscending }
            
            // If we have never saved settings before, default to selecting Google/Gmail calendars
            if UserDefaults.standard.object(forKey: self.selectedCalendarsKey) == nil {
                let googleCalendars = fetchedCalendars.filter { cal in
                    let sourceTitle = (cal.source?.title ?? "").lowercased()
                    let calTitle = cal.title.lowercased()
                    return sourceTitle.contains("google") || sourceTitle.contains("gmail") ||
                           calTitle.contains("google") || calTitle.contains("gmail")
                }
                
                if !googleCalendars.isEmpty {
                    self.selectedCalendarIdentifiers = Set(googleCalendars.map { $0.calendarIdentifier })
                } else {
                    // Fallback: select all calendars if no Google accounts are linked
                    self.selectedCalendarIdentifiers = Set(fetchedCalendars.map { $0.calendarIdentifier })
                }
                self.saveSettings()
            }
            
            self.fetchEvents()
        }
    }
    
    func toggleCalendar(_ identifier: String) {
        if selectedCalendarIdentifiers.contains(identifier) {
            selectedCalendarIdentifiers.remove(identifier)
        } else {
            selectedCalendarIdentifiers.insert(identifier)
        }
        saveSettings()
        fetchEvents()
    }
    
    func isCalendarSelected(_ identifier: String) -> Bool {
        return selectedCalendarIdentifiers.contains(identifier)
    }
    
    func fetchEvents() {
        let calendars = eventStore.calendars(for: .event).filter {
            selectedCalendarIdentifiers.contains($0.calendarIdentifier)
        }
        
        guard !calendars.isEmpty else {
            DispatchQueue.main.async {
                self.events = []
                self.cancelAllTimers()
            }
            return
        }
        
        let now = Date()
        // Fetch events from 10 minutes ago until tomorrow
        let startDate = now.addingTimeInterval(-600)
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        let fetchedEvents = eventStore.events(matching: predicate)
        
        DispatchQueue.main.async {
            // Filter out all-day events if they don't have a specific start time, or keep them if desired.
            // Typically, noisy alerts are for timed meetings.
            let timedEvents = fetchedEvents.filter { !$0.isAllDay }
            self.events = timedEvents.sorted { $0.startDate < $1.startDate }
            
            print("Fetched \(self.events.count) events from selected calendars:")
            for event in self.events {
                print("- \(event.title ?? "Untitled") at \(event.startDate!)")
            }
            
            self.scheduleEventNotifications()
        }
    }
    
    private func scheduleEventNotifications() {
        let now = Date()
        
        // Cancel timers for events that are no longer in our upcoming list
        let fetchedEventIDs = Set(events.compactMap { $0.eventIdentifier })
        for (eventID, timer) in notificationTimers {
            if !fetchedEventIDs.contains(eventID) {
                timer.invalidate()
                notificationTimers.removeValue(forKey: eventID)
            }
        }
        
        for event in events {
            guard let eventID = event.eventIdentifier else { continue }
            
            // Skip if already notified
            guard !notifiedEventIDs.contains(eventID) else { continue }
            
            guard let startDate = event.startDate else { continue }
            
            // Trigger 3 minutes before the start time
            let notificationDate = startDate.addingTimeInterval(-180)
            
            if notificationDate > now {
                // Event starts more than 3 minutes in the future. Schedule a precise timer.
                if let existingTimer = notificationTimers[eventID] {
                    // If the event start time was updated, reschedule the timer
                    if abs(existingTimer.fireDate.timeIntervalSince(notificationDate)) > 1.0 {
                        existingTimer.invalidate()
                        scheduleTimer(for: event, at: notificationDate)
                    }
                } else {
                    scheduleTimer(for: event, at: notificationDate)
                }
            } else {
                // Event is starting within the next 3 minutes, or started in the last minute.
                // Trigger the alert immediately if we haven't already.
                let timeUntilStart = startDate.timeIntervalSince(now)
                if timeUntilStart > -60 && timeUntilStart <= 180 {
                    triggerNotification(for: event)
                }
            }
        }
    }
    
    private func scheduleTimer(for event: EKEvent, at date: Date) {
        guard let eventID = event.eventIdentifier else { return }
        
        let timer = Timer(fire: date, interval: 0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            // Retrieve latest event state to trigger
            if let latestEvent = self.events.first(where: { $0.eventIdentifier == eventID }) {
                self.triggerNotification(for: latestEvent)
            }
        }
        
        RunLoop.main.add(timer, forMode: .common)
        notificationTimers[eventID] = timer
        print("Scheduled notification for '\(event.title ?? "Untitled")' at \(date)")
    }
    
    private func triggerNotification(for event: EKEvent) {
        guard let eventID = event.eventIdentifier else { return }
        
        guard !notifiedEventIDs.contains(eventID) else { return }
        notifiedEventIDs.insert(eventID)
        
        // Clean up the timer from the registry
        notificationTimers[eventID]?.invalidate()
        notificationTimers.removeValue(forKey: eventID)
        
        // Format the presentation time
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let timeStr = formatter.string(from: event.startDate)
        
        let timeLabel: String
        let timeInterval = event.startDate.timeIntervalSince(Date())
        if timeInterval > 0 {
            let minutes = Int(ceil(timeInterval / 60.0))
            timeLabel = "In \(minutes) minute\(minutes == 1 ? "" : "s") — \(timeStr)"
        } else {
            timeLabel = "Started at \(timeStr)"
        }
        
        print("ALERTING: '\(event.title ?? "Untitled")' starting at \(timeStr)")
        
        BannerWindowManager.show(
            title: event.title ?? "Untitled Meeting",
            location: event.location,
            startTime: timeLabel
        )
    }
    
    private func cancelAllTimers() {
        for timer in notificationTimers.values {
            timer.invalidate()
        }
        notificationTimers.removeAll()
    }
    
    private func setupNotificationObservers() {
        // Listen to system calendar database changes (syncs, manual edits, etc.)
        storeChangeObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: eventStore,
            queue: .main
        ) { [weak self] _ in
            print("System calendar store changed. Re-fetching calendars & events...")
            self?.updateAvailableCalendars()
        }
        
        // Listen to application becoming active (e.g. user clicked menu bar after changing settings)
        appActiveObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("App became active. Re-checking permission status...")
            self?.checkAuthStatus()
        }
    }
    
    private func setupPeriodicFetch() {
        // Fallback periodic fetch every 5 minutes in case system notifications are delayed
        periodicFetchTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            print("Performing periodic calendar update...")
            self?.fetchEvents()
        }
    }
}

