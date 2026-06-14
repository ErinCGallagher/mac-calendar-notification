import Foundation
import EventKit
import Observation

@Observable
class CalendarManager {
    private let eventStore = EKEventStore()
    var events: [EKEvent] = []
    
    init() {
        requestAccess()
    }
    
    func requestAccess() {
        // In macOS 14.0+, use requestFullAccessToEvents
        // For compatibility with 13.0 (though deployment target is 26.5, good for robust code), we use requestAccess(to: .event)
        if #available(macOS 14.0, *) {
            eventStore.requestFullAccessToEvents { [weak self] granted, error in
                if granted {
                    self?.fetchEvents()
                } else if let error = error {
                    print("Error requesting calendar access: \(error.localizedDescription)")
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { [weak self] granted, error in
                if granted {
                    self?.fetchEvents()
                } else if let error = error {
                    print("Error requesting calendar access: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func fetchEvents() {
        let calendars = eventStore.calendars(for: .event)
        
        let now = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        
        let predicate = eventStore.predicateForEvents(withStart: now, end: tomorrow, calendars: calendars)
        
        let fetchedEvents = eventStore.events(matching: predicate)
        
        DispatchQueue.main.async {
            self.events = fetchedEvents.sorted { $0.startDate < $1.startDate }
            print("Fetched \(self.events.count) events:")
            for event in self.events {
                print("- \(event.title ?? "Untitled") at \(event.startDate!)")
            }
        }
    }
}
