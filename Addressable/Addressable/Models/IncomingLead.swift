//
//  IncomingLead.swift
//  Addressable
//
//  Created by Ari on 1/13/21.
//

import Foundation

struct IncomingLead: Codable, Identifiable {
    let id: Int
    let md5, fromNumber, firstName, lastName: String?
    let streetLine1, streetLine2, city, state: String?
    let zipcode, crmID: String?

    enum CodingKeys: String, CodingKey {
        case id, md5
        case fromNumber = "from_number"
        case firstName = "first_name"
        case lastName = "last_name"
        case streetLine1 = "street_line_1"
        case streetLine2 = "street_line_2"
        case city, state, zipcode
        case crmID = "crm_id"
    }
}

typealias IncomingLeadsResponse = [IncomingLead]
