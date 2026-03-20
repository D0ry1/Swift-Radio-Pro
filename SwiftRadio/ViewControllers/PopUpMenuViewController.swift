//
//  PopUpMenuViewController.swift
//  Swift Radio
//
//  Created by Matthew Fecher on 7/9/15.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//

import UIKit

@MainActor
protocol PopUpMenuViewControllerDelegate: AnyObject {
    func didTapWebsiteButton(_ popUpMenuViewController: PopUpMenuViewController)
    func didTapAboutButton(_ popUpMenuViewController: PopUpMenuViewController)
    func didTapPreviousShowsButton(_ popUpMenuViewController: PopUpMenuViewController)
}

@MainActor
class PopUpMenuViewController: UIViewController {

    weak var delegate: PopUpMenuViewControllerDelegate?

    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var backgroundView: UIImageView!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        modalPresentationStyle = .custom
    }

    // MARK: - ViewDidLoad

    override func viewDidLoad() {
        super.viewDidLoad()

        // Round corners
        popupView.layer.cornerRadius = 10

        // Set background color to clear
        view.backgroundColor = UIColor.clear

        // Add gesture recognizer to dismiss view when touched
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(closeButtonPressed))
        backgroundView.isUserInteractionEnabled = true
        backgroundView.addGestureRecognizer(gestureRecognizer)

        // Add "Previous Shows" button programmatically
        addPreviousShowsButton()
    }

    private func addPreviousShowsButton() {
        let button = UIButton(type: .system)
        button.setTitle("Previous Shows", for: .normal)
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        button.backgroundColor = UIColor(red: 0.17, green: 0.42, blue: 0.60, alpha: 1.0)
        button.tintColor = .white
        button.layer.cornerRadius = 4
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(previousShowsButtonPressed), for: .touchUpInside)

        popupView.addSubview(button)

        // Find and increase the popup height constraint
        for constraint in popupView.constraints where constraint.firstAttribute == .height {
            constraint.constant += 46
        }

        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 27),
            button.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -27),
            button.bottomAnchor.constraint(equalTo: popupView.bottomAnchor, constant: -14),
            button.heightAnchor.constraint(equalToConstant: 32)
        ])
    }

    // MARK: - IBActions

    @IBAction func closeButtonPressed() {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func websiteButtonPressed(_ sender: UIButton) {
        delegate?.didTapWebsiteButton(self)
    }

    @IBAction func aboutButtonPressed(_ sender: Any) {
        delegate?.didTapAboutButton(self)
    }

    @objc func previousShowsButtonPressed() {
        delegate?.didTapPreviousShowsButton(self)
    }
}
