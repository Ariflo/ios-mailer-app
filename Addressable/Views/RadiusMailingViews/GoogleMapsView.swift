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
        let mapID = GMSMapID(identifier: "a7e9b12ef1d1327d")
        let mapView = GMSMapView(frame: .zero, mapID: mapID, camera: camera)

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
        mapView.clear()

        if locationSelected {
            let marker = GMSMarker()
            marker.icon = GMSMarker.markerImage(with: UIColor(rgb: 0x7E00B5))
            marker.position = CLLocationCoordinate2D(latitude: coordinates.0, longitude: coordinates.1)
            marker.map = mapView
        }
    }
}
#if DEBUG
struct GoogleMapsView_Previews: PreviewProvider {
    static var previews: some View {
        GoogleMapsView(coordinates: (0, 0), zoom: 10.0)
    }
}
#endif