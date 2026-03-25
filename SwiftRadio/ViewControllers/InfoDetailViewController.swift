//
//  InfoDetailViewController.swift
//  Swift Radio
//
//  Created by Matthew Fecher on 7/9/15.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//

import UIKit
import SwiftUI

@MainActor
class InfoDetailViewController: UIHostingController<InfoDetailView> {

    init(station: RadioStation) {
        var view = InfoDetailView(station: station, onDismiss: {})
        super.init(rootView: view)

        view.onDismiss = { [weak self] in
            _ = self?.navigationController?.popViewController(animated: true)
        }
        self.rootView = view
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
