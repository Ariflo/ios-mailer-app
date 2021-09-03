//
//  AddressableApi.swift
//  Addressable
//
//  Created by Ari on 12/30/20.
//

// swiftlint:disable file_length
import Foundation
import Combine

let unauthorizedUserResponse = "content=\"authenticity_token\""

protocol FetchableData {
    // MARK: - Authorization
    func getCurrentUserAuthorization(with basicAuthToken: String) -> AnyPublisher<AuthorizedUserResponse, ApiError>
    func logoutMobileUser() -> AnyPublisher<GenericAPISuccessResponse, ApiError>
    func getTwilioAccessToken(_ deviceIdData: Data?) -> AnyPublisher<TwilioAccessTokenData, ApiError>
    // MARK: - Incoming Leads
    func getIncomingLeads() -> AnyPublisher<IncomingLeadsResponse, ApiError>
    func getIncomingLeadsWithMessages() -> AnyPublisher<IncomingLeadsResponse, ApiError>
    func getLeadMessages(for leadId: Int) -> AnyPublisher<MessagesResponse, ApiError>
    func sendLeadMessage(_ message: Data?) -> AnyPublisher<MessagesResponse, ApiError>
    func tagIncomingLead(with id: Int, _ tagData: Data?) -> AnyPublisher<IncomingLeadResponse, ApiError>
    func addCallParticipant(_ newCallData: Data?) -> AnyPublisher<CallParticipantResponse, ApiError>
    func addUserNotes(accountId: Int, leadId: Int, _ noteData: Data?) -> AnyPublisher<IncomingLeadResponse, ApiError>
    // MARK: - Message Templates
    func getMessageTemplates(for mailingId: Int) -> AnyPublisher<MessageTemplatesResponse, ApiError>
    func getMessageTemplate(for templateId: Int, with mailingId: Int) -> AnyPublisher<MessageTemplateResponse, ApiError>
    func updateMessageTemplate(for templateId: Int, _ messageTemplateData: Data?) -> AnyPublisher<MessageTemplateResponse, ApiError>
    func getMultiTouchTopics() -> AnyPublisher<MultiTouchTopicResponse, ApiError>
    // MARK: - Mailings
    func getCurrentUserMailingCampaigns() -> AnyPublisher<CampaignsResponse, ApiError>
    func getMailingCoverImages() -> AnyPublisher<MailingCoverImageResponse, ApiError>
    func createNewRadiusMailing(_ newRadiusMailingData: Data?) -> AnyPublisher<RadiusMailingResponse, ApiError>
    func updateRadiusMailing(for component: RadiusMailingComponent, with id: Int, _ updateRadiusMailingData: Data?) -> AnyPublisher<RadiusMailingResponse, ApiError>
    func getSelectedMailing(for id: Int) -> AnyPublisher<MailingResponse, ApiError>
    func getDefaultDataTreeSearchCriteria() -> AnyPublisher<DataTreeSearchCriteriaWrapper, ApiError>
    func updateMailingListEntry(for id: Int, _ updateListEntryData: Data?) -> AnyPublisher<UpdateRecipientResponse, ApiError>
    func updateMailingMessageTemplate(for id: Int, _ updateMailingMessageTemplateData: Data?) -> AnyPublisher<MailingResponse, ApiError>
    func updateMailingListUpload(for id: Int, _ updateMailingAudienceData: Data?) -> AnyPublisher<MailingResponse, ApiError>
    func getMailingRecipients(for mailingId: Int) -> AnyPublisher<RecipientResponse, ApiError>
    func addRecipientToRemovalList(accountId: Int, recipientId: Int) -> AnyPublisher<UpdateRecipientResponse, ApiError>
    func createTransaction(accountId: Int, mailingId: Int, transactionData: Data?) -> AnyPublisher<MailingResponse, ApiError>
    func updateMailingReturnAddress(for mailingId: Int, returnAddressData: Data?) -> AnyPublisher<MailingResponse, ApiError>
    func updateMailingCover(for mailingId: Int, updateMailingCoverData: Data?) -> AnyPublisher<MailingResponse, ApiError>
    func cloneMailing(accountId: Int, mailingId: Int, cloneMailingData: Data?) -> AnyPublisher<MailingResponse, ApiError>
    func getListUploads() -> AnyPublisher<ListUploadResponse, ApiError>
    // MARK: - Feedback
    func sendAppFeedback(feedbackData: Data?) -> AnyPublisher<GenericAPISuccessResponse, ApiError>
    // MARK: - Profile Settings
    func getAccount(with accountId: Int) -> AnyPublisher<AccountResponse, ApiError>
    func getAccountHandwritingStyles() -> AnyPublisher<HandwritingResponse, ApiError>
    func updateUser(with userId: Int, updateUserData: Data?) -> AnyPublisher<AuthorizedUserResponse, ApiError>
}

