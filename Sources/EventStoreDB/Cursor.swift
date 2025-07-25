//
//  Cursor.swift
//  KurrentCore
//
//  Created by Grady Zhuo on 2024/3/21.
//

import Foundation

public enum Cursor<Pointer: Sendable>: Sendable {
    case start
    case end
    case specified(Pointer)
}
