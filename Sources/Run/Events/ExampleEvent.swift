//
//  ExampleEvent.swift
//
//
//  Created by Asiel Cabrera Gonzalez on 1/6/24.
//

import Foundation
import Cardinal_System

struct ExampleEvent: Event {
    var id: UUID
    
    var name: String = "ExampleEvent"
    
    var description: String = "Evento para pruebas"
    
    var action: () -> Void
    
    init(action: @escaping () -> Void) {
        self.id = .init()
        self.action = action
    }
    
    
}