enum RadiusMailingComponent {
    case location, cover, topic, list, targetDate
}

enum ApiError: Error {
    case parsing(description: String)
    case network(description: String)
}

class ApiService: Service {
    private let session: URLSession
    // swiftlint:disable implicitly_unwrapped_optional
    private var socket: URLSessionWebSocketTask!

    required init(provider: DependencyProviding) {
        self.session = .shared
    }
}

extension ApiService: FetchableData {
    func getAccount(with accountId: Int) -> AnyPublisher<AccountResponse, ApiError> {
        return makeApiRequest(with: getAccountRequestComponents(with: accountId))
    }

    func updateUser(with userId: Int, updateUserData: Data?) -> AnyPublisher<AuthorizedUserResponse, ApiError> {
        return makeApiRequest(with: updateUserRequestComponents(with: userId),
                              postRequestBodyData: nil,
                              patchRequestBodyData: updateUserData)
    }

    func getAccountHandwritingStyles() -> AnyPublisher<HandwritingResponse, ApiError> {
        return makeApiRequest(with: getHandwritingsRequestComponents())
    }

    func updateMailingListUpload(for id: Int, _ updateMailingAudienceData: Data?) -> AnyPublisher<MailingResponse, ApiError> {
        return makeApiRequest(
            with: updateMailingAudienceRequestComponents(for: id),
            postRequestBodyData: nil,
            patchRequestBodyData: updateMailingAudienceData
        )
    }

    func getListUploads() -> AnyPublisher<ListUploadResponse, ApiError> {
        return makeApiRequest(with: listUploadsRequestComponents())
    }

    func updateMailingMessageTemplate(for id: Int, _ updateMailingMessageTemplateData: Data?) -> AnyPublisher<MailingResponse, ApiError> {
        return makeApiRequest(
            with: mailingRequestComponents(for: id),
            postRequestBodyData: nil,
            patchRequestBodyData: updateMailingMessageTemplateData
        )
    }

    func cloneMailing(accountId: Int, mailingId: Int, cloneMailingData: Data?) -> AnyPublisher<MailingResponse, ApiError> {
        return makeApiRequest(
            with: cloneMailingRequestComponents(accountId: accountId, mailingId: mailingId),
            postRequestBodyData: cloneMailingData
        )
    }

    func sendAppFeedback(feedbackData: Data?) -> AnyPublisher<GenericAPISuccessResponse, ApiError> {
        return makeApiRequest(
            with: sendFeedbackRequestComponents(),
            postRequestBodyData: feedbackData
        )
    }

    func createTransaction(accountId: Int, mailingId: Int, transactionData: Data?) -> AnyPublisher<MailingResponse, ApiError> {
        return makeApiRequest(
            with: createTransactionRequestComponents(accountId: accountId, mailingId: mailingId),
            postRequestBodyData: transactionData
        )
    }

    func addUserNotes(accountId: Int, leadId: Int, _ noteData: Data?) -> AnyPublisher<IncomingLeadResponse, ApiError> {
        return makeApiRequest(
            with: addUserNotesRequestComponents(accountId: accountId, leadId: leadId),
            postRequestBodyData: noteData
        )
    }

