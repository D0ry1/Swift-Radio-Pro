//
//  NothingFoundCell.swift
//  SwiftRadio
//

import UIKit

class NothingFoundCell: UITableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none
        isAccessibilityElement = true
        accessibilityLabel = "Loading stations"

        let label = UILabel()
        label.text = "Loading Stations..."
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = UIColor(red: 0.849, green: 0.849, blue: 0.849, alpha: 1)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
