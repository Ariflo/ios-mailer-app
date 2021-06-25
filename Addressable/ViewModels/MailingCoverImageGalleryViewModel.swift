//
//  MailingCoverImageGalleryViewModel.swift
//  Addressable
//
//  Created by Ari on 6/16/21.
//

import SwiftUI
import Combine


class MailingCoverImageGalleryViewModel: ObservableObject {
    private let apiService: ApiService
    private var disposables = Set<AnyCancellable>()
    var mailing: Mailing

    @Binding var selectedFrontCoverImageData: Data?
    @Binding var selectedBackCoverImageData: Data?

    @Binding var selectedCoverImageId: Int

    @Published var frontCoverImages: [Int: MailingCoverImageData] = [:]
    @Published var backCoverImages: [Int: MailingCoverImageData] = [:]

    @Published var loadingCoverImages: Bool = false

    init(
        provider: DependencyProviding,
        selectedMailing: Mailing,
        selectedFrontImageData: Binding<Data?>,
        selectedBackImageData: Binding<Data?>,
        selectedImageId: Binding<Int>
    ) {
        apiService = provider.register(provider: provider)
        mailing = selectedMailing

        _selectedFrontCoverImageData = selectedFrontImageData
        _selectedBackCoverImageData = selectedBackImageData
        _selectedCoverImageId = selectedImageId
    }

    func getMailingCoverImageOptions() {
        loadingCoverImages = true
        apiService
            .getMailingCoverImages()
            .map { resp in resp.mailingCoverImages
                .filter {
                    $0.mailingCoverImage.cardFrontImageUrl != nil ||
                        $0.mailingCoverImage.cardBackImageUrl != nil
                }
                .map { $0.mailingCoverImage }
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] value in
                    guard let self = self else { return }
                    switch value {
                    case .failure(let error):
                        print("getMailingCoverImageOptions() receiveCompletion error: \(error)")
                        self.frontCoverImages = [:]
                        self.backCoverImages = [:]
                        self.loadingCoverImages = false
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] mailingCoverImages in
                    guard let self = self else { return }
                    self.getMailingFrontCoverImageData(for: mailingCoverImages)
                })
            .store(in: &disposables)
    }

    private func getMailingFrontCoverImageData(for coverImages: [MailingCoverImage]) {
        guard !coverImages.isEmpty else {
            self.loadingCoverImages = false
            return
        }
        for image in coverImages {
            guard let urlString = image.cardFrontImageUrl,
                  let url = URL(string: urlString) else { continue }

            let task = URLSession.shared.dataTask(with: url) { data, _, _ in
                guard let data = data else { return }

                DispatchQueue.main.async {[weak self] in
                    guard let self = self else { return }
                    self.frontCoverImages[image.id] = MailingCoverImageData(
                        id: image.id,
                        image: image,
                        imageData: data)
                    // Present images when they've all loaded
                    if self.frontCoverImages.keys.count == coverImages.count {
                        self.getMailingBackCoverImageData(for: coverImages)
                    }
                }
            }
            task.resume()
        }
    }

    private func getMailingBackCoverImageData(for coverImages: [MailingCoverImage]) {
        guard !coverImages.isEmpty else {
            self.loadingCoverImages = false
            return
        }
        for image in coverImages {
            guard let urlString = image.cardBackImageUrl,
                  let url = URL(string: urlString) else { continue }

            let task = URLSession.shared.dataTask(with: url) { data, _, _ in
                guard let data = data else { return }

                DispatchQueue.main.async {[weak self] in
                    guard let self = self else { return }
                    self.backCoverImages[image.id] = MailingCoverImageData(
                        id: image.id,
                        image: image,
                        imageData: data)
                    // Present images when they've all loaded
                    if self.backCoverImages.keys.count == coverImages.count {
                        self.loadingCoverImages = false
                    }
                }
            }
            task.resume()
        }
    }

    func updateMailingCoverImage(completion: @escaping (_ updatedMailing: Mailing?) -> Void) {
        guard let updatedImageData = try? JSONEncoder().encode(
            OutgoingRadiusMailingCoverArtWrapper(
                cover: OutgoingRadiusMailingCoverArtData(layoutTemplateID: selectedCoverImageId)
            )
        ) else {
            print("Update Mailing COVER Encoding Error")
            return
        }

        apiService.updateRadiusMailing(
            for: .cover,
            with: mailing.id,
            updatedImageData
        )
        .map { resp in
            resp.radiusMailing
        }
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { value in
                switch value {
                case .failure(let error):
                    print("updateMailingCoverImage() receiveCompletion error: \(error)")
                    completion(nil)
                case .finished:
                    break
                }
            },
            receiveValue: { mailing in
                completion(mailing)
            })
        .store(in: &disposables)
    }
}
