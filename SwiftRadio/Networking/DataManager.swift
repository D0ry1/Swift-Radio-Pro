//
//  DataManager.swift
//  Swift Radio
//
//  Created by Matthew Fecher on 3/24/15.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//

import UIKit

enum DataError: Error {
    case urlNotValid, dataNotValid, dataNotFound, fileNotFound, httpResponseNotValid
}

struct DataManager {

    static func getStations() async throws -> [RadioStation] {
        let data: Data

        if Config.useLocalStations {
            data = try await loadLocal()
        } else {
            data = try await loadHttp()
        }

        return try decode(data)
    }

    private static func decode(_ data: Data) throws -> [RadioStation] {
        if Config.debugLog { print("Stations JSON Found") }

        let jsonDictionary = try JSONDecoder().decode([String: [RadioStation]].self, from: data)

        guard let stations = jsonDictionary["station"] else {
            throw DataError.dataNotValid
        }

        return stations
    }

    // Load local JSON Data
    private static func loadLocal() async throws -> Data {
        guard let filePathURL = Bundle.main.url(forResource: "stations", withExtension: "json") else {
            if Config.debugLog { print("The local JSON file could not be found") }
            throw DataError.fileNotFound
        }

        return try Data(contentsOf: filePathURL, options: .uncached)
    }

    // Load http JSON Data
    private static func loadHttp() async throws -> Data {
        guard let url = URL(string: Config.stationsURL) else {
            if Config.debugLog { print("stationsURL not a valid URL") }
            throw DataError.urlNotValid
        }

        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData

        let session = URLSession(configuration: config)

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
            if Config.debugLog { print("API: HTTP status code has unexpected value") }
            throw DataError.httpResponseNotValid
        }

        return data
    }
}
