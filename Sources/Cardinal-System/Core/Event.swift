//
//  Event.swift
//
//
//  Created by Asiel Cabrera Gonzalez on 12/31/23.
//

import Foundation

public protocol Event: Information { 
    var action: () -> Void { get }
}

