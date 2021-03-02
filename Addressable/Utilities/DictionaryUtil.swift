//
//  DictionaryUtil.swift
//  Addressable
//
//  Created by Ari on 2/18/21.
//

extension Dictionary {
    static func += <K, V> (left: inout [K: V], right: [K: V]) {
        for (key, value) in right {
            left[key] = value
        }
    }
}
