//
//  PersistentSubscriptionsClient.CreateToStream.swift
//  KurrentPersistentSubscriptions
//
//  Created by 卓俊諺 on 2025/1/12.
//
import GRPCCore
import GRPCEncapsulates

extension PersistentSubscriptions {
    public struct CreateToStream: UnaryUnary {
        package typealias ServiceClient = UnderlyingClient
        package typealias UnderlyingRequest = UnderlyingService.Method.Create.Input
        package typealias UnderlyingResponse = UnderlyingService.Method.Create.Output
        package typealias Response = DiscardedResponse<UnderlyingResponse>

        var streamIdentifier: StreamIdentifier
        var group: String
        var options: Options

        public init(streamIdentifier: StreamIdentifier, group: String, options: Options) {
            self.streamIdentifier = streamIdentifier
            self.group = group
            self.options = options
        }

        package func requestMessage() throws -> UnderlyingRequest {
            try .with {
                $0.options = options.build()
                $0.options.groupName = group
                $0.options.stream.streamIdentifier = try streamIdentifier.build()
            }
        }

        package func send(client: UnderlyingClient, request: ClientRequest<UnderlyingRequest>, callOptions: CallOptions) async throws -> Response {
            try await client.create(request: request, options: callOptions) {
                try handle(response: $0)
            }
        }
    }
}

extension PersistentSubscriptions.CreateToStream {
    public struct Options: PersistentSubscriptionsCommonOptions {
        package typealias UnderlyingMessage = UnderlyingRequest.Options

        public var settings: PersistentSubscription.Settings
        public var cursor: RevisionCursor

        public init(settings: PersistentSubscription.Settings = .init(), from cursor: RevisionCursor = .end) {
            self.settings = settings
            self.cursor = cursor
        }

        @discardableResult
        public func startFrom(_ cursor: RevisionCursor) -> Self {
            withCopy { options in
                options.cursor = cursor
            }
        }

        @discardableResult
        public mutating func set(consumerStrategy: PersistentSubscription.SystemConsumerStrategy) -> Self {
            withCopy { options in
                options.settings.consumerStrategy = consumerStrategy
            }
        }

        package func build() -> UnderlyingMessage {
            .with {
                $0.settings = .make(settings: settings)

                switch cursor {
                case .start:
                    $0.stream.start = .init()
                case .end:
                    $0.stream.end = .init()
                case let .revision(revision):
                    $0.stream.revision = revision
                }
            }
        }
    }
}
