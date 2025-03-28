//
//  StreamUnary.swift
//  KurrentCore
//
//  Created by 卓俊諺 on 2025/1/20.
//

import GRPCCore
import GRPCEncapsulates
import GRPCNIOTransportHTTP2Posix

extension StreamUnary where Transport == HTTP2ClientTransport.Posix {
    package func send(client: ServiceClient, metadata: Metadata, callOptions: CallOptions) async throws -> Response {
        try await send(client: client, request: request(metadata: metadata), callOptions: callOptions)
    }

    package func perform(settings: ClientSettings, callOptions: CallOptions) async throws(KurrentError) -> Response {
        let client = try GRPCClient(settings: settings)
        let metadata = Metadata(from: settings)
        
        return try await withRethrowingError(usage: #function) {
            return try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await client.runConnections()
                }
                let underlying = ServiceClient(wrapping: client)
                let response = try await send(client: underlying, metadata: metadata, callOptions: callOptions)
                client.beginGracefulShutdown()
                return response
            }
        }
        
    }
}
