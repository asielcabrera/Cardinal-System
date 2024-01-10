//
//  Cardinal.swift
//
//
//  Created by Asiel Cabrera Gonzalez on 1/6/24.
//

import Foundation

public protocol Cardinal {
    associatedtype CardinalApplication = Application
    
    static var application: CardinalApplication { get set }
    
    static func run() async throws
}


public extension Cardinal {
    static func main() async throws {
        try await run()
    }
    
    static func excutableServer() async throws {
        var server = try WebSocketServer()
        try server.start()
        try server.waitForShutdown()
    }
}
