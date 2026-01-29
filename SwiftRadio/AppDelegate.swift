//
//  AppDelegate.swift
//  Swift Radio
//
//  Created by Matthew Fecher on 7/2/15.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//

import UIKit
import MediaPlayer
import FRadioPlayer

@main
@MainActor
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var coordinator: MainCoordinator?

    // CarPlay
    var playableContentManager: MPPlayableContentManager?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // FRadioPlayer config
        FRadioPlayer.shared.isAutoPlay = true
        FRadioPlayer.shared.enableArtwork = true
        FRadioPlayer.shared.artworkAPI = iTunesAPI(artworkSize: 600)

        // AudioSession & RemotePlay
        activateAudioSession()
        setupRemoteCommandCenter()
        UIApplication.shared.beginReceivingRemoteControlEvents()

        // Make status bar white
        UINavigationBar.appearance().barStyle = .black
        UINavigationBar.appearance().tintColor = .white
        UINavigationBar.appearance().prefersLargeTitles = true

        // `CarPlay` is defined only in SwiftRadio-CarPlay target:
        // Build Settings > Swift Compiler - Custom Flags
        #if CarPlay
        setupCarPlay()
        #endif

        // Start the coordinator
        coordinator = MainCoordinator(navigationController: UINavigationController())

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = coordinator?.navigationController
        window?.makeKeyAndVisible()

        coordinator?.start()

        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        UIApplication.shared.endReceivingRemoteControlEvents()
    }

    // MARK: - Remote Controls

    private func setupRemoteCommandCenter() {
        // Get the shared MPRemoteCommandCenter
        let commandCenter = MPRemoteCommandCenter.shared()

        // Add handler for Play Command
        commandCenter.playCommand.addTarget { event in
            FRadioPlayer.shared.play()
            return .success
        }

        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { event in
            FRadioPlayer.shared.pause()
            return .success
        }

        // Add handler for Toggle Command
        commandCenter.togglePlayPauseCommand.addTarget { event in
            FRadioPlayer.shared.togglePlaying()
            return .success
        }

        // Add handler for Next Command
        commandCenter.nextTrackCommand.addTarget { event in
            Task { @MainActor in
                StationsManager.shared.setNext()
            }
            return .success
        }

        // Add handler for Previous Command
        commandCenter.previousTrackCommand.addTarget { event in
            Task { @MainActor in
                StationsManager.shared.setPrevious()
            }
            return .success
        }
    }

    // MARK: - Activate Audio Session

    private func activateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error {
            if Config.debugLog {
                print("audioSession could not be activated: \(error.localizedDescription)")
            }
        }
    }
}
