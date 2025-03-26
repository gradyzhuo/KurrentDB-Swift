//
//  UserCredentialsParser.swift
//  KurrentCore
//
//  Created by Grady Zhuo on 2024/5/25.
//

import Foundation
import RegexBuilder

class UserCredentialsParser: ConnctionStringParser {
    typealias UserReference = Reference<String>
    typealias PasswordReference = Reference<String>
    typealias RegexType = Regex<(Substring, UserReference.RegexOutput, PasswordReference.RegexOutput?)>
    typealias Result = Authentication

    let _user: UserReference = .init()
    let _password: PasswordReference = .init()

    lazy var regex: RegexType = Regex {
        Capture(as: _user) {
            OneOrMore(.any.subtracting(.anyOf(":@/")))
        } transform: {
            String($0)
        }
        ":"
        Optionally {
            Capture(as: _password) {
                OneOrMore(.any.subtracting(.anyOf(":@")))
            } transform: {
                String($0)
            }
        }
        "@"
    }

    func parse(_ connectionString: String) -> Authentication? {
        let match = connectionString.firstMatch(of: regex)
        return match.flatMap {
            .credentials(username: $0[_user], password: $0[_password])
        }
    }
}