    func addRecipientToRemovalList(accountId: Int, recipientId: Int) -> AnyPublisher<UpdateRecipientResponse, ApiError> {
        return makeApiRequest(
            with: getRemoveRecipientFromListRequestComponents(
                accountId: accountId,
                recipientId: recipientId)
        )
    }

    func getMailingRecipients(for mailingId: Int) -> AnyPublisher<RecipientResponse, ApiError> {
        return makeApiRequest(with: getMailingRecipientsRequestComponents(for: mailingId))
    }

    func logoutMobileUser() -> AnyPublisher<GenericAPISuccessResponse, ApiError> {
        makeApiRequest(with: logoutMobileUserRequestComponents(), postRequestBodyData: Data())
    }

    func getDefaultDataTreeSearchCriteria() -> AnyPublisher<DataTreeSearchCriteriaWrapper, ApiError> {
        return makeApiRequest(with: getDefaultDataTreeSearchCriteriaRequestComponents())
    }

    func tagIncomingLead(with id: Int, _ tagData: Data?) -> AnyPublisher<IncomingLeadResponse, ApiError> {
        return makeApiRequest(with: updateIncomingLeadRequestComponents(for: id),
                              postRequestBodyData: nil,
                              patchRequestBodyData: tagData)
    }

    func updateRadiusMailing(for component: RadiusMailingComponent, with id: Int, _ updateRadiusMailingData: Data?) -> AnyPublisher<RadiusMailingResponse, ApiError> {
        switch component {
        case .location:
            return makeApiRequest(with: updateRadiusMailingLocationRequestComponents(for: id),
                                  postRequestBodyData: nil,
                                  patchRequestBodyData: updateRadiusMailingData)
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
        case .targetDate:
            return makeApiRequest(with: updateRadiusMailingDateRequestComponents(for: id),
                                  postRequestBodyData: nil,
                                  patchRequestBodyData: updateRadiusMailingData)
        }
    }

    func updateMailingReturnAddress(for mailingId: Int, returnAddressData: Data?) -> AnyPublisher<MailingResponse, ApiError> {
        return makeApiRequest(with: updateMailingReturnAddressRequestComponents(for: mailingId),
                              postRequestBodyData: nil,
                              patchRequestBodyData: returnAddressData)
    }

    func updateMailingCover(for mailingId: Int, updateMailingCoverData: Data?) -> AnyPublisher<MailingResponse, ApiError> {
        return makeApiRequest(with: updateMailingCoverRequestComponents(for: mailingId),
                              postRequestBodyData: nil,
                              patchRequestBodyData: updateMailingCoverData)
    }

    func updateMailingListEntry(for id: Int, _ updateListEntryData: Data?) -> AnyPublisher<UpdateRecipientResponse, ApiError> {
        return makeApiRequest(with: updateListEntryRequestComponents(for: id),
                              postRequestBodyData: nil,
                              patchRequestBodyData: updateListEntryData)
    }

    func getSelectedMailing(for id: Int) -> AnyPublisher<MailingResponse, ApiError> {
        return makeApiRequest(with: mailingRequestComponents(for: id))
    }

    func createNewRadiusMailing(_ newRadiusMailingData: Data?) -> AnyPublisher<RadiusMailingResponse, ApiError> {
        return makeApiRequest(with: createRadiusMailingRequestComponents(), postRequestBodyData: newRadiusMailingData)
    }

    func getMessageTemplate(for templateId: Int, with mailingId: Int) -> AnyPublisher<MessageTemplateResponse, ApiError> {
        return makeApiRequest(with: getMessageTemplateRequestComponents(for: templateId, with: mailingId))
    }

