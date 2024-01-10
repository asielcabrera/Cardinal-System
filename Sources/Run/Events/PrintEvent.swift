//
//  PrintEvent.swift
//
//
//  Created by Asiel Cabrera Gonzalez on 1/6/24.
//

import Cardinal_System
import Foundation

class PrintEvent: Event {
    var id: UUID
    
    var name: String = "PrintEvent"
    
    var description: String = "Evento para pruebas de hacer print en consola"
    
    var action: () -> Void
    
    init(action: @escaping () -> Void) {
        self.id = .init()
        self.action = action
    }
    
}
