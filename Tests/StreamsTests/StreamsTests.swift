//
//  StreamsTests.swift
//  KurrentDB
//
//  Created by Grady Zhuo on 2023/10/28.
//

import Foundation
import Testing
@testable import KurrentDB

package enum TestingError: Error {
    case exception(String)
}

@Suite("EventStoreDB Stream Tests", .serialized)
struct StreamTests: Sendable {
    let settings: ClientSettings

    init() {
        settings = .localhost()
    }

    @Test("Stream should be not found and throw an error.")
    func testStreamNotFound() async throws {
        let client = KurrentDBClient(settings: .localhost())
        
        await #expect(throws: KurrentError.self) {
            let responses = try await client.readStream(on: StreamIdentifier(name: UUID().uuidString))
            var responsesIterator = responses.makeAsyncIterator()
            _ = try await responsesIterator.next()
        }
    }

    @Test("It should succeed when appending events to a stream.", arguments: [
        [
            EventData(eventType: "AppendEvent-AccountCreated", content: ["Description": "Gears of War 4"]),
            EventData(eventType: "AppendEvent-AccountDeleted", content: ["Description": "Gears of War 4"]),
        ],
    ])
    func testAppendEvent(events: [EventData]) async throws {
        let streamIdentifier = StreamIdentifier(name: UUID().uuidString)
        let client = KurrentDBClient(settings: .localhost())
        
        let appendResponse = try await client.appendStream(on: streamIdentifier, events: events) {
            $0.revision(expected: .any)
        }

        let appendedRevision = try #require(appendResponse.currentRevision)
        let readResponses = try await client.readStream(on: streamIdentifier, startFrom: .revision(appendedRevision)) {
            $0.forward()
        }

        let firstResponse = try await readResponses.first { _ in true }
        guard case let .event(readEvent) = firstResponse,
              let readPosition = readEvent.commitPosition,
              let position = appendResponse.position
        else {
            throw TestingError.exception("readResponse.content or appendResponse.position is not Event or Position")
        }
        
        #expect(readPosition == position)

        try await client.deleteStream(on: streamIdentifier)
    }

    @Test("It should succeed when setting metadata to a stream.")
    func testMetadata() async throws {
        let streamIdentifier = StreamIdentifier(name: UUID().uuidString)
        let metadata = StreamMetadata()
            .cacheControl(.seconds(3))
            .maxAge(.seconds(30))
            .acl(.userStream)

        let client = KurrentDBClient(settings: .localhost())
        
        try await client.setStreamMetadata(on: streamIdentifier, metadata: metadata)

        let responseMetadata = try #require(try await client.getStreamMetadata(on: streamIdentifier))
        #expect(metadata == responseMetadata)
        try await client.deleteStream(on: streamIdentifier)
    }

    @Test("It should succeed when subscribing to a stream.")
    func testSubscribe() async throws {
        let streamIdentifier = StreamIdentifier(name: UUID().uuidString)
        let client = KurrentDBClient(settings: .localhost())
        
        let subscription = try await client.subscribeStream(on: streamIdentifier)
        let response = try await client.appendStream(on: streamIdentifier, events: [
            .init(eventType: "Subscribe-AccountCreated", payload: ["Description": "Gears of War 10"])
        ]) {
            $0.revision(expected: .any)
        }

        var lastEvent: ReadEvent?
        for try await event in subscription.events {
            lastEvent = event
            break
        }

        let lastEventRevision = try #require(lastEvent?.record.revision)
        #expect(response.currentRevision == lastEventRevision)
        try await client.deleteStream(on: streamIdentifier)
    }

    @Test("It should succeed when subscribing to all streams.")
    func testSubscribeAll() async throws {
        let streamIdentifier = StreamIdentifier(name: UUID().uuidString)
        let eventForTesting = EventData(
            eventType: "SubscribeAll-AccountCreated", payload: ["Description": "Gears of War 10"]
        )
        let client = KurrentDBClient(settings: .localhost())
        
        let subscription = try await client.subscribeAllStreams(startFrom: .end){
            $0.filter(.onEventType(regex: "SubscribeAll-AccountCreated"))
        }
        let response = try await client.appendStream(on: streamIdentifier, events: [eventForTesting]) {
            $0.revision(expected: .any)
        }
        
        var lastEvent: ReadEvent?
        for try await event in subscription.events {
            if event.record.eventType == eventForTesting.eventType {
                lastEvent = event
                break
            }
        }

        let lastEventPosition = try #require(lastEvent?.record.position)
        #expect(response.position?.commit == lastEventPosition.commit)
        try await client.deleteStream(on: streamIdentifier)
    }
    
    @Test("It should succeed when subscribing to all streams with an event type filter.")
    func testSubscribeAllWithFilter() async throws {
        let streamIdentifier = StreamIdentifier(name: UUID().uuidString)
        let eventForTesting = EventData(
            eventType: "SubscribeAll-AccountCreated", payload: ["Description": "Gears of War 10"]
        )
        let client = KurrentDBClient(settings: .localhost())
        
        let filter: SubscriptionFilter = .onEventType(prefixes: "SubscribeAll-AccountCreated")
        let subscription = try await client.subscribeAllStreams(startFrom: .end) {
            $0.filter(filter)
        }
        
        let response = try await client.appendStream(on: streamIdentifier, events: [eventForTesting]) {
            $0.revision(expected: .any)
        }
        
        var lastEvent: ReadEvent?
        for try await event in subscription.events {
            lastEvent = event
            break
        }

        let lastEventPosition = try #require(lastEvent?.record.position)
        #expect(response.position?.commit == lastEventPosition.commit)
        try await client.deleteStream(on: streamIdentifier)
    }
    
    @Test("It should succeed when subscribing to all streams by excluding system events.")
    func testSubscribeAllExcludeSystemEvents() async throws {
        let streamIdentifier = StreamIdentifier(name: UUID().uuidString)
        let eventForTesting = EventData(
            eventType: "SubscribeAll-AccountCreated", payload: ["Description": "Gears of War 10"]
        )
        let client = KurrentDBClient(settings: .localhost())
        
        let filter: SubscriptionFilter = .excludeSystemEvents()
        let subscription = try await client.subscribeAllStreams(startFrom: .end) {
            $0.filter(filter)
        }
        
        let response = try await client.appendStream(on: streamIdentifier, events: [eventForTesting]) {
            $0.revision(expected: .any)
        }
        
        var lastEvent: ReadEvent?
        for try await event in subscription.events {
            lastEvent = event
            break
        }

        let lastEventPosition = try #require(lastEvent?.record.position)
        #expect(response.position?.commit == lastEventPosition.commit)
        try await client.deleteStream(on: streamIdentifier)
    }
    
    @Test("It should succeed when subscribing to all streams with a stream name filter.")
    func testSubscribeFilterOnStreamName() async throws {
        let streamIdentifier = StreamIdentifier(name: UUID().uuidString)
        let eventForTesting = EventData(
            eventType: "SubscribeAll-AccountCreated", payload: ["Description": "Gears of War 10"]
        )
        let client = KurrentDBClient(settings: .localhost())
        
        let filter: SubscriptionFilter = .onStreamName(prefix: streamIdentifier.name)
        let subscription = try await client.subscribeAllStreams(startFrom: .end) {
            $0.filter(filter)
        }
        
        let response = try await client.appendStream(on: streamIdentifier, events: [eventForTesting]) {
            $0.revision(expected: .any)
        }
        
        var lastEvent: ReadEvent?
        for try await event in subscription.events {
            lastEvent = event
            break
        }

        let lastEventPosition = try #require(lastEvent?.record.position)
        #expect(response.position?.commit == lastEventPosition.commit)
        try await client.deleteStream(on: streamIdentifier)
    }
    
    @Test("It should fail when subscribing to all streams with an incorrect stream name filter.")
    func testSubscribeFilterFailedOnStreamName() async throws {
        let streamIdentifier = StreamIdentifier(name: UUID().uuidString)
        let eventForTesting = EventData(
            eventType: "SubscribeAll-AccountCreated", payload: ["Description": "Gears of War 10"]
        )
        let client = KurrentDBClient(settings: .localhost())
        
        let filter: SubscriptionFilter = .onStreamName(prefix: "wrong")
        let subscription = try await client.subscribeAllStreams(startFrom: .end) {
            $0.filter(filter)
        }
        
        _ = try await client.appendStream(on: streamIdentifier, events: [eventForTesting]) {
            $0.revision(expected: .any)
        }

        Task {
            try await Task.sleep(for: .microseconds(500))
            subscription.terminate()
        }
        
        for try await _ in subscription.events {
            break
        }
    }
    
    @Test("Testing stream ACL encoding and decoding should succeed.", arguments: [
        (StreamMetadata.Acl.systemStream, "$systemStreamAcl"),
        (StreamMetadata.Acl.userStream, "$userStreamAcl"),
    ])
    func testSystemStreamAclEncodeAndDecode(acl: StreamMetadata.Acl, value: String) throws {
        let encoder = JSONEncoder()
        let encodedData = try #require(try encoder.encode(value))

        #expect(try acl.rawValue == encodedData)

        let decoder = JSONDecoder()
        #expect(try decoder.decode(StreamMetadata.Acl.self, from: encodedData) == acl)
    }
}
