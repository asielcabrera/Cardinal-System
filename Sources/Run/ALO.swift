//
//  ALO.swift
//
//
//  Created by Asiel Cabrera Gonzalez on 1/6/24.
//

import Cardinal_System
import Foundation

@main
struct ALO: Cardinal {
    
    struct App: Application {
        var name: String = "ALO"
    }
    
    static var application = App()
    static func run() async throws {
        print("Hola desde ALO")
        
        let event = PrintEvent(action: { AllWebSockets.sockets.forEach { socket in
            socket.sendText("{'id': '\(UUID.init())', 'name': '\(PrintEvent.self)', 'time': '\(Date().description)'}")
        }})
        
        ActionExecutor.registerAction(PrintAction())
        ActionExecutor.registerAction(LogAction())
        ActionExecutor.registerAction(ExampleAction())
//        try await ActionExecutor.notifyActions(event)
//        try await ActionExecutor.notifyActions(event)
        
        try await Self.excutableServer()
    }
}

