//
//  ReadEvent+Additions.swift
//  KurrentPersistentSubscriptions
//
//  Created by 卓俊諺 on 2025/1/24.
//

extension ReadEvent {
    package init(message: PersistentSubscriptions.UnderlyingService.Method.Read.Output.ReadEvent) throws {
        let recorded: RecordedEvent = try .init(message: message.event)
        let linkedRecordedEvent: RecordedEvent? = try message.hasLink ? .init(message: message.link) : nil

        let commitPosition: StreamPosition? = if let position = message.position {
            switch position {
            case .noPosition:
                nil
            case let .commitPosition(position):
                .at(commitPosition: position)
            }
        } else {
            nil
        }

        self.init(recorded: recorded, link: linkedRecordedEvent, commitPosition: commitPosition)
    }
}
