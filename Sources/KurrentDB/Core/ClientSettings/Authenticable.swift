//
//  Authenticable.swift
//  KurrentDB-Swift
//
//  Created by Grady Zhuo on 2025/6/17.
//

import GRPCEncapsulates

public protocol Authenticable {
    var authentication: Authentication? { set get }
}

extension Authenticable where Self: Buildable{
    @discardableResult
    public func authenticated(_ authentication: Authentication) -> Self {
        withCopy {
            $0.authentication = authentication
        }
    }
}
