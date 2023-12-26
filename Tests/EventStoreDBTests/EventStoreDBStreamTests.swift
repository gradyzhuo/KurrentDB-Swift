//
//  EventStoreDBStreamTests.swift
//  
//
//  Created by Ospark.org on 2023/10/28.
//

import XCTest
@testable import EventStoreDB
import GRPC
import NIO

enum TestingError: Error {
    case exception(String)
}


final class EventStoreDBStreamTests: XCTestCase {
    var streamIdentifier: EventStoreDB.StreamClient.Identifier!
    
    var eventId: UUID!
    
    override func setUpWithError() throws {
        var settings: ClientSettings = "esdb://admin:changeit@localhost:2111,localhost:2112,localhost:2113?keepAliveTimeout=10000&keepAliveInterval=10000"
        settings.configuration.trustRoots = .file("/Users/gradyzhuo/Library/CloudStorage/Dropbox/Work/jw/mendesky/EventStore/samples/server/certs/ca/ca.crt")
        
        
        try EventStoreDB.using(settings: settings)
        streamIdentifier = "testing"
        eventId = .init()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    

    func testAppendEvent() async throws{
        let content: [String: String] = ["name": "Event1"]
        let stream = try StreamClient.init(identifier: streamIdentifier)
        let appendResponse = try await stream.append(id: eventId, type: "AccountCreated", content: content){
            $0.expected(revision: .any)
        }
        guard let rev = appendResponse.current.revision else {
            throw TestingError.exception("should not be no stream.")
        }
        
        //Check the event is appended into testing stream.
        let readResponses = try stream.read(at: rev) { options in
            options.set(uuidOption: .string)
                .countBy(limit: 1)
        }

        let result = try await readResponses.first {
            switch $0.content {
            case .event(let event):
                return event.event.id == eventId
            default:
                throw TestingError.exception("no read event data.")
            }
        }
        
        XCTAssertNotNil(result)
    }

    

}
