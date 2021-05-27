//
//  WebViewViewModel.swift
//  Addressable
//
//  Created by Ari on 4/14/21.
//

import Foundation
import Combine

class PreviewViewModel: ObservableObject {
    var showLoader = PassthroughSubject<Bool, Never>()
    @Published var reloadWebView: Bool = false
}
