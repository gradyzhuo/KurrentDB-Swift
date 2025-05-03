//
//  Gossip.Read.swift
//  KurrentGossip
//
//  Created by Grady Zhuo on 2023/12/19.
//

import Foundation
import GRPCCore
import GRPCEncapsulates

extension ServerFeatures {
    public struct GetSupportedMethods: UnaryUnary {
        package typealias ServiceClient = UnderlyingClient
        package typealias UnderlyingRequest = ServiceClient.UnderlyingService.Method.GetSupportedMethods.Input
        package typealias UnderlyingResponse = ServiceClient.UnderlyingService.Method.GetSupportedMethods.Output
        public typealias Response = ServiceInfo

        package func send(connection: GRPCClient<Transport>, request: ClientRequest<UnderlyingRequest>, callOptions: CallOptions) async throws -> Response {
            let client = ServiceClient(wrapping: connection)
            return try await client.getSupportedMethods(request: request, options: callOptions) {
                return try .init(
                    serverVersion: $0.message.eventStoreServerVersion,
                    supportedMethods: $0.message.methods.map{
                        .init(
                            methodName: $0.methodName,
                            serviceName: $0.serviceName,
                            features: $0.features)
                    })
            }
        }
    }
}

