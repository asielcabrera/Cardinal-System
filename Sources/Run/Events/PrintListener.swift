//
//  PrintListener.swift
//
//
//  Created by Asiel Cabrera Gonzalez on 1/6/24.
//

import Foundation
import Cardinal_System


class PrintListener: Listener {

   func handleEvent(_ event: Event) {
       event.action()
   }
   
   var id: UUID
   
   var name: String = "PrintEventListener"
   
   var description: String = "Listener que escucha porque se dispare un event de hacer print"
   
   init() {
       self.id = .init()
   }
}
