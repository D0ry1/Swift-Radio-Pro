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

        // Enable and add handler for Play Command
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { event in
            FRadioPlayer.shared.play()
            return .success
        }

        // Enable pause command but use stop for live streams
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { event in
            FRadioPlayer.shared.stop()
            return .success
        }

        // Also enable stop command for completeness
        commandCenter.stopCommand.isEnabled = true
        commandCenter.stopCommand.addTarget { event in
            FRadioPlayer.shared.stop()
            return .success
        }

        // Enable toggle command (play/stop for live streams)
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { event in
            if FRadioPlayer.shared.isPlaying {
                FRadioPlayer.shared.stop()
            } else {
                FRadioPlayer.shared.play()
            }
            return .success
        }

        // Enable and add handler for Next Command
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { event in
            Task { @MainActor in
                StationsManager.shared.setNext()
            }
            return .success
        }

        // Enable and add handler for Previous Command
        commandCenter.previousTrackCommand.isEnabled = true
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
