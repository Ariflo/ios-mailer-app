//
//  IncomingLead.swift
//  Addressable
//
//  Created by Ari on 1/13/21.
//

import Foundation

struct IncomingLead: Codable, Identifiable {
    let id: Int
    let md5, from_number, first_name, last_name: String?
    let street_line_1, street_line_2, city, state, zipcode, crm_id: String?
}

typealias IncomingLeadsResponse = [IncomingLead]
