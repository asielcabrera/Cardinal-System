//
//  CardinalServerTest.swift
//
//
//  Created by Asiel Cabrera Gonzalez on 12/31/23.
//

import XCTest
@testable import Cardinal_System

final class CardinalServerTest: XCTestCase {

    struct ALO: Cardinal {
 
        struct App: Application {
            var name: String
        }
        static var application: App = App(name: "ALO")
        
        static func run() async throws {
             
        }
    }
}
