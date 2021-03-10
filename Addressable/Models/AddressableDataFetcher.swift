//
//  AddressableApi.swift
//  Addressable
//
//  Created by Ari on 12/30/20.
//

import Foundation
import Combine

protocol FetchableData {
    func tagIncomingLead(with id: Int, _ tagData: Data?) -> AnyPublisher<IncomingLeadResponse, ApiError>
    func getCurrentUserAuthorization(with basicAuthToken: String) -> AnyPublisher<AuthorizedUserResponse, ApiError>
    func getTwilioAccessToken(_ deviceIdData: Data?) -> AnyPublisher<TwilioAccessTokenData, ApiError>
    func getCurrentUserMailingCampaigns() -> AnyPublisher<CampaignsResponse, ApiError>
    func getIncomingLeads() -> AnyPublisher<IncomingLeadsResponse, ApiError>
    func getIncomingLeadsWithMessages() -> AnyPublisher<IncomingLeadsResponse, ApiError>
    func getLeadMessages(for leadId: Int) -> AnyPublisher<MessagesResponse, ApiError>
    func sendLeadMessage(_ message: Data?) -> AnyPublisher<MessagesResponse, ApiError>
    func getMailingCoverArt() -> AnyPublisher<MailingCoverArtResponse, ApiError>
    func getMailingReturnAddress() -> AnyPublisher<ReturnAddress, ApiError>
    func sendCustomMailing(_ mailing: Data?) -> AnyPublisher<OutgoingCustomNoteResponse, ApiError>
    func getMessageTemplates() -> AnyPublisher<MessageTemplatesResponse, ApiError>
    func addCallParticipant(_ newCallData: Data?) -> AnyPublisher<CallParticipantResponse, ApiError>
    func getMultiTouchTopics() -> AnyPublisher<MultiTouchTopicResponse, ApiError>
    func getMessageTemplate(for id: Int) -> AnyPublisher<MessageTemplateElement, ApiError>
    func createNewRadiusMailing(_ newRadiusMailingData: Data?) -> AnyPublisher<RadiusMailingWrapper, ApiError>
    func updateRadiusMailing(for component: RadiusMailingComponent, with id: Int, _ updateRadiusMailingData: Data?) -> AnyPublisher<RadiusMailingWrapper, ApiError>
    func updateRadiusListEntry(for id: Int, _ updateListEntryData: Data?) -> AnyPublisher<ListEntryResponse, ApiError>
    func getSelectedRadiusMailing(for id: Int) -> AnyPublisher<RadiusMailingWrapper, ApiError>
}

enum RadiusMailingComponent {
    case cover, topic, list
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
    func tagIncomingLead(with id: Int, _ tagData: Data?) -> AnyPublisher<IncomingLeadResponse, ApiError> {
        return makeApiRequest(with: updateIncomingLeadRequestComponents(for: id),
                              postRequestBodyData: nil,
                              patchRequestBodyData: tagData)
    }

    func updateRadiusMailing(for component: RadiusMailingComponent, with id: Int, _ updateRadiusMailingData: Data?) -> AnyPublisher<RadiusMailingWrapper, ApiError> {
        switch component {
        case .cover:
            return makeApiRequest(with: updateRadiusMailingCoverRequestComponents(for: id),
                                  postRequestBodyData: nil,
                                  patchRequestBodyData: updateRadiusMailingData)
        case .topic:
            return makeApiRequest(with: updateRadiusMailingTopicRequestComponents(for: id),
                                  postRequestBodyData: nil,
                                  patchRequestBodyData: updateRadiusMailingData)
        case .list:
            return makeApiRequest(with: updateRadiusMailingListRequestComponents(for: id),
                                  postRequestBodyData: nil,
                                  patchRequestBodyData: updateRadiusMailingData)
        }
    }

    func updateRadiusListEntry(for id: Int, _ updateListEntryData: Data?) -> AnyPublisher<ListEntryResponse, ApiError> {
        return makeApiRequest(with: updateListEntryRequestComponents(for: id),
                              postRequestBodyData: nil,
                              patchRequestBodyData: updateListEntryData)
    }

    func getSelectedRadiusMailing(for id: Int) -> AnyPublisher<RadiusMailingWrapper, ApiError> {
        return makeApiRequest(with: getRadiusMailingRequestComponents(for: id))
    }

    func createNewRadiusMailing(_ newRadiusMailingData: Data?) -> AnyPublisher<RadiusMailingWrapper, ApiError> {
        return makeApiRequest(with: createRadiusMailingRequestComponents(), postRequestBodyData: newRadiusMailingData)
    }

    func getMessageTemplate(for id: Int) -> AnyPublisher<MessageTemplateElement, ApiError> {
        return makeApiRequest(with: getMessageTemplateRequestComponents(for: id))
    }

    func getMultiTouchTopics() -> AnyPublisher<MultiTouchTopicResponse, ApiError> {
        return makeApiRequest(with: getMultiTouchTopicRequestComponents())
    }

    func getCurrentUserMailingCampaigns() -> AnyPublisher<CampaignsResponse, ApiError> {
        return makeApiRequest(with: getCampaignsRequestComponents())
    }

    func addCallParticipant(_ newCallData: Data?) -> AnyPublisher<CallParticipantResponse, ApiError> {
        return makeApiRequest(with: addParticipantToCallRequestComponents(), postRequestBodyData: newCallData)
    }

    func getMessageTemplates() -> AnyPublisher<MessageTemplatesResponse, ApiError> {
        return makeApiRequest(with: getMessageTemplatesRequestComponents())
    }

