//
//  MapBoxUiViewController.swift
//  Addressable
//
//  Created by Ari on 10/26/21.
//

import UIKit
import MapboxMaps

// swiftlint:disable implicitly_unwrapped_optional
class MapBoxUiViewController: UIViewController {
    internal var mapView: MapView!
    internal var cameraLocationConsumer: CameraLocationConsumer!

    var selectedCoordinates: CLLocationCoordinate2D?

    init(selectedCoordinates: CLLocationCoordinate2D?) {
        self.selectedCoordinates = selectedCoordinates
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        // Set initial map settings
        let options = MapInitOptions(
            cameraOptions: selectedCoordinates != nil ?
                CameraOptions(center: selectedCoordinates, zoom: 15) : CameraOptions(zoom: 15),
            styleURI: StyleURI.light
        )

        mapView = MapView(frame: view.bounds, mapInitOptions: options)
        mapView.autoresizingMask = [.flexibleHeight]
        view.addSubview(mapView)

        cameraLocationConsumer = CameraLocationConsumer(mapView: mapView)

        // Add user position icon to the map with location indicator layer
        mapView.location.options.puckType = .puck2D()

        // Allows the delegate to receive information about map events.
        mapView.mapboxMap.onNext(.mapLoaded) { _ in
            // Register the location consumer with the map
            // Note that the location manager holds weak references to consumers, which should be retained
            self.mapView.location.addLocationConsumer(newConsumer: self.cameraLocationConsumer)
        }
    }

    func updateMapWithSelectedLocation(selectedCoordinates: CLLocationCoordinate2D) {
        // Update map settings with new Coordinates
        let options = MapInitOptions(
            cameraOptions: CameraOptions(center: selectedCoordinates, zoom: 15),
            styleURI: StyleURI.light
        )

        mapView = MapView(frame: view.bounds, mapInitOptions: options)
        mapView.autoresizingMask = [.flexibleHeight]
        view.addSubview(mapView)

        // We want to display the annotation at the center of the map's current viewport
        let centerCoordinate = mapView.cameraState.center

        // Make a `PointAnnotationManager` which will be responsible for managing a
        // collection of `PointAnnotation`s.
        let pointAnnotationManager = mapView.annotations.makePointAnnotationManager()

        // Initialize a point annotation with a single coordinate
        // and configure it with a custom image (sourced from the asset catalogue)
        var customPointAnnotation = PointAnnotation(coordinate: centerCoordinate)

        // Add the image to the style's sprite
        if let markerImage = UIImage(named: "house-icon") {
            customPointAnnotation.image = .init(image: markerImage, name: "house-icon")
        }

        // Add the annotation to the manager in order to render it on the map.
        pointAnnotationManager.annotations = [customPointAnnotation]
    }
}

// Create class which conforms to LocationConsumer, update the camera's centerCoordinate when a locationUpdate is received
class CameraLocationConsumer: LocationConsumer {
    weak var mapView: MapView?

    init(mapView: MapView) {
        self.mapView = mapView
    }

    public func locationUpdate(newLocation: Location) {
        mapView?.camera.ease(
            to: CameraOptions(center: newLocation.coordinate, zoom: 15),
            duration: 1.3)
    }
}
