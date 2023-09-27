//
//  Map+Coordinator.swift
//  Map
//
//  Created by Paul Kraft on 23.04.22.
//

import MapKit
import SwiftUI

#if !os(watchOS)

extension Map {
    
    // MARK: Nested Types
    
    public class Coordinator: NSObject, MKMapViewDelegate {
        
        // MARK: Stored Properties
        
        private var view: Map?
        
        private var annotationContentByObject = [ObjectIdentifier: MapAnnotation]()
        private var annotationContentByID = [AnnotationItems.Element.ID: MapAnnotation]()
        
        private var overlayContentByObject = [ObjectIdentifier: MapOverlay]()
        private var overlayContentByID = [OverlayItems.Element.ID: MapOverlay]()
        
        private var previousBoundary: MKMapView.CameraBoundary?
        private var previousZoomRange: MKMapView.CameraZoomRange?
        
        private var registeredAnnotationTypes = Set<ObjectIdentifier>()
        private var regionIsChanging = false
        private var isInitialRegionChange = true
        
        // MARK: Initialization
        
        override init() {}
        
        deinit {
            MapRegistry.clean()
        }
        
        // MARK: Methods
        
        func update(_ mapView: MKMapView, from newView: Map, context: Context) {
            defer { view = newView }
            let animation = context.transaction.animation
            updateAnnotations(on: mapView, from: view, to: newView)
            updateSelectedItem(on: mapView, from: view, to: newView)
            updateCamera(on: mapView, context: context, animated: animation != nil)
            updateSelectableMapFeatures(on: mapView, from: view, to: newView)
            updateInformationVisibility(on: mapView, from: view, to: newView)
            updateInteractionModes(on: mapView, from: view, to: newView)
            updateOverlays(on: mapView, from: view, to: newView)
            updatePointOfInterestFilter(on: mapView, from: view, to: newView)
            updateRegion(on: mapView, from: view, to: newView, animated: animation != nil)
            updateBottomPadding(on: mapView, from: view, to: newView)
            updateType(on: mapView, from: view, to: newView)
            updateUserTracking(on: mapView, from: view, to: newView, animated: animation != nil)
            updateVisibleItems(on: mapView, from: view, to: newView)
            updateVisibleUpdateNeeded(on: mapView, from: view, to: newView)
            
            if let key = context.environment.mapKey {
                MapRegistry[key] = mapView
            }
        }
        
        // MARK: Helpers
        
        private func registerAnnotationViewIfNeeded(on mapView: MKMapView, for content: MapAnnotation) {
            let contentType = type(of: content)
            let contentTypeKey = ObjectIdentifier(contentType)
            if !registeredAnnotationTypes.contains(contentTypeKey) {
                registeredAnnotationTypes.insert(contentTypeKey)
                contentType.registerView(on: mapView)
            }
        }
        
        private func updateAnnotations(on mapView: MKMapView, from previousView: Map?, to newView: Map) {
            let changes: CollectionDifference<AnnotationItems.Element>
            if let previousView = previousView {
                changes = newView.annotationItems.difference(from: previousView.annotationItems) { $0.id == $1.id }
            } else {
                changes = newView.annotationItems.difference(from: []) { $0.id == $1.id }
            }
            
                for change in changes {
                    switch change {
                    case let .insert(_, item, _):
                        guard !annotationContentByID.keys.contains(item.id) else {
                            assertionFailure("Duplicate annotation item id \(item.id) of \(item) found.")
                            continue
                        }
                        let content = newView.annotationContent(item)
                        let objectKey = ObjectIdentifier(content.annotation)
                        guard !annotationContentByObject.keys.contains(objectKey) else {
                            assertionFailure("Duplicate annotation for content \(content) found!")
                            continue
                        }
                        annotationContentByID[item.id] = content
                        annotationContentByObject[objectKey] = content
                        registerAnnotationViewIfNeeded(on: mapView, for: content)
                        mapView.addAnnotation(content.annotation)
                    case let .remove(_, item, _):
                        guard let content = annotationContentByID[item.id] else {
                            assertionFailure("Missing annotation content for item \(item) encountered.")
                            continue
                        }
                        mapView.removeAnnotation(content.annotation)
                        annotationContentByObject.removeValue(forKey: ObjectIdentifier(content.annotation))
                        annotationContentByID.removeValue(forKey: item.id)
                    }
                }
        }
        
