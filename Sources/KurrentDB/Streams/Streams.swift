//
//  Streams.swift
//  KurrentStreams
//
//  Created by Grady Zhuo on 2023/10/17.
//

import Foundation
import GRPCCore
import GRPCEncapsulates
import GRPCNIOTransportHTTP2Posix
import Logging
import NIO

/// A generic gRPC service for handling event streams.
///
/// `Streams` is a concrete gRPC service that enables interaction with event streams through operations
/// such as appending, reading, subscribing, deleting, and managing metadata.
///
/// The type parameter `Target` determines the scope of the stream, allowing either a specific stream
/// (`SpecifiedStream`) or all streams (`AllStreams`).
///
/// ## Usage
///
/// Creating a client for a specified stream:
/// ```swift
/// let specifiedStream = Streams(stream: StreamTarget.specified("log.txt"), settings: clientSettings)
/// try await specifiedStream.append(events: [event])
/// ```
///
/// Creating a client for all streams:
/// ```swift
/// let allStreams = Streams(stream: StreamTarget.all, settings: clientSettings)
/// try await allStreams.read(cursor: .start)
/// ```
///
/// - Note: This service relies on **gRPC** and requires a valid `ClientSettings` configuration.
///
/// ### Topics
/// #### Specific Stream Operations
/// - ``setMetadata(metadata:)``
/// - ``getMetadata(cursor:)``
/// - ``append(events:options:)``
/// - ``read(cursor:options:)``
/// - ``subscribe(from:options:)``
/// - ``delete(options:)``
/// - ``tombstone(options:)``
///
/// #### All Streams Operations
/// - ``read(cursor:options:)-6h8h2``
/// - ``subscribe(from:options:)-9gq2e``
public struct Streams<Target: StreamTarget>: GRPCConcreteService {
    
    /// The underlying client type used for gRPC communication.
    package typealias UnderlyingClient = EventStore_Client_Streams_Streams.Client<HTTP2ClientTransport.Posix>

    /// The client settings required for establishing a gRPC connection.
    public let settings: ClientSettings
    
    /// The gRPC call options.
    public let callOptions: CallOptions
    
    /// The event loop group handling asynchronous tasks.
    public let eventLoopGroup: EventLoopGroup
    
    /// The target stream, which can be either a specific stream or all streams.
    public let target: Target

    /// Initializes a `Streams` instance with the given target and settings.
    ///
    /// - Parameters:
    ///   - target: The stream target, either `SpecifiedStream` or `AllStreams`.
    ///   - settings: The client settings for gRPC communication.
    ///   - callOptions: The gRPC call options, defaulting to `.defaults`.
    ///   - eventLoopGroup: The event loop group, defaulting to a shared multi-threaded group.
    internal init(target: Target, settings: ClientSettings, callOptions: CallOptions = .defaults, eventLoopGroup: EventLoopGroup = .singletonMultiThreadedEventLoopGroup) {
        self.target = target
        self.settings = settings
        self.callOptions = callOptions
        self.eventLoopGroup = eventLoopGroup
    }
}

// MARK: - Specified Stream Operations
/// Extension providing operations for specific streams.
extension Streams where Target: SpecifiedStreamTarget {
    
    /// The identifier of the specific stream.
    public var identifier: StreamIdentifier {
        get {
            target.identifier
        }
    }

    /// Sets metadata for the specified stream.
    ///
    /// - Parameter metadata: The metadata to associate with the stream.
    /// - Returns: An `Append.Response` indicating the result of the operation.
    /// - Throws: An error if the operation fails.
    @discardableResult
    public func setMetadata(metadata: StreamMetadata) async throws -> Append.Response {
        let usecase = Append(to: .init(name: "$$\(identifier.name)"), events: [
            .init(
                eventType: "$metadata",
                payload: metadata
            )
        ], options: .init())
        return try await usecase.perform(settings: settings, callOptions: callOptions)
    }

