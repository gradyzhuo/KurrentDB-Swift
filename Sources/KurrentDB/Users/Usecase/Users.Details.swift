//
//  Users.Details.swift
//  KurrentUsers
//
//  Created by Grady Zhuo on 2023/12/20.
//

import Foundation
import GRPCCore
import GRPCEncapsulates
import GRPCNIOTransportHTTP2Posix

extension Users {
    public struct Details: UnaryStream {
        package typealias ServiceClient = UnderlyingClient
        package typealias UnderlyingRequest = ServiceClient.UnderlyingService.Method.Details.Input
        package typealias UnderlyingResponse = ServiceClient.UnderlyingService.Method.Details.Output
        package typealias Responses = AsyncThrowingStream<UserDetails, any Error>

        public let loginName: String

        public init(loginName: String) {
            self.loginName = loginName
        }

        package func requestMessage() throws -> UnderlyingRequest {
            .with {
                $0.options.loginName = loginName
            }
        }

        package func send(client: ServiceClient, request: ClientRequest<UnderlyingRequest>, callOptions: CallOptions) async throws -> Responses {
            try await withThrowingTaskGroup(of: Void.self) { _ in
                let (stream, continuation) = AsyncThrowingStream.makeStream(of: UserDetails.self)
                try await client.details(request: request, options: callOptions) {
                    for try await message in $0.messages {
                        let response = try handle(message: message)
                        continuation.yield(response.userDetails)
                    }
                    continuation.finish()
                }
                
                return stream
            }
        }
    }
}

extension Users.Details {
    public struct Response: GRPCResponse {
        package typealias UnderlyingMessage = UnderlyingResponse

        let userDetails: UserDetails

        package init(from message: UnderlyingMessage) throws {
            userDetails = try .init(from: message.userDetails)
        }
    }
}
