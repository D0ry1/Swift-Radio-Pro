//
//  OnDemandEpisode.swift
//  SwiftRadio
//

import Foundation

struct OnDemandEpisode: Codable {

    let trackId: String
    let downloadUrl: String
    let media: Media

    struct Media: Codable {
        let id: String?
        let art: String?
        let title: String?
        let text: String?
    }

    enum CodingKeys: String, CodingKey {
        case trackId = "track_id"
        case downloadUrl = "download_url"
        case media
    }

    var fullDownloadURL: String {
        Config.onDemandBaseURL + downloadUrl
    }

    var artworkURL: String {
        media.art ?? ""
    }

    func toRadioStation() -> RadioStation {
        RadioStation(
            name: media.title ?? "Unknown",
            streamURL: fullDownloadURL,
            imageURL: artworkURL,
            desc: media.text ?? ""
        )
    }
}
