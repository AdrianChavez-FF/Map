//
//  MapFeatureAnnotation.swift
//  
//
//  Created by Roman Blum on 05.11.22.
//

import UIKit
import MapKit

@available(iOS 16.0, *)
extension MKMapFeatureAnnotation.FeatureType {
    var featureType: MapFeatureAnnotation.FeatureType {
        switch self {
        case .pointOfInterest:
            return .pointOfInterest
        case .territory:
            return .territory
        case .physicalFeature:
            return .physicalFeature
        @unknown default:
            fatalError("Unknown MKMapFeatureAnnotation.FeatureType")
        }
    }
}

public struct MapFeatureAnnotation: Equatable {

    public enum FeatureType: Int {
        case pointOfInterest = 0
        case territory = 1
        case physicalFeature = 2
    }

    public struct IconStyle: Hashable {
        public let backgroundColor: UIColor
        public let image: UIImage
    }

    public let coordinate: CLLocationCoordinate2D
    public let title: String?
    public let subtitle: String?
    public let featureType: FeatureType
    public let iconStyle: IconStyle?
    public let pointOfInterestCategory: MKPointOfInterestCategory?
}

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