        private func updateCamera(on mapView: MKMapView, context: Context, animated: Bool) {
            let newBoundary = context.environment.mapBoundary
            if previousBoundary != newBoundary && mapView.cameraBoundary != newBoundary {
                mapView.setCameraBoundary(newBoundary, animated: animated)
                previousBoundary = newBoundary
            }
            
            let newZoomRange = context.environment.mapZoomRange
            if previousZoomRange != newZoomRange && mapView.cameraZoomRange != newZoomRange {
                mapView.setCameraZoomRange(newZoomRange, animated: animated)
                previousZoomRange = newZoomRange
            }
        }
        
        private func updateInformationVisibility(on mapView: MKMapView, from previousView: Map?, to newView: Map) {
            guard previousView?.informationVisibility != newView.informationVisibility else {
                return
            }
            
            mapView.showsBuildings = newView.informationVisibility.contains(.buildings)
#if !os(tvOS)
            mapView.showsCompass = newView.informationVisibility.contains(.compass)
#endif
            mapView.showsScale = newView.informationVisibility.contains(.scale)
            mapView.showsTraffic = newView.informationVisibility.contains(.traffic)
            mapView.showsUserLocation = newView.informationVisibility.contains(.userLocation)
#if !os(iOS) && !os(tvOS)
            mapView.showsZoomControls = newView.informationVisibility.contains(.zoomControls)
            if #available(macOS 11, *) {
                mapView.showsPitchControl = newView.informationVisibility.contains(.pitchControl)
            }
#endif
        }
        
