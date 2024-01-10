//
//  ActionExecutor.swift
//
//
//  Created by Asiel Cabrera Gonzalez on 1/6/24.
//

import Foundation


public struct ActionExecutor {
    
    private static var actions: [CardinalAction] = []
    public init() {}
    
    public static func notifyActions(_ event: Event) {
        
        let filteredActions = actions.filter { $0.eventAssociated == type(of: event.self) }
        
        for action in filteredActions {
            action.execute(event)
        }
    }
    
    public static func registerAction(_ action: CardinalAction) {
        actions.append(action)
    }
}
