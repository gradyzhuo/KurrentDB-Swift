//
//  SchemeParser.swift
//  KurrentCore
//
//  Created by Grady Zhuo on 2024/5/25.
//

import Foundation
import RegexBuilder

class URLSchemeParser: ConnctionStringParser {
    typealias SchemeReference = Reference<String>
    typealias RegexType = Regex<(Substring, SchemeReference.RegexOutput)>
    typealias Result = URLScheme

    let _scheme: SchemeReference = .init()

    lazy var regex: RegexType = Regex {
        Capture(as: _scheme) {
            OneOrMore(.any)
        }
        transform: {
            String($0)
        }
        "://"
    }

    func parse(_ connectionString: String) -> URLScheme? {
        let match = connectionString.firstMatch(of: regex)
        return match.flatMap {
            .init(rawValue: $0[_scheme])
        }
    }
}
