//
//  Information.swift
//
//
//  Created by Asiel Cabrera Gonzalez on 1/2/24.
//

import Foundation
 
public protocol Information {
    var id: UUID { get }
    var name: String { get }
    var description: String { get }
}
