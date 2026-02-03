# The Gates Radio Station

A school radio station app for **The Gates Primary School**, built on the excellent [Swift Radio Pro](https://github.com/analogcode/Swift-Radio-Pro) open source project.

<p align="center">
    <img alt="Swift Radio" src="https://fethica.com/assets/img/web/swift-radio.jpg">
</p>

## Features

- **CarPlay Support** - Listen in your car with CarPlay integration
- Background audio playback
- Displays Artist, Track & Album Art on Lock Screen
- Streaming with metadata parsing (Track & Artist information)
- Album Art automatically downloaded from iTunes API
- Pull to Refresh stations
- Search stations
- "About" screen with email & website links
- Supports local or hosted station images

## Requirements

- Xcode 14+
- Swift 5.10
- iOS 15.0+

## Setup

The `Config.swift` file contains project configuration options.

## Stations

The `stations.json` file defines the radio stations. You can host this file on a server to update stations without resubmitting to the App Store.

Station fields:
- **name**: Station display name
- **streamURL**: The stream URL
- **imageURL**: Station image (local or hosted). Local images omit "http" prefix
- **desc**: Short 2-3 word description
- **longDesc**: Optional longer description for the info screen

## Credits

**Original Swift Radio Pro Team:**
- [Fethi El Hassasna](https://fethica.com) - Co-organizer & lead developer ([@fethica](https://twitter.com/fethica))
- [Matthew Fecher](http://matthewfecher.com) - Original creator, [AudioKit Pro](https://audiokitpro.com) ([@analogMatthew](http://twitter.com/analogMatthew))
- [All contributors](https://github.com/analogcode/Swift-Radio-Pro/graphs/contributors)

Forked and customized for The Gates Primary School.

## Libraries

- [FRadioPlayer](https://github.com/fethica/FRadioPlayer) - AVPlayer wrapper for streaming
- [Spring](https://github.com/MengTo/Spring) - Animation library

## FAQ

**Q: My radio station isn't playing?**
A: Check if the stream URL works in a browser. The stream may be offline.

**Q: Song names aren't appearing?**
A: Ensure your stream provider is sending metadata properly.

**Q: How do I support IPv6 networks?**
A: Use domain names (e.g., "http://mystream.com/rock") instead of IP addresses for stream URLs.

## License

This project is based on [Swift Radio Pro](https://github.com/analogcode/Swift-Radio-Pro), an open source project. See the original repository for license details.
