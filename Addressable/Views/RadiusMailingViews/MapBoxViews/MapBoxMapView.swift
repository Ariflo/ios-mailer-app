//
//  MapBoxMapView.swift
//  Addressable
//
//  Created by Ari on 10/25/21.
//

import SwiftUI
import MapboxMaps

struct MapboxMapView: UIViewControllerRepresentable {
    var selectedCoordinates: CLLocationCoordinate2D?

    func makeUIViewController(context: Context) -> MapBoxUiViewController {
        let mapBoxViewController = MapBoxUiViewController(selectedCoordinates: selectedCoordinates)

        return mapBoxViewController
    }

    func updateUIViewController(_ mapBoxViewController: MapBoxUiViewController, context: Context) {
        if let coordinates = selectedCoordinates {
            mapBoxViewController.updateMapWithSelectedLocation(selectedCoordinates: coordinates)
        }
    }
}
