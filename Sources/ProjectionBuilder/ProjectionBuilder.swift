//
//  ProjectionBuilder.swift
//  KurrentDB-Swift
//
//  Created by Grady Zhuo on 2025/5/8.
//
import Foundation
import KurrentDB

public enum FromSource {
    case streams([String])
}

public struct ProjectionBuilder {
    let source: FromSource
    
    public init(streams: [StreamIdentifier]){
        self.init(streams: streams.map(\.name))
    }
    
    public init(streams: [String]){
        self.source = .streams(streams)
    }
    
    public func build() throws -> [Expression] {
        var expressions: [Expression] = []
        switch source {
        case .streams(let streamNames):
            expressions.append(
                .init(content: "fromStreams([\(streamNames.map{ "\"\($0)\"" }.joined(separator: ","))])")
            )
        }
        return expressions
    }
}
