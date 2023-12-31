//
//  File.swift
//  
//
//  Created by Asiel Cabrera Gonzalez on 12/31/23.
//

import XCTest
@testable import Cardinal_System

final class EventManagerTest: XCTestCase {
    struct TestEvent: Event {
        var id: UUID
        var name: String
        var description: String
 
    }
    
    func testCreateEvent() {
        var eventManager = EventManager()
        let id = UUID()
        let event = TestEvent(id: id, name: "testEvent", description: "Event for testing proporses")
        eventManager.createEvent(event)
        XCTAssertEqual(eventManager.getAllEvent().count, 1)
        XCTAssertEqual(eventManager.getEvent(id)?.name, "testEvent")
    }
}