    func updateMessageTemplate(for templateId: Int, _ messageTemplateData: Data?) -> AnyPublisher<MessageTemplateResponse, ApiError> {
        return makeApiRequest(with: updateMessageTemplateRequestComponents(for: templateId),
                              postRequestBodyData: nil,
                              patchRequestBodyData: messageTemplateData)
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

    func getMessageTemplates(for mailingId: Int) -> AnyPublisher<MessageTemplatesResponse, ApiError> {
        return makeApiRequest(with: getMailingMessageTemplatesRequestComponents(with: mailingId))
    }

    func getMailingCoverImages() -> AnyPublisher<MailingCoverImageResponse, ApiError> {
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
            .filter { self.verifiedAuthorizedUserResponse(response: $0.data) }
            .flatMap(maxPublishers: .max(1)) { pair in
                decode(pair.data)
            }
            .eraseToAnyPublisher()
    }
    private func verifiedAuthorizedUserResponse(response: Data) -> Bool {
        if let jsonPayload = String(data: response, encoding: .utf8) {
            if jsonPayload.contains(unauthorizedUserResponse) {
                KeyChainServiceUtil.shared.clearAll()
                return false
            }
        }
        return true
    }
    func connectToWebSocket(userToken: String, completionHandler: @escaping (Data?) -> Void) {
        if let url = getWebSocketRequestComponents(with: userToken).url {
            var request = URLRequest(url: url)
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")

            socket = session.webSocketTask(with: request)
            listen(completionHandler)
            socket.resume()
        }
    }

    func disconnectFromWebSocket() {
        guard socket != nil else { return }
        if let cancelTask = URLSessionWebSocketTask.CloseCode(rawValue: 0) {
            socket.cancel(with: cancelTask, reason: nil)
        }
    }

    func subscribe(command: String, identifier: String) {
        guard let encodedSubscribeCommandData = try? JSONEncoder().encode(
            MessageSocketCommand(command: command, identifier: identifier)
        ) else {
            print("Message Socket Subscription Data Encoding Error")
            return
        }
        // swiftlint:disable force_unwrapping
        socket.send(
            URLSessionWebSocketTask
                .Message
                .string(String(data: encodedSubscribeCommandData, encoding: .utf8)!)) { error in
            if let error = error {
                print("WebSocket couldn’t send message because: \(error)")
            }
        }
    }

    private func listen(_ completionHandler: @escaping (Data?) -> Void) {
        socket.receive { result in
            switch result {
            case .failure(let error):
                print("connectToSocket() receive error: \(error)")
                completionHandler(nil)
                return
            case .success(let message):
                switch message {
                case .data(let data):
                    completionHandler(data)
                case .string(let str):
                    guard let data = str.data(using: .utf8) else { return }
                    completionHandler(data)
                @unknown default:
                    break
                }
            }
            self.listen(completionHandler)
        }
    }
}

private extension ApiService {
    // swiftlint:disable convenience_type
    struct AddressableAPI {
        static var components = URLComponents()
        static let scheme = Bundle.main.object(forInfoDictionaryKey: "DOMAIN_SCHEME") as? String ?? ""
        static let host = Bundle.main.object(forInfoDictionaryKey: "API_DOMAIN_NAME") as? String ?? ""
        static let path = "/api/v1"
        static let port = 3000
    }

    func getAuthorizationRequestComponents() -> URLComponents {
        #if DEBUG
        AddressableAPI.components.port = AddressableAPI.port
        #endif

        AddressableAPI.components.scheme = AddressableAPI.scheme
        AddressableAPI.components.host = AddressableAPI.host
        AddressableAPI.components.path = AddressableAPI.path + "/auth"

        return AddressableAPI.components
    }

    func getTwilioAccessTokenRequestComponents() -> URLComponents {
        #if DEBUG
        AddressableAPI.components.port = AddressableAPI.port
        #endif

        AddressableAPI.components.scheme = AddressableAPI.scheme
        AddressableAPI.components.host = AddressableAPI.host
        AddressableAPI.components.path = AddressableAPI.path + "/auth/mobile_registration"

        return AddressableAPI.components
    }

    func logoutMobileUserRequestComponents() -> URLComponents {
        #if DEBUG
        AddressableAPI.components.port = AddressableAPI.port
        #endif

        AddressableAPI.components.scheme = AddressableAPI.scheme
        AddressableAPI.components.host = AddressableAPI.host
        AddressableAPI.components.path = AddressableAPI.path + "/auth/mobile_deregistration"

        return AddressableAPI.components
    }