    func sendCustomMailing(_ mailing: Data?) -> AnyPublisher<OutgoingCustomNoteResponse, ApiError> {
        return makeApiRequest(with: customNotesRequestComponents(), postRequestBodyData: mailing)
    }

    func getMailingReturnAddress() -> AnyPublisher<ReturnAddress, ApiError> {
        return makeApiRequest(with: getMailingReturnAddressRequestComponents())
    }

    func getMailingCoverArt() -> AnyPublisher<MailingCoverArtResponse, ApiError> {
        return makeApiRequest(with: getMailingCoverArtRequestComponents())
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

    func getTwilioAccessToken(_ deviceIdData: Data?) -> AnyPublisher<TwilioAccessTokenData, ApiError> {
        return makeApiRequest(with: getTwilioAccessTokenRequestComponents(), postRequestBodyData: deviceIdData)
    }

    func getCurrentUserAuthorization(with basicAuthToken: String) -> AnyPublisher<AuthorizedUserResponse, ApiError> {
        return makeApiRequest(with: getAuthorizationRequestComponents(), token: basicAuthToken)
    }

    private func makeApiRequest<T>(
        with components: URLComponents,
        token: String? = nil,
        postRequestBodyData: Data? = nil,
        patchRequestBodyData: Data? = nil
    ) -> AnyPublisher<T, ApiError> where T: Codable {
        guard let url = components.url else {
            let error = ApiError.network(description: "Couldn't create URL")
            return Fail(error: error).eraseToAnyPublisher()
        }
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        if let authToken = token ?? KeyChainServiceUtil.shared[userBasicAuthToken] {
            request.setValue("Basic \(authToken)", forHTTPHeaderField: "Authorization")
        } else {
            let error = ApiError.network(description: "Unable to apply authorization token to request")
            return Fail(error: error).eraseToAnyPublisher()
        }

        if let body = postRequestBodyData {
            request.httpMethod = "POST"
            request.httpBody = body
        }

        if let body = patchRequestBodyData {
            request.httpMethod = "PATCH"
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
        static let host = "sandbox.addressable.app"
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

    func customNotesRequestComponents() -> URLComponents {
        var components = URLComponents()

        components.scheme = AddressableAPI.scheme
        components.host = AddressableAPI.host
        components.path = AddressableAPI.path + "/custom_notes"

        return components
    }

    func getCampaignsRequestComponents() -> URLComponents {
        var components = URLComponents()

        components.scheme = AddressableAPI.scheme
        components.host = AddressableAPI.host
        components.path = AddressableAPI.path + "/campaigns"

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

    func getMessageTemplateRequestComponents(for id: Int) -> URLComponents {
        var components = URLComponents()

        components.scheme = AddressableAPI.scheme
        components.host = AddressableAPI.host
        components.path = AddressableAPI.path + "/message_templates/\(id)"

        return components
    }

    func addParticipantToCallRequestComponents() -> URLComponents {
        var components = URLComponents()

        components.scheme = AddressableAPI.scheme
        components.host = AddressableAPI.host
        components.path = AddressableAPI.path + "/outgoing_calls/add_caller"

        return components
    }

    func getMultiTouchTopicRequestComponents() -> URLComponents {
        var components = URLComponents()

        components.scheme = AddressableAPI.scheme
        components.host = AddressableAPI.host
        components.path = AddressableAPI.path + "/multi_touch_topics"

        return components
    }

    func createRadiusMailingRequestComponents() -> URLComponents {
        var components = URLComponents()

        components.scheme = AddressableAPI.scheme
        components.host = AddressableAPI.host
        components.path = AddressableAPI.path + "/radius_mailings"

        return components
    }

    func getRadiusMailingRequestComponents(for id: Int) -> URLComponents {
        var components = URLComponents()

        components.scheme = AddressableAPI.scheme
        components.host = AddressableAPI.host
        components.path = AddressableAPI.path + "/radius_mailings/\(id)"

        return components
    }

    func updateRadiusMailingCoverRequestComponents(for id: Int) -> URLComponents {
        var components = URLComponents()

        components.scheme = AddressableAPI.scheme
        components.host = AddressableAPI.host
        components.path = AddressableAPI.path + "/radius_mailings/\(id)/cover"

        return components
    }

    func updateRadiusMailingTopicRequestComponents(for id: Int) -> URLComponents {
        var components = URLComponents()

        components.scheme = AddressableAPI.scheme
        components.host = AddressableAPI.host
        components.path = AddressableAPI.path + "/radius_mailings/\(id)/topic"

        return components
    }

    func updateRadiusMailingListRequestComponents(for id: Int) -> URLComponents {
        var components = URLComponents()

        components.scheme = AddressableAPI.scheme
        components.host = AddressableAPI.host
        components.path = AddressableAPI.path + "/radius_mailings/\(id)/list"

        return components
    }

    func updateListEntryRequestComponents(for id: Int) -> URLComponents {
        var components = URLComponents()

        components.scheme = AddressableAPI.scheme
        components.host = AddressableAPI.host
        components.path = AddressableAPI.path + "/list_entries/\(id)"

        return components
    }

    func updateIncomingLeadRequestComponents(for id: Int) -> URLComponents {
        var components = URLComponents()

        components.scheme = AddressableAPI.scheme
        components.host = AddressableAPI.host
        components.path = AddressableAPI.path + "/incoming_leads/\(id)"

        return components
    }
}
