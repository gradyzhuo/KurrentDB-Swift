//
//  StreamClient.Subscription.swift
//
//
//  Created by Grady Zhuo on 2024/3/23.
//

import KurrentCore
import GRPCCore
import GRPCEncapsulates
import SwiftProtobuf

extension Streams {
    public final class Subscription {
        public let events: AsyncThrowingStream<ReadEvent, Error>
        public let subscriptionId: String?
        
        package init(messages: AsyncThrowingStream<Streams.Subscribe.UnderlyingResponse, any Error>) async throws {
            
            var iterator = messages.makeAsyncIterator()
            
            subscriptionId = if case let .confirmation(confirmation) = try await iterator.next()?.content{
                confirmation.subscriptionID
            }else{
                nil
            }
            
            let (stream, continuation) = AsyncThrowingStream.makeStream(of: ReadEvent.self)
            Task{
                while let message = try await iterator.next() {
                    if case let .event(message) = message.content {
                        try continuation.yield(.init(message: message))
                    }
                }
            }
            events = stream
        }
    }
}
