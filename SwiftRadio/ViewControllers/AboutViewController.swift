//
//  AboutViewController.swift
//  Swift Radio
//
//  Created by Matthew Fecher on 7/9/15.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//

import UIKit
import MessageUI

@MainActor
protocol AboutViewControllerDelegate: AnyObject {
    func didTapEmailButton(_ aboutViewController: AboutViewController)
    func didTapWebsiteButton(_ aboutViewController: AboutViewController)
}

class AboutViewController: BaseController {

    weak var delegate: AboutViewControllerDelegate?

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI

    private let logoImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "logo"))
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.widthAnchor.constraint(equalToConstant: 120).isActive = true
        iv.heightAnchor.constraint(equalToConstant: 80).isActive = true
        return iv
    }()

    private let headlineLabel: UILabel = {
        let label = UILabel()
        label.text = "Xcode / Swift"
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.heightAnchor.constraint(equalToConstant: 25).isActive = true
        return label
    }()

    private let subheadLabel: UILabel = {
        let label = UILabel()
        label.text = "Radio App"
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let featuresTextView: UITextView = {
        let tv = UITextView()
        tv.text = """
        FEATURES: + Displays Artist, Track and Album/Station Art on lock screen.
        + Background Audio performance
        +iTunes API integration to automatically download album art
        + Loads and parses Icecast metadata (i.e. artist & track names)
        + Ability to update stations from server without resubmitting to the app store.
        """
        tv.font = .preferredFont(forTextStyle: .body)
        tv.textColor = .white
        tv.backgroundColor = .clear
        tv.isEditable = false
        tv.isSelectable = false
        tv.isScrollEnabled = false
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private lazy var websiteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Website", for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.tintColor = .white
        button.addTarget(self, action: #selector(websiteButtonDidTouch), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var emailButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("email me", for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        button.tintColor = .white
        button.addTarget(self, action: #selector(emailButtonDidTouch), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var okayButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Okay", for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .body)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 0.204, green: 0.202, blue: 0.209, alpha: 1) // #343438
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 36).isActive = true
        button.addTarget(self, action: #selector(okayButtonPressed), for: .touchUpInside)
        return button
    }()

    // MARK: - Layout

    override func setupViews() {
        super.setupViews()

        let titleStack = UIStackView(arrangedSubviews: [headlineLabel, subheadLabel])
        titleStack.axis = .vertical
        titleStack.spacing = 8

        let headerStack = UIStackView(arrangedSubviews: [logoImageView, titleStack])
        headerStack.alignment = .center
        headerStack.spacing = 8
        headerStack.translatesAutoresizingMaskIntoConstraints = false

        let contactStack = UIStackView(arrangedSubviews: [websiteButton, emailButton])
        contactStack.axis = .vertical
        contactStack.alignment = .center
        contactStack.spacing = 4

        let buttonsStack = UIStackView(arrangedSubviews: [contactStack, okayButton])
        buttonsStack.axis = .vertical
        buttonsStack.spacing = 8
        buttonsStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(headerStack)
        view.addSubview(featuresTextView)
        view.addSubview(buttonsStack)

        let safeArea = view.safeAreaLayoutGuide
        let margins = view.layoutMarginsGuide

        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            headerStack.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16),
            headerStack.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16),

            featuresTextView.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 8),
            featuresTextView.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            featuresTextView.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            featuresTextView.heightAnchor.constraint(lessThanOrEqualToConstant: 350),

            buttonsStack.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16),
            buttonsStack.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16),
            buttonsStack.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -20),

            buttonsStack.topAnchor.constraint(greaterThanOrEqualTo: featuresTextView.bottomAnchor, constant: 8)
        ])
    }

    // MARK: - Actions

    @objc private func websiteButtonDidTouch(_ sender: UIButton) {
        delegate?.didTapWebsiteButton(self)
    }

    @objc private func emailButtonDidTouch(_ sender: UIButton) {
        delegate?.didTapEmailButton(self)
    }

    @objc private func okayButtonPressed() {
        dismiss(animated: true)
    }
}

// MARK: - MFMailComposeViewController Delegate

extension AboutViewController: @preconcurrency MFMailComposeViewControllerDelegate {

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
