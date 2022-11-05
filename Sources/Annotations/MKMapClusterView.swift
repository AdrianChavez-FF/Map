//
//  MKMapClusterView.swift
//  Map
//
//  Created by Roman Blum on 04.11.22.
//

#if !os(watchOS)

import MapKit
import SwiftUI

class MKMapClusterView<Content: View, ClusterContent: View>: MKAnnotationView {

    // MARK: Stored Properties

    private var controller: NativeHostingController<ClusterContent>?
    private var viewMapAnnotation: ViewMapAnnotation<Content, ClusterContent>?

    // MARK: Methods

    func setup(for mapAnnotation: ViewMapAnnotation<Content, ClusterContent>, clusterAnnotation: MKClusterAnnotation) {
        annotation = clusterAnnotation
        self.viewMapAnnotation = mapAnnotation
        self.displayPriority = .defaultHigh
        self.collisionMode = .circle
        updateContent(for: self.isSelected)
    }

    private func updateContent(for selectedState: Bool) {
        guard
            let contentView = viewMapAnnotation?.clusterContent,
            let memberCount = (annotation as? MKClusterAnnotation)?.memberAnnotations.count,
            let content = contentView(selectedState, memberCount)
        else {
            return
        }
        controller?.view.removeFromSuperview()
        let controller = NativeHostingController(rootView: content, ignoreSafeArea: true)
        addSubview(controller.view)
        let size = controller.view.intrinsicContentSize
        controller.view.center = .init(x: size.width / 2, y: size.height / 2)
        frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        self.controller = controller
    }

    // MARK: Overrides

    override func setSelected(_ selected: Bool, animated: Bool) {
        updateContent(for: selected)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if let controller = controller {
            bounds.size = controller.view.intrinsicContentSize
        }
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

#endif
