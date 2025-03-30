//
//  StreamIdentifier.swift
//  KurrentCore
//
//  Created by Grady Zhuo on 2024/5/21.
//

import Foundation
import GRPCEncapsulates

public struct StreamIdentifier: Sendable {
    package typealias UnderlyingMessage = EventStore_Client_StreamIdentifier

    public let name: String
    public var encoding: String.Encoding

    public init(name: String, encoding: String.Encoding = .utf8) {
        self.name = name
        self.encoding = encoding
    }
}

extension StreamIdentifier: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String

    public init(stringLiteral value: String) {
        self.init(name: value)
    }
}

extension StreamIdentifier: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.name == rhs.name && lhs.encoding == rhs.encoding
    }
}

extension StreamIdentifier {
    package func build() throws(KurrentError) -> UnderlyingMessage {
        guard let streamName = name.data(using: encoding) else {
            throw .internalParsingError(reason: "name coding error: \(name), encoding: \(encoding)")
        }

        return .with {
            $0.streamName = streamName
        }
    }
}

extension StreamIdentifier {
    public static var all: Self {
        get{
            .init(name: "$all")
        }
    }
}
