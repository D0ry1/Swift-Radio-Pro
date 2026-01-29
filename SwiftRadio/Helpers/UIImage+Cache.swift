//
//  UIImage+Cache.swift
//  SwiftRadio
//
//  Created by Fethi El Hassasna on 2022-11-01.
//  Copyright © 2022 matthewfecher.com. All rights reserved.
//

import UIKit

extension UIImage {

    static func image(from url: URL?) async -> UIImage? {
        guard let url = url else {
            return nil
        }

        let cache = URLCache.shared
        let request = URLRequest(url: url)

        if let data = cache.cachedResponse(for: request)?.data, let image = UIImage(data: data) {
            return image
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  200...299 ~= httpResponse.statusCode,
                  let image = UIImage(data: data) else {
                return nil
            }

            let cachedData = CachedURLResponse(response: httpResponse, data: data)
            cache.storeCachedResponse(cachedData, for: request)

            return image
        } catch {
            return nil
        }
    }
}
