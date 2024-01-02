//
//  ConfigStorate.swift
//
//
//  Created by Asiel Cabrera Gonzalez on 1/2/24.
//

import Foundation
import Yams

public struct ConfigStorate: Storage {
    public var id: UUID = .init()
    
    public var name: String = "Config Storage"
    
    public var description: String = "Configuration storage system"

    public static func decode<T: Decodable>(fromFile file: String, as type: T.Type) throws -> T {
        let url = URL(fileURLWithPath: file)
        let data = try Data(contentsOf: url)
        return try YAMLDecoder().decode(T.self, from: data)
    }
    
    public static func encode<T: Encodable>(_ value: T, toFile file: String) throws {
        let data = try YAMLEncoder().encode(value)
        try data.write(toFile: file, atomically: true, encoding: .utf8)
    }
}
