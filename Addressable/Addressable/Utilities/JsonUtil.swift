//
//  JsonUtil.swift
//  Addressable
//
//  Created by Ari on 12/30/20.
//

import Foundation
import Combine

func decode<T: Decodable>(_ data: Data) -> AnyPublisher<T, ApiError> {
    return Just(data)
        .decode(type: T.self, decoder: JSONDecoder())
        .mapError { error in
            .parsing(description: error.localizedDescription)
        }
        .eraseToAnyPublisher()
}
