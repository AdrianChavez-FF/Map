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

    public let annotation: MKAnnotation?
    public let featureType: FeatureType
    public let iconStyle: IconStyle?
    public let pointOfInterestCategory: MKPointOfInterestCategory?

    public static func == (lhs: MapFeatureAnnotation, rhs: MapFeatureAnnotation) -> Bool {
        lhs.annotation?.coordinate.latitude == rhs.annotation?.coordinate.latitude
        && lhs.annotation?.coordinate.longitude == rhs.annotation?.coordinate.longitude
        && lhs.annotation?.title == rhs.annotation?.title
        && lhs.annotation?.subtitle == rhs.annotation?.subtitle
        && lhs.featureType == rhs.featureType
        && lhs.iconStyle == rhs.iconStyle
        && lhs.pointOfInterestCategory == rhs.pointOfInterestCategory
    }
}
