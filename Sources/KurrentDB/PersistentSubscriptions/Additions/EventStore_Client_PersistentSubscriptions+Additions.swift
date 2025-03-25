//
//  EventStore_Client_PersistentSubscriptions+Additions.swift
//  KurrentPersistentSubscriptions
//
//  Created by Grady Zhuo on 2024/3/22.
//

import Foundation
import GRPCEncapsulates

extension EventStore_Client_PersistentSubscriptions_CreateReq.Settings {
    package static func make(settings: PersistentSubscription.Settings) -> Self {
        .with {
            $0.resolveLinks = settings.resolveLink
            $0.extraStatistics = settings.extraStatistics
            $0.maxRetryCount = settings.maxRetryCount
            $0.minCheckpointCount = settings.checkpointCount.lowerBound
            $0.maxSubscriberCount = settings.checkpointCount.upperBound
            $0.maxSubscriberCount = settings.maxSubscriberCount
            $0.liveBufferSize = settings.liveBufferSize
            $0.readBatchSize = settings.readBatchSize
            $0.historyBufferSize = settings.historyBufferSize

            switch settings.checkpointAfter {
            case let .ms(ms):
                $0.checkpointAfterMs = ms
            case let .ticks(ticks):
                $0.checkpointAfterTicks = ticks
            }

            switch settings.messageTimeout {
            case let .ticks(int64):
                $0.messageTimeoutTicks = int64
            case let .ms(int32):
                $0.messageTimeoutMs = int32
            }
            $0.consumerStrategy = settings.consumerStrategy.rawValue
        }
    }
}

extension EventStore_Client_PersistentSubscriptions_UpdateReq.Settings {
    package static func make(settings: PersistentSubscription.Settings) -> Self {
        .with {
            $0.resolveLinks = settings.resolveLink
            $0.extraStatistics = settings.extraStatistics
            $0.maxRetryCount = settings.maxRetryCount
            $0.minCheckpointCount = settings.checkpointCount.lowerBound
            $0.maxSubscriberCount = settings.checkpointCount.upperBound
            $0.maxSubscriberCount = settings.maxSubscriberCount
            $0.liveBufferSize = settings.liveBufferSize
            $0.readBatchSize = settings.readBatchSize
            $0.historyBufferSize = settings.historyBufferSize

            switch settings.checkpointAfter {
            case let .ms(ms):
                $0.checkpointAfterMs = ms
            case let .ticks(ticks):
                $0.checkpointAfterTicks = ticks
            }

            switch settings.messageTimeout {
            case let .ticks(int64):
                $0.messageTimeoutTicks = int64
            case let .ms(int32):
                $0.messageTimeoutMs = int32
            }
        }
    }
}

extension EventStore_Client_PersistentSubscriptions_CreateReq.AllOptions.FilterOptions {
    package static func make(with filter: SubscriptionFilter) -> Self {
        .with {
            switch filter.window {
            case .count:
                $0.count = .init()
            case let .max(max):
                $0.max = max
            }

            switch filter.type {
            case .streamName:
                $0.streamIdentifier = .with {
                    if let regex = filter.regex{
                        $0.regex = regex
                    }
                    
                    $0.prefix = filter.prefixes
                }
            case .eventType:
                $0.eventType = .with {
                    if let regex = filter.regex{
                        $0.regex = regex
                    }
                    $0.prefix = filter.prefixes
                }
            }

            $0.checkpointIntervalMultiplier = filter.checkpointIntervalMultiplier
        }
    }
}
