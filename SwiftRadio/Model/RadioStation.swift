//
//  RadioStation.swift
//  Swift Radio
//
//  Created by Matthew Fecher on 7/4/15.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//

import UIKit
import FRadioPlayer

// Radio Station

struct RadioStation: Codable, Sendable {

    var name: String
    var streamURL: String
    var imageURL: String
    var desc: String
    var longDesc: String

    init(name: String, streamURL: String, imageURL: String, desc: String, longDesc: String = "") {
        self.name = name
        self.streamURL = streamURL
        self.imageURL = imageURL
        self.desc = desc
        self.longDesc = longDesc
    }
}

extension RadioStation {
    var shoutout: String {
        "I'm listening to \(name) via \(Bundle.main.appName) app"
    }
}

extension RadioStation: Equatable {

    static func == (lhs: RadioStation, rhs: RadioStation) -> Bool {
        return (lhs.name == rhs.name) && (lhs.streamURL == rhs.streamURL) && (lhs.imageURL == rhs.imageURL) && (lhs.desc == rhs.desc) && (lhs.longDesc == rhs.longDesc)
    }
}

extension RadioStation {

    func getImage() async -> UIImage {
        if imageURL.hasPrefix("http"), let url = URL(string: imageURL) {
            // load current station image from network
            let image = await UIImage.image(from: url)
            return image ?? UIImage(named: "stationImage") ?? UIImage()
        } else {
            // load local station image
            return UIImage(named: imageURL) ?? UIImage(named: "stationImage") ?? UIImage()
        }
    }
}

extension RadioStation {

    @MainActor
    var trackName: String {
        FRadioPlayer.shared.currentMetadata?.trackName ?? name
    }

    @MainActor
    var artistName: String {
        FRadioPlayer.shared.currentMetadata?.artistName ?? desc
    }
}
