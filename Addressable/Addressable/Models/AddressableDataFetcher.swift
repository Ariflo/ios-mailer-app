//
//  AddressableApi.swift
//  Addressable
//
//  Created by Ari on 12/30/20.
//

import Foundation
import Combine

protocol FetchableData {
    func getCurrentUserMailings() -> AnyPublisher<MailingsResponse, ApiError>
    func getCurrentUserAuthorization(with basicAuthToken: String) -> AnyPublisher<AuthorizedUserResponse, ApiError>
}

class AddressableDataFetcher {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }
}

extension AddressableDataFetcher: FetchableData {
    func getCurrentUserAuthorization(with basicAuthToken: String) -> AnyPublisher<AuthorizedUserResponse, ApiError> {
        return makeApiRequest(with: getAuthorizationRequestComponents(), token: basicAuthToken)
    }

    func getCurrentUserMailings() -> AnyPublisher<MailingsResponse, ApiError> {
        return makeApiRequest(with: getMailingsRequestComponents())
    }

    private func makeApiRequest<T>(
        with components: URLComponents,
        token: String? = nil
    ) -> AnyPublisher<T, ApiError> where T: Decodable {
        guard let url = components.url else {
            let error = ApiError.network(description: "Couldn't create URL")
            return Fail(error: error).eraseToAnyPublisher()
        }
        var request = URLRequest(url: url)

        if let authToken = token ?? KeyChainServiceUtil.shared[USER_BASIC_AUTH_TOKEN] {
            request.setValue("Basic \(authToken)", forHTTPHeaderField: "Authorization")
        } else {
            let error = ApiError.network(description: "Unable to apply authorization token to request")
            return Fail(error: error).eraseToAnyPublisher()
        }

        return session.dataTaskPublisher(for: request)
            .mapError { error in
                .network(description: error.localizedDescription)
            }
            .flatMap(maxPublishers: .max(1)) { pair in
                decode(pair.data)
            }
            .eraseToAnyPublisher()
    }
}

private extension AddressableDataFetcher {
    struct AddressableAPI {
        #if DEBUG
        static let scheme = "http"
        static let host = "localhost"
        #elseif PRODUCTION
        static let scheme = "https"
        static let host = "api.addressable.app"
        #endif
        static let path = "/api/v1"
    }

    func getAuthorizationRequestComponents() -> URLComponents {
        var components = URLComponents()

        components.scheme = AddressableAPI.scheme
        components.host = AddressableAPI.host
        #if DEBUG
        components.port = 3000
        #endif
        components.path = AddressableAPI.path + "/auth.json"

        return components
    }

    func getMailingsRequestComponents() -> URLComponents {
        var components = URLComponents()

        components.scheme = AddressableAPI.scheme
        components.host = AddressableAPI.host
        #if DEBUG
        components.port = 3000
        #endif
        components.path = AddressableAPI.path + "/mailings.json"

        return components
    }
}


enum ApiError: Error {
    case parsing(description: String)
    case network(description: String)
}
