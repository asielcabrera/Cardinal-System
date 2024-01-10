//
//  PrintAction.swift
//
//
//  Created by Asiel Cabrera Gonzalez on 1/6/24.
//

import Cardinal_System

struct PrintAction: CardinalAction {
    var eventAssociated: Event.Type = PrintEvent.self
    
    func execute(_ event: Event) {
        event.action()
    }
}

