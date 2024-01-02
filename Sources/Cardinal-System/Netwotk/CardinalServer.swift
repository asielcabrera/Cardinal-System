//
//  Server.swift
//  
//
//  Created by Asiel Cabrera Gonzalez on 12/31/23.
//

import Vapor


public protocol CardinalServer {
    var eventManager: EventManager { get }
    var websocketManager: WebsocketManager { get }
    var applicacion: Application { get }
    
     static func execute() async throws
}

public extension CardinalServer {
    static func run() async throws {
        try await execute()
    }
}
