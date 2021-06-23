//
//  MailingImagePreviewView.swift
//  Addressable
//
//  Created by Ari on 6/16/21.
//

import SwiftUI

struct MailingImagePreviewView: View {
    var imageData: Data?
    var refreshMailing: () -> Void
    var cancelRefreshMailingTask: () -> Void

    var body: some View {
        if let imageData = imageData {
            CustomNote.CoverImage(imageData: imageData)
                .padding(.bottom, 30)
        } else {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .onAppear {
                    refreshMailing()
                }
                .onDisappear {
                    cancelRefreshMailingTask()
                }
        }
    }
}
#if DEBUG
struct MailingImagePreviewView_Previews: PreviewProvider {
    static var previews: some View {
        MailingImagePreviewView(refreshMailing: {}, cancelRefreshMailingTask: {})
    }
}
#endif
