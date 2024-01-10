//
//  EventManager.swift
//
//
//  Created by Asiel Cabrera Gonzalez on 12/31/23.
//

import Foundation

public struct EventManager {
    
    private var events: [Event] = []
    private var observers: [Listener] = []
    
    public init() {}
    public mutating func createEvent(_ event: Event) {
        events.append(event)
        notififyObservers(event)
    }
    
    public func getEvent(_ id: UUID) -> Event? {
        events.first { $0.id == id }
    }
    
    public func getAllEvent() -> [Event] {
        return events
    }
    
    public func getEventsByType<T: Event>(_ type: T.Type) -> [Event] {
        return events.filter { $0 is T }
    }
    
    mutating func removeEvent(_ id: UUID) {
        events.removeAll { $0.id == id }
    }
    
    func notififyObservers(_ event: Event) {
        observers.forEach { $0.handleEvent(event) }
    }
    
    func notifyObserverOfEvent<T: Listener>(_ type: T.Type, event: Event) {
        let filteredObservers: [Listener] = observers.filter { $0 is T }
        filteredObservers.forEach { $0.handleEvent(event) }
    }
    
    public mutating func addObserver(_ observer: Listener) {
        observers.append(observer)
    }
    mutating func removeEventObserver(_ id: UUID) {
        observers.removeAll { $0.id == id }
    }
}
