//
//  PopUpMenuViewController.swift
//  Swift Radio
//
//  Created by Matthew Fecher on 7/9/15.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//

import UIKit
import Spring

@MainActor
protocol PopUpMenuViewControllerDelegate: AnyObject {
    func didTapWebsiteButton(_ popUpMenuViewController: PopUpMenuViewController)
    func didTapAboutButton(_ popUpMenuViewController: PopUpMenuViewController)
    func didTapPreviousShowsButton(_ popUpMenuViewController: PopUpMenuViewController)
}

@MainActor
class PopUpMenuViewController: UIViewController {

    weak var delegate: PopUpMenuViewControllerDelegate?

    private let backgroundView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "background"))
        iv.contentMode = .scaleToFill
        iv.isUserInteractionEnabled = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.isAccessibilityElement = true
        iv.accessibilityLabel = "Close menu"
        iv.accessibilityTraits = .button
        return iv
    }()

    private let popupView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 10
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "btn-close"), for: .normal)
        button.tintColor = UIColor(red: 0.206, green: 0.502, blue: 0.709, alpha: 1) // #3480B5
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 16).isActive = true
        button.heightAnchor.constraint(equalToConstant: 16).isActive = true
        button.addTarget(self, action: #selector(closeButtonPressed), for: .touchUpInside)
        button.accessibilityLabel = "Close"
        return button
    }()

    private let logoImageView: SpringImageView = {
        let iv = SpringImageView(image: UIImage(named: "swift-radio-black"))
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.widthAnchor.constraint(equalToConstant: 180).isActive = true
        iv.heightAnchor.constraint(equalToConstant: 70).isActive = true
        return iv
    }()

    private lazy var aboutButton: SpringButton = {
        let button = SpringButton(type: .system)
        button.setTitle("About", for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .body)
        button.backgroundColor = UIColor(red: 0.247, green: 0.563, blue: 0.811, alpha: 1)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 32).isActive = true
        button.widthAnchor.constraint(greaterThanOrEqualToConstant: 86).isActive = true
        button.addTarget(self, action: #selector(aboutButtonPressed), for: .touchUpInside)
        return button
    }()

    private lazy var websiteButton: SpringButton = {
        let button = SpringButton(type: .system)
        button.setTitle("Website", for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .body)
        button.backgroundColor = UIColor(red: 0.206, green: 0.492, blue: 0.709, alpha: 1)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 32).isActive = true
        button.widthAnchor.constraint(greaterThanOrEqualToConstant: 86).isActive = true
        button.addTarget(self, action: #selector(websiteButtonPressed), for: .touchUpInside)
        return button
    }()

    private let openSourceLabel: UILabel = {
        let label = UILabel()
        label.text = "Open Source Project"
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let creditsLabel: UILabel = {
        let label = UILabel()
        label.text = "Matt Fecher & Fethi El Hassasna"
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = UIColor(white: 0, alpha: 0.5)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var previousShowsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Previous Shows", for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .body)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.backgroundColor = UIColor(red: 0.17, green: 0.42, blue: 0.60, alpha: 1.0)
        button.tintColor = .white
        button.layer.cornerRadius = 4
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(previousShowsButtonPressed), for: .touchUpInside)
        button.accessibilityHint = "Shows previously aired episodes"
        return button
    }()

    // MARK: - Init

    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .custom
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    override func loadView() {
        super.loadView()

        view.backgroundColor = UIColor(white: 0, alpha: 0.5)

        view.addSubview(backgroundView)
        view.addSubview(popupView)

        // Background - full bleed
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(closeButtonPressed))
        backgroundView.addGestureRecognizer(gestureRecognizer)

        // Close button
        popupView.addSubview(closeButton)

        // Button row
        let buttonsStack = UIStackView(arrangedSubviews: [aboutButton, websiteButton])
        buttonsStack.distribution = .fillEqually

        // Content stack
        let contentStack = UIStackView(arrangedSubviews: [logoImageView, buttonsStack, openSourceLabel, creditsLabel])
        contentStack.axis = .vertical
        contentStack.alignment = .center
        contentStack.spacing = 10
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        popupView.addSubview(contentStack)
        popupView.addSubview(previousShowsButton)

        NSLayoutConstraint.activate([
            popupView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            popupView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            popupView.widthAnchor.constraint(equalToConstant: 250),

            closeButton.topAnchor.constraint(equalTo: popupView.topAnchor, constant: 8),
            closeButton.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 8),

            contentStack.topAnchor.constraint(equalTo: popupView.topAnchor, constant: 27),
            contentStack.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 27),
            contentStack.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -27),

            previousShowsButton.topAnchor.constraint(equalTo: contentStack.bottomAnchor, constant: 14),
            previousShowsButton.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 27),
            previousShowsButton.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -27),
            previousShowsButton.heightAnchor.constraint(equalToConstant: 32),
            previousShowsButton.bottomAnchor.constraint(equalTo: popupView.bottomAnchor, constant: -14)
        ])
    }

    // MARK: - ViewDidLoad

    override func viewDidLoad() {
        super.viewDidLoad()

        view.accessibilityViewIsModal = true

        // Animations
        logoImageView.autostart = true
        logoImageView.animation = "zoomIn"
        logoImageView.delay = 0.3

        aboutButton.autostart = true
        aboutButton.animation = "slideRight"
        aboutButton.delay = 0.6
        aboutButton.damping = 1

        websiteButton.autostart = true
        websiteButton.animation = "slideLeft"
        websiteButton.delay = 0.6
        websiteButton.damping = 1
    }

    // MARK: - Actions

    @objc private func closeButtonPressed() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func websiteButtonPressed(_ sender: UIButton) {
        delegate?.didTapWebsiteButton(self)
    }

    @objc private func aboutButtonPressed(_ sender: Any) {
        delegate?.didTapAboutButton(self)
    }

    @objc func previousShowsButtonPressed() {
        delegate?.didTapPreviousShowsButton(self)
    }
}
