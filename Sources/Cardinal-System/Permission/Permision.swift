//
//  Permision.swift
//
//
//  Created by Asiel Cabrera Gonzalez on 12/31/23.
//

import Foundation

public protocol Permision: Information {
    var isActive: Bool { get set }
    var priotiry: Int { get set }
    var context: Context { get set }
}

