//
//  LogAction.swift
//
//
//  Created by Asiel Cabrera Gonzalez on 1/6/24.
//

import Foundation
import Cardinal_System

struct LogAction: CardinalAction {
    var eventAssociated: Event.Type = PrintEvent.self
    
    func execute(_ event: Event) {
        print(event.name)
    }
}
