//
//  InfoDetailViewController.swift
//  Swift Radio
//
//  Created by Matthew Fecher on 7/9/15.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//

import UIKit

@MainActor
class InfoDetailViewController: BaseController {

    let station: RadioStation

    init(station: RadioStation) {
        self.station = station
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI

    private let stationImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.widthAnchor.constraint(equalToConstant: 110).isActive = true
        iv.heightAnchor.constraint(equalToConstant: 70).isActive = true
        return iv
    }()

    private let stationNameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let stationDescLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let stationLongDescTextView: UITextView = {
        let tv = UITextView()
        tv.font = .preferredFont(forTextStyle: .body)
        tv.textColor = .white
        tv.backgroundColor = .clear
        tv.isEditable = false
        tv.isScrollEnabled = false
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private lazy var okayButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Okay", for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .body)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 0.149, green: 0.149, blue: 0.153, alpha: 1) // #262627
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 36).isActive = true
        button.addTarget(self, action: #selector(okayButtonPressed), for: .touchUpInside)
        return button
    }()

    // MARK: - Layout

    override func setupViews() {
        super.setupViews()

        let titleStack = UIStackView(arrangedSubviews: [stationNameLabel, stationDescLabel])
        titleStack.axis = .vertical
        titleStack.spacing = 8

        let headerStack = UIStackView(arrangedSubviews: [stationImageView, titleStack])
        headerStack.alignment = .center
        headerStack.spacing = 8
        headerStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(headerStack)
        view.addSubview(stationLongDescTextView)
        view.addSubview(okayButton)

        let safeArea = view.safeAreaLayoutGuide
        let margins = view.layoutMarginsGuide

        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 20),
            headerStack.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16),
            headerStack.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16),

            stationLongDescTextView.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 16),
            stationLongDescTextView.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            stationLongDescTextView.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            stationLongDescTextView.heightAnchor.constraint(lessThanOrEqualToConstant: 340),

            okayButton.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            okayButton.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            okayButton.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -20),

            okayButton.topAnchor.constraint(greaterThanOrEqualTo: stationLongDescTextView.bottomAnchor, constant: 8)
        ])
    }

    // MARK: - ViewDidLoad

    override func viewDidLoad() {
        super.viewDidLoad()
        setupStationText()
        setupStationLogo()
        configureAccessibility()
    }

    // MARK: - UI Helpers

    func setupStationText() {
        stationNameLabel.text = station.name
        stationDescLabel.text = station.desc

        if station.longDesc == "" {
            loadDefaultText()
        } else {
            stationLongDescTextView.text = station.longDesc
        }
    }

    func loadDefaultText() {
        stationLongDescTextView.text = "You are listening to Swift Radio. This is a sweet open source project. Tell your friends, swiftly!"
    }

    func setupStationLogo() {
        Task {
            let image = await station.getImage()
            stationImageView.image = image
        }
        stationImageView.applyShadow()
    }

    // MARK: - Accessibility

    private func configureAccessibility() {
        stationImageView.isAccessibilityElement = true
        stationImageView.accessibilityLabel = "Logo for \(station.name)"
        stationImageView.accessibilityTraits = .image

        stationNameLabel.accessibilityTraits = .header

        okayButton.accessibilityLabel = "Close"
        okayButton.accessibilityHint = "Returns to the now playing screen"
    }

    // MARK: - Actions

    @objc private func okayButtonPressed(_ sender: UIButton) {
        _ = navigationController?.popViewController(animated: true)
    }
}