    func getCampaignsRequestComponents() -> URLComponents {
        #if DEBUG
        AddressableAPI.components.port = AddressableAPI.port
        #endif

        AddressableAPI.components.scheme = AddressableAPI.scheme
        AddressableAPI.components.host = AddressableAPI.host
        AddressableAPI.components.path = AddressableAPI.path + "/campaigns"

        return AddressableAPI.components
    }

    func getIncomingLeadsRequestComponents() -> URLComponents {
        #if DEBUG
        AddressableAPI.components.port = AddressableAPI.port
        #endif

        AddressableAPI.components.scheme = AddressableAPI.scheme
        AddressableAPI.components.host = AddressableAPI.host
        AddressableAPI.components.path = AddressableAPI.path + "/incoming_leads"

        return AddressableAPI.components
    }

    func getIncomingLeadsWithMessagesRequestComponents() -> URLComponents {
        #if DEBUG
        AddressableAPI.components.port = AddressableAPI.port
        #endif

        AddressableAPI.components.scheme = AddressableAPI.scheme
        AddressableAPI.components.host = AddressableAPI.host
        AddressableAPI.components.path = AddressableAPI.path + "/lead_messages"

        return AddressableAPI.components
    }

    func getLeadMessagesRequestComponents(for leadId: Int) -> URLComponents {
        #if DEBUG
        AddressableAPI.components.port = AddressableAPI.port
        #endif

        AddressableAPI.components.scheme = AddressableAPI.scheme
        AddressableAPI.components.host = AddressableAPI.host
        AddressableAPI.components.path = AddressableAPI.path + "/lead_messages/\(leadId)"

        return AddressableAPI.components
    }

    func sendLeadMessageRequestComponents() -> URLComponents {
        #if DEBUG
        AddressableAPI.components.port = AddressableAPI.port
        #endif

        AddressableAPI.components.scheme = AddressableAPI.scheme
        AddressableAPI.components.host = AddressableAPI.host
        AddressableAPI.components.path = AddressableAPI.path + "/lead_messages"

        return AddressableAPI.components
    }

    func getMailingCoverArtRequestComponents() -> URLComponents {
        #if DEBUG
        AddressableAPI.components.port = AddressableAPI.port
        #endif

        AddressableAPI.components.scheme = AddressableAPI.scheme
        AddressableAPI.components.host = AddressableAPI.host
        AddressableAPI.components.path = AddressableAPI.path + "/layout_templates"

        return AddressableAPI.components
    }

    func getMailingReturnAddressRequestComponents() -> URLComponents {
        #if DEBUG
        AddressableAPI.components.port = AddressableAPI.port
        #endif

        AddressableAPI.components.scheme = AddressableAPI.scheme
        AddressableAPI.components.host = AddressableAPI.host
        AddressableAPI.components.path = AddressableAPI.path + "/return_addresses"

        return AddressableAPI.components
    }

    func getMailingMessageTemplatesRequestComponents(with mailingId: Int) -> URLComponents {
        #if DEBUG
        AddressableAPI.components.port = AddressableAPI.port
        #endif

        AddressableAPI.components.scheme = AddressableAPI.scheme
        AddressableAPI.components.host = AddressableAPI.host
        AddressableAPI.components.path = AddressableAPI.path + "/mailings/\(mailingId)" +
            "/message_templates/all_templates_with_merge_vars"

        return AddressableAPI.components
    }

    func getMessageTemplateRequestComponents(for templateId: Int, with mailingId: Int) -> URLComponents {
        #if DEBUG
        AddressableAPI.components.port = AddressableAPI.port
        #endif

        AddressableAPI.components.scheme = AddressableAPI.scheme
        AddressableAPI.components.host = AddressableAPI.host
        AddressableAPI.components.path = AddressableAPI.path + "/mailings/\(mailingId)" +
            "/message_templates/\(templateId)/template_with_merge_vars"

        return AddressableAPI.components
    }

