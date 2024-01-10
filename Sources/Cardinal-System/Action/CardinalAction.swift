//
//  CardinalAction.swift
//
//
//  Created by Asiel Cabrera Gonzalez on 1/2/24.
//

import Foundation

public protocol CardinalAction {
    var eventAssociated: any Event.Type { get set }
    func execute(_ event: Event) 
}