    /// Retrieves the metadata associated with the specified stream.
    ///
    /// - Parameter cursor: The position in the stream from which to retrieve metadata, defaulting to `.end`.
    /// - Returns: The `StreamMetadata` if available, otherwise `nil`.
    /// - Throws: An error if the metadata cannot be retrieved or parsed.
    @discardableResult
    public func getMetadata(cursor: Cursor<CursorPointer> = .end) async throws -> StreamMetadata? {
        let usecase = Read(from: .init(name: "$$\(identifier.name)"), cursor: cursor, options: .init())
        let responses = try await usecase.perform(settings: settings, callOptions: callOptions)

        return try await responses.first {
            if case .event = $0 { return true }
            return false
        }.flatMap {
            switch $0 {
            case let .event(event):
                switch event.record.contentType {
                case .json:
                    try JSONDecoder().decode(StreamMetadata.self, from: event.record.data)
                default:
                    throw ClientError.eventDataError(message: "The event data could not be parsed. Stream metadata must be encoded in JSON format.")
                }
            default:
                throw ClientError.readResponseError(message: "The metadata event does not exist.")
            }
        }
    }

    /// Appends a list of events to the specified stream.
    ///
    /// - Parameters:
    ///   - events: An array of events to append.
    ///   - options: Options for appending events, defaulting to an empty configuration.
    /// - Returns: An `Append.Response` indicating the result of the operation.
    /// - Throws: An error if the append operation fails.
    @discardableResult
    public func append(events: [EventData], options: Append.Options = .init()) async throws -> Append.Response {
        let usecase = Append(to: identifier, events: events, options: options)
        return try await usecase.perform(settings: settings, callOptions: callOptions)
    }
    
    /// Appends a variadic list of events to the specified stream.
    ///
    /// - Parameters:
    ///   - events: A variadic list of events to append.
    ///   - options: Options for appending events, defaulting to an empty configuration.
    /// - Returns: An `Append.Response` indicating the result of the operation.
    /// - Throws: An error if the append operation fails.
    public func append(events: EventData..., options: Append.Options = .init()) async throws -> Append.Response {
        return try await append(events: events, options: options)
    }

    /// Reads events from the specified stream.
    ///
    /// - Parameters:
    ///   - cursor: The position in the stream from which to read.
    ///   - options: Options for reading events, defaulting to an empty configuration.
    /// - Returns: An asynchronous stream of `Read.Response` values.
    /// - Throws: An error if the read operation fails.
    public func read(cursor: Cursor<CursorPointer>, options: Read.Options = .init()) async throws -> AsyncThrowingStream<Read.Response, Error> {
        let usecase = Read(from: identifier, cursor: cursor, options: options)
        return try await usecase.perform(settings: settings, callOptions: callOptions)
    }
    
    /// Reads events from the specified stream starting at a given revision.
    ///
    /// - Parameters:
    ///   - revision: The revision of the stream to start reading from.
    ///   - direction: The direction to read (forward or backward).
    ///   - options: Options for reading events, defaulting to an empty configuration.
    /// - Returns: An asynchronous stream of `Read.Response` values.
    /// - Throws: An error if the read operation fails.
    public func read(from revision: UInt64, directTo direction: Direction, options: Read.Options = .init()) async throws -> AsyncThrowingStream<Read.Response, Error> {
        return try await read(cursor: .specified(.init(revision: revision, direction: direction)), options: options)
    }
    
    /// Subscribes to events from the specified stream.
    ///
    /// - Parameters:
    ///   - cursor: The position in the stream from which to start subscribing.
    ///   - options: Options for subscribing, defaulting to an empty configuration.
    /// - Returns: A `Subscription` instance for receiving events.
    /// - Throws: An error if the subscription fails.
    public func subscribe(from cursor: Cursor<StreamRevision>, options: Subscribe.Options = .init()) async throws -> Subscription {
        let usecase = Subscribe(from: identifier, cursor: cursor, options: options)
        return try await usecase.perform(settings: settings, callOptions: callOptions)
    }
    
    /// Subscribes to events from the specified stream starting at a given revision.
    ///
    /// - Parameters:
    ///   - revision: The revision of the stream to start subscribing from.
    ///   - options: Options for subscribing, defaulting to an empty configuration.
    /// - Returns: A `Subscription` instance for receiving events.
    /// - Throws: An error if the subscription fails.
    public func subscribe(from revision: UInt64, options: Subscribe.Options = .init()) async throws -> Subscription {
        return try await subscribe(from: .specified(.init(value: revision)), options: options)
    }