    func updateMessageTemplateRequestComponents(for templateId: Int) -> URLComponents {
        #if DEBUG
        AddressableAPI.components.port = AddressableAPI.port
        #endif

        AddressableAPI.components.scheme = AddressableAPI.scheme
        AddressableAPI.components.host = AddressableAPI.host
        AddressableAPI.components.path = AddressableAPI.path + "/message_templates/\(templateId)"

        return AddressableAPI.components
    }

    func addParticipantToCallRequestComponents() -> URLComponents {
        #if DEBUG
        AddressableAPI.components.port = AddressableAPI.port
        #endif

        AddressableAPI.components.scheme = AddressableAPI.scheme
        AddressableAPI.components.host = AddressableAPI.host
        AddressableAPI.components.path = AddressableAPI.path + "/outgoing_calls/add_caller"

        return AddressableAPI.components
    }

    func getMultiTouchTopicRequestComponents() -> URLComponents {
        #if DEBUG
        AddressableAPI.components.port = AddressableAPI.port
        #endif

        AddressableAPI.components.scheme = AddressableAPI.scheme
        AddressableAPI.components.host = AddressableAPI.host
        AddressableAPI.components.path = AddressableAPI.path + "/multi_touch_topics"

        return AddressableAPI.components
    }

    func createRadiusMailingRequestComponents() -> URLComponents {
        #if DEBUG
        AddressableAPI.components.port = AddressableAPI.port
        #endif

        AddressableAPI.components.scheme = AddressableAPI.scheme
        AddressableAPI.components.host = AddressableAPI.host
        AddressableAPI.components.path = AddressableAPI.path + "/radius_mailings"

        return AddressableAPI.components
    }

    func mailingRequestComponents(for id: Int) -> URLComponents {
        #if DEBUG
        AddressableAPI.components.port = AddressableAPI.port
        #endif

        AddressableAPI.components.scheme = AddressableAPI.scheme
        AddressableAPI.components.host = AddressableAPI.host
        AddressableAPI.components.path = AddressableAPI.path + "/mailings/\(id)"

        return AddressableAPI.components
    }

    func updateRadiusMailingLocationRequestComponents(for id: Int) -> URLComponents {
        #if DEBUG
        AddressableAPI.components.port = AddressableAPI.port
        #endif

        AddressableAPI.components.scheme = AddressableAPI.scheme
        AddressableAPI.components.host = AddressableAPI.host
        AddressableAPI.components.path = AddressableAPI.path + "/radius_mailings/\(id)/subject_address"

        return AddressableAPI.components
    }

    func updateRadiusMailingCoverRequestComponents(for id: Int) -> URLComponents {
        #if DEBUG
        AddressableAPI.components.port = AddressableAPI.port
        #endif

        AddressableAPI.components.scheme = AddressableAPI.scheme
        AddressableAPI.components.host = AddressableAPI.host
        AddressableAPI.components.path = AddressableAPI.path + "/radius_mailings/\(id)/cover"

        return AddressableAPI.components
    }

    func updateMailingCoverRequestComponents(for id: Int) -> URLComponents {
        #if DEBUG
        AddressableAPI.components.port = AddressableAPI.port
        #endif

        AddressableAPI.components.scheme = AddressableAPI.scheme
        AddressableAPI.components.host = AddressableAPI.host
        AddressableAPI.components.path = AddressableAPI.path + "/mailings/\(id)/cover"

        return AddressableAPI.components
    }

    func updateMailingAudienceRequestComponents(for id: Int) -> URLComponents {
        #if DEBUG
        AddressableAPI.components.port = AddressableAPI.port
        #endif

        AddressableAPI.components.scheme = AddressableAPI.scheme
        AddressableAPI.components.host = AddressableAPI.host
        AddressableAPI.components.path = AddressableAPI.path + "/mailings/\(id)/audience"

        return AddressableAPI.components
    }

    func updateRadiusMailingTopicRequestComponents(for id: Int) -> URLComponents {
        #if DEBUG
        AddressableAPI.components.port = AddressableAPI.port
        #endif

        AddressableAPI.components.scheme = AddressableAPI.scheme
        AddressableAPI.components.host = AddressableAPI.host
        AddressableAPI.components.path = AddressableAPI.path + "/radius_mailings/\(id)/topic"

        return AddressableAPI.components
    }

