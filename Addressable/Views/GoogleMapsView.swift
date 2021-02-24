//
//  GoogleMapsView.swift
//  Addressable
//
//  Created by Ari on 2/11/21.
//

import SwiftUI
import GoogleMaps

struct GoogleMapsView: UIViewRepresentable {
    var coordinates: (CLLocationDegrees, CLLocationDegrees)
    var locationSelected: Bool = false
    var zoom: Float

    func makeUIView(context: Self.Context) -> GMSMapView {
        let camera = GMSCameraPosition.camera(withLatitude: coordinates.0, longitude: coordinates.1, zoom: zoom)
        let mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)

        mapView.isMyLocationEnabled = true

        return mapView
    }

    func updateUIView(_ mapView: GMSMapView, context: Context) {
        mapView.animate(toLocation: CLLocationCoordinate2D(latitude: coordinates.0, longitude: coordinates.1))

        let newCamera = GMSCameraPosition.camera(
            withLatitude: coordinates.0,
            longitude: coordinates.1,
            zoom: zoom
        )
        mapView.camera = newCamera

        if locationSelected {
            let marker = GMSMarker()
            marker.position = CLLocationCoordinate2D(latitude: coordinates.0, longitude: coordinates.1)
            marker.map = mapView
        }
    }
}

struct GoogleMapsView_Previews: PreviewProvider {
    static var previews: some View {
        GoogleMapsView(coordinates: (0, 0), zoom: 10.0)
    }
}
