//
//  ProjectionBuilderTests.swift
//  KurrentDB-Swift
//
//  Created by Grady Zhuo on 2025/5/8.
//

import Testing
@testable import ProjectionBuilder

@Suite
struct ProjectionBuilderTests {
    
    
    @Test
    func testFromStreams() throws {
        let target: [Expression] = ["fromStreams([\"$ce-QuotingCase\"])"]
        let builder = ProjectionBuilder(streams: ["$ce-QuotingCase"])
        let expressions = try builder.build()
        #expect(expressions == target)
    }
    
    @Test
    func test2() throws {
//        let target: [Expression] = ["fromStreams([\"$ce-QuotingCase\"])"]
//        let builder = ProjectionBuilder(streams: ["$ce-QuotingCase"])
//            .when(){
//                
//            }
//        let expressions = try builder.build()
//        #expect(expressions == target)
    }
}