    func updateRadiusMailingListRequestComponents(for id: Int) -> URLComponents {
        #if DEBUG
        AddressableAPI.components.port = AddressableAPI.port
        #endif

        AddressableAPI.components.scheme = AddressableAPI.scheme
        AddressableAPI.components.host = AddressableAPI.host
        AddressableAPI.components.path = AddressableAPI.path + "/radius_mailings/\(id)/list"

        return AddressableAPI.components
    }

    func updateRadiusMailingDateRequestComponents(for id: Int) -> URLComponents {
        #if DEBUG
        AddressableAPI.components.port = AddressableAPI.port
        #endif

        AddressableAPI.components.scheme = AddressableAPI.scheme
        AddressableAPI.components.host = AddressableAPI.host
        AddressableAPI.components.path = AddressableAPI.path + "/radius_mailings/\(id)/target_date"

        return AddressableAPI.components
    }

    func updateMailingReturnAddressRequestComponents(for id: Int) -> URLComponents {
        #if DEBUG
        AddressableAPI.components.port = AddressableAPI.port
        #endif

        AddressableAPI.components.scheme = AddressableAPI.scheme
        AddressableAPI.components.host = AddressableAPI.host
        AddressableAPI.components.path = AddressableAPI.path + "/mailings/\(id)/from_address"

        return AddressableAPI.components
    }

    func updateRadiusMailingStatusRequestComponents(for id: Int) -> URLComponents {
        #if DEBUG
        AddressableAPI.components.port = AddressableAPI.port
        #endif

        AddressableAPI.components.scheme = AddressableAPI.scheme
        AddressableAPI.components.host = AddressableAPI.host
        AddressableAPI.components.path = AddressableAPI.path + "/radius_mailings/\(id)/status"

        return AddressableAPI.components
    }

    func updateListEntryRequestComponents(for id: Int) -> URLComponents {
        #if DEBUG
        AddressableAPI.components.port = AddressableAPI.port
        #endif

        AddressableAPI.components.scheme = AddressableAPI.scheme
        AddressableAPI.components.host = AddressableAPI.host
        AddressableAPI.components.path = AddressableAPI.path + "/list_entries/\(id)"

        return AddressableAPI.components
    }

    func updateIncomingLeadRequestComponents(for id: Int) -> URLComponents {
        #if DEBUG
        AddressableAPI.components.port = AddressableAPI.port
        #endif

        AddressableAPI.components.scheme = AddressableAPI.scheme
        AddressableAPI.components.host = AddressableAPI.host
        AddressableAPI.components.path = AddressableAPI.path + "/incoming_leads/\(id)"

        return AddressableAPI.components
    }

    func getDefaultDataTreeSearchCriteriaRequestComponents() -> URLComponents {
        #if DEBUG
        AddressableAPI.components.port = AddressableAPI.port
        #endif

        AddressableAPI.components.scheme = AddressableAPI.scheme
        AddressableAPI.components.host = AddressableAPI.host
        AddressableAPI.components.path = AddressableAPI.path + "/data_tree_search/default_criteria"

        return AddressableAPI.components
    }

    func getMailingRecipientsRequestComponents(for id: Int) -> URLComponents {
        #if DEBUG
        AddressableAPI.components.port = AddressableAPI.port
        #endif

        AddressableAPI.components.scheme = AddressableAPI.scheme
        AddressableAPI.components.host = AddressableAPI.host
        AddressableAPI.components.path = AddressableAPI.path + "/mailings/\(id)/recipients"

        return AddressableAPI.components
    }

    func getRemoveRecipientFromListRequestComponents(accountId: Int, recipientId: Int) -> URLComponents {
        #if DEBUG
        AddressableAPI.components.port = AddressableAPI.port
        #endif

        AddressableAPI.components.scheme = AddressableAPI.scheme
        AddressableAPI.components.host = AddressableAPI.host
        AddressableAPI.components.path = AddressableAPI.path + "/accounts/\(accountId)/removals/\(recipientId)" +
            "/create_removal_from_list_entry"

        return AddressableAPI.components
    }

