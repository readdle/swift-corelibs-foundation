//
//  NSLocking+Readdle.swift
//  SparkCore
//
//  Created by Anton Pogonets on 05.05.17.
//  Copyright © 2017 Readdle. All rights reserved.
//

import Foundation

public extension NSLocking {
    
    @discardableResult
    func sync<T>(execute work: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        
        return try work()
    }
}