    /// Deletes the specified stream.
    ///
    /// - Parameter options: Options for deleting the stream, defaulting to an empty configuration.
    /// - Returns: A `Delete.Response` indicating the result of the operation.
    /// - Throws: An error if the delete operation fails.
    @discardableResult
    public func delete(options: Delete.Options = .init()) async throws -> Delete.Response {
        let usecase = Delete(to: identifier, options: options)
        return try await usecase.perform(settings: settings, callOptions: callOptions)
    }

    /// Marks the specified stream as permanently deleted (tombstoned).
    ///
    /// - Parameter options: Options for tombstoning the stream, defaulting to an empty configuration.
    /// - Returns: A `Tombstone.Response` indicating the result of the operation.
    /// - Throws: An error if the tombstone operation fails.
    @discardableResult
    public func tombstone(options: Tombstone.Options = .init()) async throws -> Tombstone.Response {
        let usecase = Tombstone(to: identifier, options: options)
        return try await usecase.perform(settings: settings, callOptions: callOptions)
    }
}

/// Extension providing operations for projection streams.
extension Streams where Target == ProjectionStream {
    
    /// The identifier of the projection stream.
    public var identifier: StreamIdentifier {
        get {
            target.identifier
        }
    }

    /// Subscribes to events from the projection stream.
    ///
    /// - Parameters:
    ///   - cursor: The position in the stream from which to start subscribing.
    ///   - options: Options for subscribing, defaulting to an empty configuration.
    /// - Returns: A `Subscription` instance for receiving events.
    /// - Throws: An error if the subscription fails.
    public func subscribe(from cursor: Cursor<StreamRevision>, options: Subscribe.Options = .init()) async throws -> Subscription {
        let usecase = Subscribe(from: identifier, cursor: cursor, options: options)
        return try await usecase.perform(settings: settings, callOptions: callOptions)
    }
    
    /// Subscribes to events from the projection stream starting at a given revision.
    ///
    /// - Parameters:
    ///   - revision: The revision of the stream to start subscribing from.
    ///   - options: Options for subscribing, defaulting to an empty configuration.
    /// - Returns: A `Subscription` instance for receiving events.
    /// - Throws: An error if the subscription fails.
    public func subscribe(from revision: UInt64, options: Subscribe.Options = .init()) async throws -> Subscription {
        return try await subscribe(from: .specified(.init(value: revision)), options: options)
    }
}

// MARK: - All Streams Operations
/// Extension providing operations for all streams.
extension Streams where Target == AllStreams {

    /// Reads events from all available streams.
    ///
    /// - Parameters:
    ///   - cursor: The position from which to start reading.
    ///   - options: Options for reading events, defaulting to an empty configuration.
    /// - Returns: An asynchronous stream of `ReadAll.Response` values.
    /// - Throws: An error if the read operation fails.
    public func read(cursor: Cursor<ReadAll.CursorPointer>, options: ReadAll.Options = .init()) async throws -> AsyncThrowingStream<ReadAll.Response, Error> {
        let usecase = ReadAll(cursor: cursor, options: options)
        return try await usecase.perform(settings: settings, callOptions: callOptions)
    }

    /// Reads events from a specified position and direction in all streams.
    ///
    /// - Parameters:
    ///   - position: The starting position in the stream.
    ///   - direction: The reading direction (forward or backward).
    ///   - options: Options for reading events, defaulting to an empty configuration.
    /// - Returns: An asynchronous stream of `ReadAll.Response` values.
    /// - Throws: An error if the read operation fails.
    public func read(from position: StreamPosition, directTo direction: Direction, options: ReadAll.Options = .init()) async throws -> AsyncThrowingStream<ReadAll.Response, Error> {
        try await read(cursor: .specified(.init(position: position, direction: direction)), options: options)
    }

    /// Subscribes to all streams from a specified position.
    ///
    /// - Parameters:
    ///   - cursor: The position from which to start subscribing.
    ///   - options: Options for subscribing, defaulting to an empty configuration.
    /// - Returns: A `Streams.Subscription` instance for receiving events.
    /// - Throws: An error if the subscription fails.
    public func subscribe(from cursor: Cursor<StreamPosition>, options: SubscribeAll.Options = .init()) async throws -> Streams.Subscription {
        let usecase = SubscribeAll(cursor: cursor, options: options)
        return try await usecase.perform(settings: settings, callOptions: callOptions)
    }
}
