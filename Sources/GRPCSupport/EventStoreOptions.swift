//
//  File.swift
//  
//
//  Created by Ospark.org on 2023/10/31.
//

import Foundation
import SwiftProtobuf

package protocol EventStoreOptions: GRPCBridge {
    
    func build() -> UnderlyingMessage
    
}

