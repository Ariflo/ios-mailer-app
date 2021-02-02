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
    func getCurrentUserCustomNotes() -> AnyPublisher<CustomNotesResponse, ApiError>
    func getCurrentUserAuthorization(with basicAuthToken: String) -> AnyPublisher<AuthorizedUserResponse, ApiError>
    func getTwilioAccessToken(_ deviceIdData: Data?) -> AnyPublisher<TwilioAccessToken, ApiError>
    func getIncomingLeads() -> AnyPublisher<IncomingLeadsResponse, ApiError>
    func getIncomingLeadsWithMessages() -> AnyPublisher<IncomingLeadsResponse, ApiError>
    func getLeadMessages(for leadId: Int) -> AnyPublisher<MessagesResponse, ApiError>
    func sendLeadMessage(_ message: Data?) -> AnyPublisher<MessagesResponse, ApiError>
    func getMailingCoverArt() -> AnyPublisher<MailingCoverArtResponse, ApiError>
    func getMailingReturnAddress() -> AnyPublisher<ReturnAddress, ApiError>
    func sendCustomMailing(_ mailing: Data?) -> AnyPublisher<OutgoingCustomNoteResponse, ApiError>
    func getMessageTemplates() -> AnyPublisher<MessageTemplatesResponse, ApiError>
}

enum ApiError: Error {
    case parsing(description: String)
    case network(description: String)
}

class AddressableDataFetcher {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }
}

extension AddressableDataFetcher: FetchableData {
    func getMessageTemplates() -> AnyPublisher<MessageTemplatesResponse, ApiError> {
        return makeApiRequest(with: getMessageTemplatesRequestComponents())
    }

    func sendCustomMailing(_ mailing: Data?) -> AnyPublisher<OutgoingCustomNoteResponse, ApiError> {
        return makeApiRequest(with: getCustomNotesRequestComponents(), postRequestBodyData: mailing)
    }

    func getMailingReturnAddress() -> AnyPublisher<ReturnAddress, ApiError> {
        return makeApiRequest(with: getMailingReturnAddressRequestComponents())
    }

    func getMailingCoverArt() -> AnyPublisher<MailingCoverArtResponse, ApiError> {
        return makeApiRequest(with: getMailingCoverArtRequestComponents())
    }

    func getCurrentUserCustomNotes() -> AnyPublisher<CustomNotesResponse, ApiError> {
        return makeApiRequest(with: getCustomNotesRequestComponents())
    }

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
        return makeApiRequest(with: getTwilioAccessTokenRequestComponents(), postRequestBodyData: deviceIdData)
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
        static let host = "bfa6f6d72a2f.ngrok.io"
        static let path = "/api/v1"
    }

    func getAuthorizationRequestComponents() -> URLComponents {
        var components = URLComponents()

        components.scheme = AddressableAPI.scheme
        components.host = AddressableAPI.host
        components.path = AddressableAPI.path + "/auth"

        return components
    }

    func getTwilioAccessTokenRequestComponents() -> URLComponents {
        var components = URLComponents()

        components.scheme = AddressableAPI.scheme
        components.host = AddressableAPI.host
        components.path = AddressableAPI.path + "/auth/mobile_login"

        return components
    }

    func getMailingsRequestComponents() -> URLComponents {
        var components = URLComponents()

        components.scheme = AddressableAPI.scheme
        components.host = AddressableAPI.host
        components.path = AddressableAPI.path + "/mailings"

        return components
    }

    func getCustomNotesRequestComponents() -> URLComponents {
        var components = URLComponents()

        components.scheme = AddressableAPI.scheme
        components.host = AddressableAPI.host
        components.path = AddressableAPI.path + "/custom_notes"

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

    func getMailingCoverArtRequestComponents() -> URLComponents {
        var components = URLComponents()

        components.scheme = AddressableAPI.scheme
        components.host = AddressableAPI.host
        components.path = AddressableAPI.path + "/layout_templates"

        return components
    }

    func getMailingReturnAddressRequestComponents() -> URLComponents {
        var components = URLComponents()

        components.scheme = AddressableAPI.scheme
        components.host = AddressableAPI.host
        components.path = AddressableAPI.path + "/return_addresses"

        return components
    }

    func getMessageTemplatesRequestComponents() -> URLComponents {
        var components = URLComponents()

        components.scheme = AddressableAPI.scheme
        components.host = AddressableAPI.host
        components.path = AddressableAPI.path + "/message_templates"

        return components
    }
}
