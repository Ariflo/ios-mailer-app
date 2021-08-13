//
//  PreviewView.swift
//  Addressable
//
//  Created by Ari on 4/14/21.
//

import Foundation
import UIKit
import SwiftUI
import Combine
import WebKit

// MARK: - PreviewView
struct PreviewView: UIViewRepresentable {
    @ObservedObject var viewModel: PreviewViewModel
    var mailing: Mailing
    var messageTemplateId: Int

    // Make a coordinator to co-ordinate with WKWebView's default delegate functions
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true

        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences = preferences

        let webView = WKWebView(frame: CGRect.zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = false
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if viewModel.reloadWebView {
            webView.reload()
            viewModel.reloadWebView = false
        }

        if let url = URL(string: "https://sandbox.addressable.app/api/v1/mobile_views/custom_note_previews?" +
                            "mailing_id=\(mailing.id)&" +
                            "&user_token=\(mailing.user.authenticationToken)" +
                            "&message_template_id=\(messageTemplateId)") {
            webView.load(URLRequest(url: url))
        }
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: PreviewView
        var webViewNavigationSubscriber: AnyCancellable?

        init(_ uiWebView: PreviewView) {
            parent = uiWebView
        }

        deinit {
            webViewNavigationSubscriber?.cancel()
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation) {
            parent.viewModel.showLoader.send(false)
        }

        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            parent.viewModel.showLoader.send(false)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation, withError error: Error) {
            parent.viewModel.showLoader.send(false)
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation) {
            parent.viewModel.showLoader.send(true)
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation) {
            parent.viewModel.showLoader.send(true)
        }
    }
}
