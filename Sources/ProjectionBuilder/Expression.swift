//
//  Expression.swift
//  KurrentDB-Swift
//
//  Created by Grady Zhuo on 2025/5/8.
//


public struct Expression {
    let content: String
}

extension Expression: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    
    public init(stringLiteral value: String) {
        self.init(content: value)
    }
}

extension Expression: Equatable {
    
}
