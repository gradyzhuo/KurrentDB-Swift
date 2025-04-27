//
//  UnaryUnary.swift
//  GRPCEncapsulates
//
//  Created by 卓俊諺 on 2025/1/20.
//

import GRPCCore

package protocol UnaryUnary: Usecase, UnaryRequestBuildable, UnaryResponseHandlable {
    func send(connection: GRPCClient<Transport>, request: ClientRequest<UnderlyingRequest>, callOptions: CallOptions) async throws -> Response
}
