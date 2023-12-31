//
//  Event.swift
//
//
//  Created by Asiel Cabrera Gonzalez on 12/31/23.
//

import Foundation

public protocol Event {
    var id: UUID { get }
    var name: String { get }
    var description: String { get } 
}
