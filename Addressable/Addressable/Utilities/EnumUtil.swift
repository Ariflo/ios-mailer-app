//
//  EnumUtil.swift
//  Addressable
//
//  Created by Ari on 1/26/21.
//


extension CaseIterable where Self: Equatable, AllCases: BidirectionalCollection {
    mutating func next() {
        let allCases = Self.allCases
        // just a sanity check, as the possibility of a enum case to not be
        // present in `allCases` is quite low
        guard let selfIndex = allCases.firstIndex(of: self) else { return }
        let nextIndex = Self.allCases.index(after: selfIndex)
        self = allCases[nextIndex]
    }

    mutating func back() {
        let allCases = Self.allCases
        // just a sanity check, as the possibility of a enum case to not be
        // present in `allCases` is quite low
        guard let selfIndex = allCases.firstIndex(of: self) else { return }
        let previousIndex = allCases.index(before: selfIndex)
        self = allCases[previousIndex]
    }
}
