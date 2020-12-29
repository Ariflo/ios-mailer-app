//
//  UrlUtiles.swift
//  Addressable
//
//  Created by Ari on 12/29/20.
//

import Foundation

func baseUrl() -> String {
    #if DEBUG
    return "http://localhost:3000/api/v1"
    #elseif PRODUCTION
    return "https://api.addressable.app/api/v1/"
    #endif
}
