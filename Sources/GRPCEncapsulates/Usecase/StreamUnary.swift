//
//  StreamUnary.swift
//  GRPCEncapsulates
//
//  Created by 卓俊諺 on 2025/1/20.
//

import GRPCCore

package protocol StreamUnary: Usecase, StreamRequestBuildable, UnaryResponseHandlable {
    func send(connection: GRPCClient<Transport>, request: StreamingClientRequest<UnderlyingRequest>, callOptions: CallOptions) async throws -> Response
}
