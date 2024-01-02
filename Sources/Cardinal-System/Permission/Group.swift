//
//  Group.swift
//
//
//  Created by Asiel Cabrera Gonzalez on 1/2/24.
//

import Foundation

public protocol Group: Information {
    var entities: [Entity] { get set }
}
