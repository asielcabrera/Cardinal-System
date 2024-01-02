//
//  Action.swift
//
//
//  Created by Asiel Cabrera Gonzalez on 1/2/24.
//

import Foundation

public protocol Action {
    associatedtype T: Event
    static func execute(_ event: T) async throws
}
