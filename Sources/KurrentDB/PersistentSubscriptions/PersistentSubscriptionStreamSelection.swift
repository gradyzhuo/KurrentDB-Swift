//
//  PersistentSubscriptionStreamSelection.swift
//  KurrentDB-Swift
//
//  Created by Grady Zhuo on 2025/3/30.
//

import GRPCEncapsulates
import SwiftProtobuf

public protocol PersistentSubscriptionStreamSelection: Sendable {
    associatedtype Cursor: Sendable
    var streamIdentifier: StreamIdentifier { get }
}

extension PersistentSubscriptionStreamSelection where Self == PersistentSubscriptionSpecifiedStream {
    public static func specified(_ streamIdentifier: StreamIdentifier) -> Self {
        .init(streamIdentifier: streamIdentifier)
    }
}

extension PersistentSubscriptionStreamSelection where Self == PersistentSubscriptionStreamAll {
    public static var all: Self {
        .init()
    }
}

public struct PersistentSubscriptionSpecifiedStream: PersistentSubscriptionStreamSelection {
    public typealias Cursor = RevisionCursor
    public let streamIdentifier: StreamIdentifier

    package init(streamIdentifier: StreamIdentifier) {
        self.streamIdentifier = streamIdentifier
    }
}

public struct PersistentSubscriptionStreamAll: PersistentSubscriptionStreamSelection {
    public typealias Cursor = PositionCursor
    public var streamIdentifier: StreamIdentifier {
        .all
    }
}
