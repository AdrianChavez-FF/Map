//
//  MapFeatureOptions.swift
//  
//
//  Created by Roman Blum on 05.11.22.
//

#if !os(watchOS)

public struct MapFeatureOptions: OptionSet {

    // MARK: Static Properties

    @available(iOS 16, *)
    @available(macOS, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public static let pointsOfInterest =
    MapFeatureOptions(rawValue: 1 << 0)

    @available(iOS 16, *)
    @available(macOS, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public static let territories = MapFeatureOptions(rawValue: 1 << 1)

    @available(iOS 16, *)
    @available(macOS, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public static let physicalFeatures = MapFeatureOptions(rawValue: 1 << 2)

    public static let all = {
        #if os(iOS)
        if #available(iOS 16, *) {
            return MapFeatureOptions(arrayLiteral: .pointsOfInterest, .territories, .physicalFeatures)
        } else {
            return MapFeatureOptions()
        }
        #else
        return MapFeatureOptions()
        #endif
    }()

    // MARK: Stored Properties

    public let rawValue: Int

    // MARK: Initialization

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

}

#endif
