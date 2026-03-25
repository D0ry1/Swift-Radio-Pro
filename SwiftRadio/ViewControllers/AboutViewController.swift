//
//  AboutViewController.swift
//  Swift Radio
//
//  Created by Matthew Fecher on 7/9/15.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//

import UIKit
import SwiftUI
import MessageUI

@MainActor
protocol AboutViewControllerDelegate: AnyObject {
    func didTapEmailButton(_ aboutViewController: AboutViewController)
    func didTapWebsiteButton(_ aboutViewController: AboutViewController)
}

class AboutViewController: UIHostingController<AboutView> {

    weak var delegate: AboutViewControllerDelegate?

    init() {
        var view = AboutView(onWebsite: {}, onEmail: {}, onDismiss: {})
        super.init(rootView: view)

        view.onWebsite = { [weak self] in
            guard let self else { return }
            delegate?.didTapWebsiteButton(self)
        }
        view.onEmail = { [weak self] in
            guard let self else { return }
            delegate?.didTapEmailButton(self)
        }
        view.onDismiss = { [weak self] in
            self?.dismiss(animated: true)
        }
        self.rootView = view
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - MFMailComposeViewController Delegate

extension AboutViewController: @preconcurrency MFMailComposeViewControllerDelegate {

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
