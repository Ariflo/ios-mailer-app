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
    func getTwilioAccessToken(_ deviceIdData: Data?) -> AnyPublisher<TwilioAccessToken, ApiError>
    func getIncomingLeads() -> AnyPublisher<IncomingLeadsResponse, ApiError>
    func getIncomingLeadsWithMessages() -> AnyPublisher<IncomingLeadsResponse, ApiError>
    func getLeadMessages(for leadId: Int) -> AnyPublisher<MessagesResponse, ApiError>
    func sendLeadMessage(_ message: Data?) -> AnyPublisher<MessagesResponse, ApiError>
}

class AddressableDataFetcher {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }
}

extension AddressableDataFetcher: FetchableData {
    func sendLeadMessage(_ messageData: Data?) -> AnyPublisher<MessagesResponse, ApiError> {
        return makeApiRequest(with: sendLeadMessageRequestComponents(), postRequestBodyData: messageData)
    }

    func getLeadMessages(for leadId: Int) -> AnyPublisher<MessagesResponse, ApiError> {
        return makeApiRequest(with: getLeadMessagesRequestComponents(for: leadId))
    }

    func getIncomingLeadsWithMessages() -> AnyPublisher<IncomingLeadsResponse, ApiError> {
        return makeApiRequest(with: getIncomingLeadsWithMessagesRequestComponents())
    }

    func getIncomingLeads() -> AnyPublisher<IncomingLeadsResponse, ApiError> {
        return makeApiRequest(with: getIncomingLeadsRequestComponents())
    }

    func getTwilioAccessToken(_ deviceIdData: Data?) -> AnyPublisher<TwilioAccessToken, ApiError> {
        return makeApiRequest(with: getTwilioAccessTokenRequestComponents(newLogin: deviceIdData != nil), postRequestBodyData: deviceIdData)
    }

    func getCurrentUserAuthorization(with basicAuthToken: String) -> AnyPublisher<AuthorizedUserResponse, ApiError> {
        return makeApiRequest(with: getAuthorizationRequestComponents(), token: basicAuthToken)
    }

    func getCurrentUserMailings() -> AnyPublisher<MailingsResponse, ApiError> {
        return makeApiRequest(with: getMailingsRequestComponents())
    }

    private func makeApiRequest<T>(
        with components: URLComponents,
        token: String? = nil,
        postRequestBodyData: Data? = nil
    ) -> AnyPublisher<T, ApiError> where T: Codable {
        guard let url = components.url else {
            let error = ApiError.network(description: "Couldn't create URL")
            return Fail(error: error).eraseToAnyPublisher()
        }
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        if let authToken = token ?? KeyChainServiceUtil.shared[USER_BASIC_AUTH_TOKEN] {
            request.setValue("Basic \(authToken)", forHTTPHeaderField: "Authorization")
        } else {
            let error = ApiError.network(description: "Unable to apply authorization token to request")
            return Fail(error: error).eraseToAnyPublisher()
        }

        if let body = postRequestBodyData {
            request.httpMethod = "POST"
            request.httpBody = body
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
        static let scheme = "https"
        static let host = "9b3875ee9d1a.ngrok.io"
        static let path = "/api/v1"
    }

    func getAuthorizationRequestComponents() -> URLComponents {
        var components = URLComponents()

        components.scheme = AddressableAPI.scheme
        components.host = AddressableAPI.host
        components.path = AddressableAPI.path + "/auth.json"

        return components
    }

    func getTwilioAccessTokenRequestComponents(newLogin: Bool) -> URLComponents {
        var components = URLComponents()

        components.scheme = AddressableAPI.scheme
        components.host = AddressableAPI.host
        components.path = AddressableAPI.path + "/auth/\(newLogin ? "mobile_login_new" : "mobile_login_refresh")"

        return components
    }

    func getMailingsRequestComponents() -> URLComponents {
        var components = URLComponents()

        components.scheme = AddressableAPI.scheme
        components.host = AddressableAPI.host
        components.path = AddressableAPI.path + "/mailings"

        return components
    }

    func getIncomingLeadsRequestComponents() -> URLComponents {
        var components = URLComponents()

        components.scheme = AddressableAPI.scheme
        components.host = AddressableAPI.host
        components.path = AddressableAPI.path + "/incoming_leads"

        return components
    }

    func getIncomingLeadsWithMessagesRequestComponents() -> URLComponents {
        var components = URLComponents()

        components.scheme = AddressableAPI.scheme
        components.host = AddressableAPI.host
        components.path = AddressableAPI.path + "/lead_messages"

        return components
    }

    func getLeadMessagesRequestComponents(for leadId: Int) -> URLComponents {
        var components = URLComponents()

        components.scheme = AddressableAPI.scheme
        components.host = AddressableAPI.host
        components.path = AddressableAPI.path + "/lead_messages/\(leadId)"

        return components
    }

    func sendLeadMessageRequestComponents() -> URLComponents {
        var components = URLComponents()

        components.scheme = AddressableAPI.scheme
        components.host = AddressableAPI.host
        components.path = AddressableAPI.path + "/lead_messages"

        return components
    }
}


enum ApiError: Error {
    case parsing(description: String)
    case network(description: String)
}
