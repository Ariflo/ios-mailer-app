//
//  CustomRefreshableScrollView.swift
//  Addressable
//
//  Created by Ari on 1/4/21.
//

import SwiftUI

public struct CustomRefreshableScrollView<Content: View>: UIViewRepresentable {
    var size: CGSize
    var viewBuilder: () -> Content
    var handleRefreshControl: () -> Void

    public init(@ViewBuilder viewBuilder: @escaping () -> Content, size: CGSize, handleRefreshControl: @escaping () -> Void) {
        self.size = size
        self.viewBuilder = viewBuilder
        self.handleRefreshControl = handleRefreshControl
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self, handleRefreshControl: handleRefreshControl)
    }

    public func makeUIView(context: Context) -> UIScrollView {
        let control = UIScrollView()
        control.refreshControl = UIRefreshControl()
        control.refreshControl?.addTarget(context.coordinator, action:
                                            #selector(Coordinator.handleRefreshControl),
                                          for: .valueChanged)
        return control
    }

    public func updateUIView(_ control: UIScrollView, context: Context) {
        if let child = context.coordinator.child {
            child.removeFromParent()
        }

        let child = UIHostingController(rootView: viewBuilder())
        // TODO: Setting Height to the size of the container here is making it
        // hard to see the bottom of views with lists, need alternative solution
        child.view.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        control.addSubview(child.view)
        context.coordinator.child = child
    }

    public class Coordinator: NSObject {
        var control: CustomRefreshableScrollView
        var child: UIViewController?
        private var _handleRefreshControl: () -> Void

        init(_ control: CustomRefreshableScrollView, handleRefreshControl: @escaping () -> Void) {
            self.control = control
            self._handleRefreshControl = handleRefreshControl
        }

        @objc func handleRefreshControl(sender: UIRefreshControl) {
            sender.endRefreshing()
            _handleRefreshControl()
        }
    }
}