        private func updateBottomPadding(on mapView: MKMapView, from previousView: Map?, to newView: Map) {
            guard previousView?.bottomPartOfMapObscured != newView.bottomPartOfMapObscured else {
                return
            }
            DispatchQueue.main.async { [self] in
                mapView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: view?.bottomPartOfMapObscured ?? 0.0, right: 0)
                
                var mapRect = mapView.visibleMapRect
                
                let visannotations = mapView.annotations(in: mapRect).filter { !($0 is MKUserLocation) }
                view?.visibleItems = visannotations
                print("**newmap 5 new visible: \(visannotations.count)")
            }
        }
        
        private func updateSelectableMapFeatures(on mapView: MKMapView, from previousView: Map?, to newView: Map) {
            guard previousView?.selectableMapFeatures != newView.selectableMapFeatures else {
                return
            }
            
            if #available(iOS 16.0, *) {
                var newFeatures = MKMapFeatureOptions()
                if newView.selectableMapFeatures.contains(.physicalFeatures) {
                    newFeatures.insert(.physicalFeatures)
                }
                if newView.selectableMapFeatures.contains(.pointsOfInterest) {
                    newFeatures.insert(.pointsOfInterest)
                }
                if newView.selectableMapFeatures.contains(.territories) {
                    newFeatures.insert(.territories)
                }
                mapView.selectableMapFeatures = newFeatures
            }
        }
        
        private func updateInteractionModes(on mapView: MKMapView, from previousView: Map?, to newView: Map) {
            guard previousView?.interactionModes != newView.interactionModes else {
                return
            }
            
            mapView.isScrollEnabled = newView.interactionModes.contains(.pan)
            mapView.isZoomEnabled = newView.interactionModes.contains(.zoom)
#if !os(tvOS)
            mapView.isRotateEnabled = newView.interactionModes.contains(.rotate)
            mapView.isPitchEnabled = newView.interactionModes.contains(.pitch)
#endif
        }
        
        private func updateOverlays(on mapView: MKMapView, from previousView: Map?, to newView: Map) {
            let changes: CollectionDifference<OverlayItems.Element>
            if let previousView = previousView {
                changes = newView.overlayItems.difference(from: previousView.overlayItems) { $0.id == $1.id }
            } else {
                changes = newView.overlayItems.difference(from: []) { $0.id == $1.id }
            }
            
            for change in changes {
                switch change {
                case let .insert(index, item, _):
                    guard !overlayContentByID.keys.contains(item.id) else {
                        assertionFailure("Duplicate overlay item id \(item.id) of \(item) found.")
                        continue
                    }
                    let content = newView.overlayContent(item)
                    let objectKey = ObjectIdentifier(content.overlay)
                    guard !overlayContentByObject.keys.contains(objectKey) else {
                        assertionFailure("Duplicate overlay for content \(content) found!")
                        continue
                    }
                    overlayContentByObject[objectKey] = content
                    overlayContentByID[item.id] = content
                    if let level = content.level {
                        mapView.insertOverlay(content.overlay, at: index, level: level)
                    } else {
                        mapView.insertOverlay(content.overlay, at: index)
                    }
                case let .remove(_, item, _):
                    guard let content = overlayContentByID[item.id] else {
                        assertionFailure("Missing overlay content for item \(item) encountered.")
                        continue
                    }
                    overlayContentByObject.removeValue(forKey: ObjectIdentifier(content.overlay))
                    overlayContentByID.removeValue(forKey: item.id)
                    mapView.removeOverlay(content.overlay)
                }
            }
        }
        
        private func updateSelectedItem(on mapView: MKMapView, from previousView: Map?, to newView: Map) {
            guard newView.selectedItems != previousView?.selectedItems else { return }
            
            if newView.selectedItems.count == 1,
               let newSelectedItem = newView.selectedItems.first,
               let mapAnnotation = annotationContentByID[newSelectedItem] {
                mapView.selectAnnotation(mapAnnotation.annotation, animated: false)
            } else if newView.selectedItems.isEmpty {
                mapView.selectedAnnotations = []
            }
            
        }
        
        private func updateVisibleItems(on mapView: MKMapView, from previousView: Map?, to newView: Map) {
            guard newView.coordinateRegion.center.latitude != previousView?.coordinateRegion.center.latitude ||
                    newView.coordinateRegion.center.latitude != previousView?.coordinateRegion.center.latitude
            else { return }
            let annotations = mapView.annotations.filter { !($0 is MKUserLocation) }
            if newView.visibleItems.count == 0, annotations.count > 0, newView.zoomToShowPinsIfNeeded {
                DispatchQueue.main.async { [self] in
                    adjustViewToNearestPin(mapView: mapView)
                }
            }
        }
        
        private func updateVisibleUpdateNeeded(on mapView: MKMapView, from previousView: Map?, to newView: Map) {
            guard newView.visibleUpdateNeeded else { return }
            
            DispatchQueue.main.async { [self] in
                mapView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: view?.bottomPartOfMapObscured ?? 0.0, right: 0)
                
                var mapRect = mapView.visibleMapRect
                
                let visannotations = mapView.annotations(in: mapRect).filter { !($0 is MKUserLocation) }
                view?.visibleItems = visannotations
                newView.visibleUpdateNeeded = false
                print("**newmap 7 new visible: \(visannotations.count)")
            }
        }
        
        private func updatePointOfInterestFilter(on mapView: MKMapView, from previousView: Map?, to newView: Map) {
            if previousView?.pointOfInterestFilter != newView.pointOfInterestFilter {
                mapView.pointOfInterestFilter = newView.pointOfInterestFilter
            }
        }
        
        private func updateRegion(on mapView: MKMapView, from previousView: Map?, to newView: Map, animated: Bool) {
            guard !regionIsChanging else {
                return
            }
            
            if newView.usesRegion {
                let newRegion = newView.coordinateRegion
                guard !(previousView?.coordinateRegion.equals(to: newRegion) ?? false)
                        && !mapView.region.equals(to: newRegion) else {
                    return
                }
                DispatchQueue.main.async { [self] in
                    mapView.setRegion(newRegion, animated: animated)
                }
            } else {
                let newRect = newView.mapRect
                guard !(previousView?.mapRect.equals(to: newRect) ?? false)
                        && !mapView.visibleMapRect.equals(to: newRect) else {
                    return
                }
                DispatchQueue.main.async { [self] in
                    mapView.setVisibleMapRect(newRect, animated: animated)
                }
            }
        }
        
        private func updateType(on mapView: MKMapView, from previousView: Map?, to newView: Map) {
            if previousView?.mapType != newView.mapType {
                mapView.mapType = newView.mapType
            }
        }
        
        private func updateUserTracking(on mapView: MKMapView, from previousView: Map?, to newView: Map, animated: Bool) {
            if #available(macOS 11, *) {
                let newTrackingMode = newView.userTrackingMode
                if newView.usesUserTrackingMode, mapView.userTrackingMode != newTrackingMode {
                    mapView.setUserTrackingMode(newTrackingMode, animated: animated)
                }
            }
        }
        
        // MARK: MKMapViewDelegate
        
        public func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            guard !regionIsChanging else {
                return
            }
            
            // Setup layout margins first
            DispatchQueue.main.async { [self] in
                mapView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: view?.bottomPartOfMapObscured ?? 0.0, right: 0)
            }
            view?.coordinateRegion = mapView.region
            view?.mapRect = mapView.visibleMapRect
            
            
            // Calculate the top half of the visible map rect
            
            var mapRect = mapView.visibleMapRect
            //            topHalfMapRect.size.height = topHalfMapRect.size.height - (topHalfMapRect.size.height * paddingRatio)
            
            let visannotations = mapView.annotations(in: mapRect).filter { !($0 is MKUserLocation) }
            view?.visibleItems = visannotations
            
            print("4 new visible \(visannotations.count)")
        }
        
        @available(macOS 11, *)
        public func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
            guard let view = view, view.usesUserTrackingMode else {
                return
            }
            switch mode {
            case .none:
                view.userTrackingMode = .none
            case .follow:
                view.userTrackingMode = .follow
            case .followWithHeading:
#if os(macOS) || os(tvOS)
                view.userTrackingMode = .follow
#else
                view.userTrackingMode = .followWithHeading
#endif
            @unknown default:
                assertionFailure("Encountered unknown user tracking mode")
            }
        }
        
        public func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            regionIsChanging = true
        }
        
        public func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            regionIsChanging = false
            if isInitialRegionChange {
                isInitialRegionChange = false
            } else {
                mapViewDidChangeVisibleRegion(mapView)
            }
        }
        
        public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let content = overlayContentByObject[ObjectIdentifier(overlay)] else {
                assertionFailure("Somehow an unknown overlay appeared.")
                return MKOverlayRenderer(overlay: overlay)
            }
            return content.renderer(for: mapView)
        }
        
        public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if #available(iOS 16.0, *) {
                if let feature = annotation as? MKMapFeatureAnnotation {
                    self.selectFeature(feature)
                }
            }
            
            // Simple annotation
            guard let content = annotationContentByObject[ObjectIdentifier(annotation)] else {
                return nil
            }
            
            return content.view(for: mapView)
        }
        
        public func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            
            // Find the item ID of the selected annotation
            guard let id = annotationContentByID.first(where: { $0.value.annotation === view.annotation })?.key else {
                return
            }
            // Assing the selected item ID to the selectedItem binding
            DispatchQueue.main.async {
                self.view?.selectedItems = [id]
            }
        }
        
        public func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
            DispatchQueue.main.async {
                if mapView.selectedAnnotations.isEmpty {
                    if #available(iOS 16.0, *) {
                        self.view?.selectedFeature = nil
                    }
                    self.view?.selectedItems = []
                }
            }
        }
        
        public func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
            if let userLocationView = mapView.view(for: mapView.userLocation) {
                userLocationView.isEnabled = false
            }
        }
        
        @available(iOS 16.0, *)
        private func selectFeature(_ feature: MKMapFeatureAnnotation) {
            var featureType: MapFeatureAnnotation.FeatureType
            switch feature.featureType {
            case .pointOfInterest:
                featureType = .pointOfInterest
            case .territory:
                featureType = .territory
            case .physicalFeature:
                featureType = .physicalFeature
            @unknown default:
                featureType = .pointOfInterest
            }
            
            var iconStyle: MapFeatureAnnotation.IconStyle?
            if let style = feature.iconStyle {
                iconStyle = MapFeatureAnnotation.IconStyle(
                    backgroundColor: style.backgroundColor,
                    image: style.image
                )
            }
            self.view?.selectedFeature = MapFeatureAnnotation(
                annotation: feature,
                featureType: featureType,
                iconStyle: iconStyle,
                pointOfInterestCategory: feature.pointOfInterestCategory
            )
        }
        
        func adjustViewToNearestPin(mapView: MKMapView) {
            let annotations = mapView.annotations.filter { !($0 is MKUserLocation) }
            
            var closestAnnotation: MKAnnotation?
            var shortestDistance: CLLocationDistance = .greatestFiniteMagnitude
            let center = mapView.centerCoordinate
            for annotation in annotations {
                if !mapView.visibleMapRect.contains(MKMapPoint(annotation.coordinate)) {
                    let currentDistance = distanceBetween(mapView.centerCoordinate, and: annotation.coordinate)
                    if currentDistance < shortestDistance {
                        closestAnnotation = annotation
                        shortestDistance = currentDistance
                    }
                }
            }
            
            if let closestAnnotation = closestAnnotation {
                let latitudeDelta = abs(mapView.centerCoordinate.latitude - closestAnnotation.coordinate.latitude) * 2.2
                let longitudeDelta = abs(mapView.centerCoordinate.longitude - closestAnnotation.coordinate.longitude) * 2.2
                
                let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta))
                
                mapView.setRegion(region, animated: true)
            }
        }
        
        func distanceBetween(_ coord1: CLLocationCoordinate2D, and coord2: CLLocationCoordinate2D) -> CLLocationDistance {
            let location1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
            let location2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
            return location1.distance(from: location2)
        }
    }
    
    // MARK: Methods
    
    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
}

#endif
