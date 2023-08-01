//
//  SwiftUIView.swift
//  
//
//  Created by Adrian Chavez on 8/1/23.
//

import SwiftUI
import MapKit

enum Pins {
    static var defaultCoord = CLLocationCoordinate2D(latitude: 41.886, longitude: -87.679)
    static var defaultSpan = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
}

struct SwiftUIView: View {
    @EnvironmentObject private var viewModel: LocationsViewModel
    // Initialise to a size proportional to the screen dimensions.
    @State private var width = UIScreen.main.bounds.size.width / 3.5
    @State private var height = UIScreen.main.bounds.size.height / 1.5
    @State var mapRegion: MKCoordinateRegion?
    @State var dragging: Bool = false
    @State var updates: Int = 0
    @State private var lastTask: DispatchWorkItem?
    @State var lastRegion = MKCoordinateRegion()
    @State private var selected = Set<String>() {
        didSet {
            print("\(selected.map({$0}))")
        }
    }
    
    var body: some View {
        ZStack {
            Text("test")
            Map(coordinateRegion: $viewModel.region, annotationItems: viewModel.locations, selectedItems: $selected) { location in
                ViewMapAnnotation(coordinate: location.coordinate, clusteringIdentifier: nil) { selected in
                    MapViewPin(isSelected: selected, number: 1)
                } clusterContent: { bool, annotations in
                    MapViewPin(isSelected: bool, number: annotations.count)
                }
            }
        }
        //        Map(
        //            coordinateRegion: $viewModel.region,
        //            type: .standard,
        //            pointOfInterestFilter: .excludingAll,
        //            informationVisibility: .default.union(.userLocation),
        //            interactionModes: [.pan, .rotate, .zoom],
        //            annotationItems: viewModel.locations,
        //            selectedItems: $selected) { location in
        //                ViewMapAnnotation(coordinate: location.coordinate, clusteringIdentifier: nil) { selected in
        //                    MapViewPin(isSelected: selected, number: 1)
        //                } clusterContent: { bool, annotations in
        //                    MapViewPin(isSelected: bool, number: annotations.count)
        //                }
        //            }
    }
}

struct MapViewPin: View {
    let isSelected: Bool
    let number: Int
    var body: some View {
        Image(isSelected ? "mapPin" : "mapPinCircle")
            .resizable()
            .scaledToFit()
            .frame(width: 30, height: 30)
            .padding(.bottom, isSelected ? 30 : 0)
            .onTapGesture {
                print("tapped")
            }
            .overlay(Text("\(number)").foregroundColor(.white))
    }
}

class LocationsViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    struct Location: Identifiable {
        let id = UUID()
        let name = "string \(Int.random(in: 1...100))"
        let coordinate: CLLocationCoordinate2D
    }
    
    @Published var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 41.886, longitude: -87.679), span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
    @Published var locations: [Location] = []
    @Published var isSearchingLocations: Bool = false
    @Published var bottomSheetHeight: CGFloat = 100.0 // static
    @Published var bottomSheetHeightCover: CGFloat = 100.0
    @Published var selectedLocation: Location? {
        didSet {
            guard let selectedLocation = selectedLocation else { return }
            //            showLocation(location: selectedLocation)
        }
    }
    @Published var needsUpdate: Bool = false
    
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIView()
    }
}