    func addUserNotesRequestComponents(accountId: Int, leadId: Int) -> URLComponents {
        #if DEBUG
        AddressableAPI.components.port = AddressableAPI.port
        #endif

        AddressableAPI.components.scheme = AddressableAPI.scheme
        AddressableAPI.components.host = AddressableAPI.host
        AddressableAPI.components.path = AddressableAPI.path + "/accounts/\(accountId)" +
            "/incoming_leads/\(leadId)/add_note"

        return AddressableAPI.components
    }

    func createTransactionRequestComponents(accountId: Int, mailingId: Int) -> URLComponents {
        #if DEBUG
        AddressableAPI.components.port = AddressableAPI.port
        #endif

        AddressableAPI.components.scheme = AddressableAPI.scheme
        AddressableAPI.components.host = AddressableAPI.host
        AddressableAPI.components.path = AddressableAPI.path + "/accounts/\(accountId)" +
            "/mailings/\(mailingId)/create_transaction"

        return AddressableAPI.components
    }

    func cloneMailingRequestComponents(accountId: Int, mailingId: Int) -> URLComponents {
        #if DEBUG
        AddressableAPI.components.port = AddressableAPI.port
        #endif

        AddressableAPI.components.scheme = AddressableAPI.scheme
        AddressableAPI.components.host = AddressableAPI.host
        AddressableAPI.components.path = AddressableAPI.path + "/accounts/\(accountId)/mailings/\(mailingId)/clone"

        return AddressableAPI.components
    }

    func listUploadsRequestComponents() -> URLComponents {
        #if DEBUG
        AddressableAPI.components.port = AddressableAPI.port
        #endif

        AddressableAPI.components.scheme = AddressableAPI.scheme
        AddressableAPI.components.host = AddressableAPI.host
        AddressableAPI.components.path = AddressableAPI.path + "/list_uploads"

        return AddressableAPI.components
    }

    func sendFeedbackRequestComponents() -> URLComponents {
        #if DEBUG
        AddressableAPI.components.port = AddressableAPI.port
        #endif

        AddressableAPI.components.scheme = AddressableAPI.scheme
        AddressableAPI.components.host = AddressableAPI.host
        AddressableAPI.components.path = AddressableAPI.path + "/feedback"

        return AddressableAPI.components
    }

    func getAccountRequestComponents(with accountID: Int) -> URLComponents {
        #if DEBUG
        AddressableAPI.components.port = AddressableAPI.port
        #endif

        AddressableAPI.components.scheme = AddressableAPI.scheme
        AddressableAPI.components.host = AddressableAPI.host
        AddressableAPI.components.path = AddressableAPI.path + "/accounts/\(accountID)"

        return AddressableAPI.components
    }

    func getHandwritingsRequestComponents() -> URLComponents {
        #if DEBUG
        AddressableAPI.components.port = AddressableAPI.port
        #endif

        AddressableAPI.components.scheme = AddressableAPI.scheme
        AddressableAPI.components.host = AddressableAPI.host
        AddressableAPI.components.path = AddressableAPI.path + "/handwritings"

        return AddressableAPI.components
    }

    func updateUserRequestComponents(with userId: Int) -> URLComponents {
        #if DEBUG
        AddressableAPI.components.port = AddressableAPI.port
        #endif

        AddressableAPI.components.scheme = AddressableAPI.scheme
        AddressableAPI.components.host = AddressableAPI.host
        AddressableAPI.components.path = AddressableAPI.path + "/users/\(userId)"

        return AddressableAPI.components
    }


    func getWebSocketRequestComponents(with userToken: String) -> URLComponents {
        #if DEBUG
        AddressableAPI.components.port = AddressableAPI.port
        #endif

        AddressableAPI.components.scheme = "ws"
        AddressableAPI.components.host = AddressableAPI.host
        AddressableAPI.components.path = "/cable"
        AddressableAPI.components.queryItems = [URLQueryItem(name: "user_token", value: userToken)]

        return AddressableAPI.components
    }
}
