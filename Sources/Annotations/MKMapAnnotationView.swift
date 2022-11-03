//
//  MKMapAnnotationView.swift
//  Map
//
//  Created by Paul Kraft on 23.04.22.
//

#if !os(watchOS)

import MapKit
import SwiftUI

class MKMapAnnotationView<Content: View, ClusterContent: View>: MKAnnotationView {

    // MARK: Stored Properties

    private var controller: NativeHostingController<Content>?
    private var viewMapAnnotation: ViewMapAnnotation<Content, ClusterContent>?

    // MARK: Methods

    func setup(for mapAnnotation: ViewMapAnnotation<Content, ClusterContent>) {
        annotation = mapAnnotation.annotation
        self.viewMapAnnotation = mapAnnotation
        self.clusteringIdentifier = mapAnnotation.clusteringIdentifier
        self.displayPriority = .defaultLow
        self.collisionMode = .rectangle
        updateContent(for: self.isSelected)
    }
    
    private func updateContent(for selectedState: Bool) {
        guard let contentView = viewMapAnnotation?.content else {
            return
        }
        controller?.view.removeFromSuperview()
        let controller = NativeHostingController(rootView: contentView(selectedState), ignoreSafeArea: true)
        addSubview(controller.view)
        self.collisionMode = .circle
        let size = controller.view.intrinsicContentSize
        frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        self.controller = controller
    }

    // MARK: Overrides

    override func setSelected(_ selected: Bool, animated: Bool) {
        updateContent(for: selected)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        #if canImport(UIKit)
        controller?.willMove(toParent: nil)
        #endif
        controller?.view.removeFromSuperview()
        controller?.removeFromParent()
        controller = nil
    }
}

class MKMapClusterView<ClusterContent: View>: MKAnnotationView {

    init(clusterContent: ClusterContent, clusterAnnotation: MKClusterAnnotation) {
        super.init(annotation: clusterAnnotation, reuseIdentifier: "customClusterReuseIdentifier")

        let content = clusterContent
        let controller = NativeHostingController(rootView: content, ignoreSafeArea: true)

        self.addSubview(controller.view)
        self.displayPriority = .defaultHigh
        self.collisionMode = .circle
        
        let size = controller.view.intrinsicContentSize
        frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
    }

    required init?(coder aDecoder: NSCoder) { nil }
}

#endif
