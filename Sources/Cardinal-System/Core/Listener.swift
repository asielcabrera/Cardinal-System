//
//  EventObserver.swift
//
//
//  Created by Asiel Cabrera Gonzalez on 12/31/23.
//

import Foundation

public protocol Listener: Information {
    func handleEvent(_ event: Event)
}
