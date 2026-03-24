//
//  NowPlayingViewController.swift
//  Swift Radio
//
//  Created by Matthew Fecher on 7/22/15.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//

import UIKit
import MediaPlayer
import AVKit
import Spring
import FRadioPlayer

@MainActor
protocol NowPlayingViewControllerDelegate: AnyObject {
    func didTapCompanyButton(_ nowPlayingViewController: NowPlayingViewController)
    func didTapInfoButton(_ nowPlayingViewController: NowPlayingViewController, station: RadioStation)
    func didTapShareButton(_ nowPlayingViewController: NowPlayingViewController, station: RadioStation, artworkURL: URL?)
}

@MainActor
class NowPlayingViewController: UIViewController {

    weak var delegate: NowPlayingViewControllerDelegate?

    // MARK: - IB UI

    @IBOutlet weak var albumHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var albumImageView: SpringImageView!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var playingButton: UIButton!
    @IBOutlet weak var songLabel: SpringLabel!
    @IBOutlet weak var stationDescLabel: UILabel!
    @IBOutlet weak var volumeParentView: UIView!
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var airPlayView: UIView!

    // MARK: - Properties

    private let player = FRadioPlayer.shared
    private let manager = StationsManager.shared

    var isNewStation = true
    var nowPlayingImageView: UIImageView!

    var mpVolumeSlider: UISlider?

    // MARK: - Scrub Bar UI

    private let scrubBar: UISlider = {
        let slider = UISlider()
        slider.minimumTrackTintColor = .white
        slider.maximumTrackTintColor = .white.withAlphaComponent(0.3)
        slider.setThumbImage(UIImage(named: "slider-ball"), for: .normal)
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.isHidden = true
        return slider
    }()

    private let currentTimeLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        label.textColor = .white.withAlphaComponent(0.7)
        label.text = "0:00"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()

    private let durationLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        label.textColor = .white.withAlphaComponent(0.7)
        label.textAlignment = .right
        label.text = "0:00"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()

    private var isScrubbing = false
    private var timeObserver: Any?
    private var volumeTopConstraint: NSLayoutConstraint?
    private let volumeTopDefault: CGFloat = 12
    private let volumeTopWithScrub: CGFloat = 56

    deinit {
        if let observer = timeObserver {
            player.avPlayer?.removeTimeObserver(observer)
        }
    }

    // MARK: - ViewDidLoad

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .never

        player.addObserver(self)
        manager.addObserver(self)

        // Create Now Playing BarItem
        createNowPlayingAnimation()

        // Set AlbumArtwork Constraints
        optimizeForDeviceSize()

        // Set View Title
        self.title = manager.currentStation?.name

        // Set UI

        stationDescLabel.text = manager.currentStation?.desc
        stationDescLabel.isHidden = player.currentMetadata != nil

        // Check for station change
        if isNewStation {
            stationDidChange()
        } else {
            updateTrackArtwork()
            playerStateDidChange(player.state, animate: false)
        }

        // Setup volumeSlider
        setupVolumeSlider()

        // Setup AirPlayButton
        setupAirPlayButton()

        // Hide / Show Next/Previous buttons
        previousButton.isHidden = Config.hideNextPreviousButtons
        nextButton.isHidden = Config.hideNextPreviousButtons

        // Setup scrub bar
        setupScrubBar()

        isPlayingDidChange(player.isPlaying)

        // Accessibility
        configureAccessibility()
    }

    // MARK: - Accessibility

    private func configureAccessibility() {
        albumImageView.isAccessibilityElement = true
        albumImageView.accessibilityLabel = "Album artwork"
        albumImageView.accessibilityTraits = .image

        playingButton.accessibilityLabel = player.isPlaying ? "Pause" : "Play"
        playingButton.accessibilityHint = "Double tap to toggle playback"

        previousButton.accessibilityLabel = "Previous station"
        nextButton.accessibilityLabel = "Next station"

        songLabel.accessibilityTraits = .updatesFrequently
        songLabel.adjustsFontForContentSizeCategory = true
        artistLabel.adjustsFontForContentSizeCategory = true
        stationDescLabel.adjustsFontForContentSizeCategory = true

        scrubBar.accessibilityLabel = "Playback position"

        currentTimeLabel.isAccessibilityElement = false
        durationLabel.isAccessibilityElement = false

        nowPlayingImageView.isAccessibilityElement = false
    }

    // MARK: - Setup

    func setupVolumeSlider() {
        // Note: This slider implementation uses a MPVolumeView
        // The volume slider only works in devices, not the simulator.
        for subview in MPVolumeView().subviews {
            guard let volumeSlider = subview as? UISlider else { continue }
            mpVolumeSlider = volumeSlider
        }

        guard let mpVolumeSlider = mpVolumeSlider else { return }

        volumeParentView.addSubview(mpVolumeSlider)

        mpVolumeSlider.translatesAutoresizingMaskIntoConstraints = false
        mpVolumeSlider.leftAnchor.constraint(equalTo: volumeParentView.leftAnchor).isActive = true
        mpVolumeSlider.rightAnchor.constraint(equalTo: volumeParentView.rightAnchor).isActive = true
        mpVolumeSlider.centerYAnchor.constraint(equalTo: volumeParentView.centerYAnchor).isActive = true

        mpVolumeSlider.setThumbImage(UIImage(named: "slider-ball"), for: .normal)
        mpVolumeSlider.accessibilityLabel = "Volume"
    }

    func setupAirPlayButton() {
        let airPlayButton = AVRoutePickerView(frame: airPlayView.bounds)
        airPlayButton.activeTintColor = .white
        airPlayButton.tintColor = .gray
        airPlayView.backgroundColor = .clear
        airPlayView.addSubview(airPlayButton)

        airPlayView.isAccessibilityElement = true
        airPlayView.accessibilityLabel = "AirPlay"
        airPlayView.accessibilityHint = "Double tap to choose audio output"
        airPlayView.accessibilityTraits = .button
    }

    // MARK: - Scrub Bar

    func setupScrubBar() {
        view.addSubview(scrubBar)
        view.addSubview(currentTimeLabel)
        view.addSubview(durationLabel)

        // Position scrub bar between the controls and the volume slider
        let volumeStack = volumeParentView.superview!
        let controlsStack = playingButton.superview!

        // Find the storyboard constraint: volumeStack.top == controlsStack.bottom + 12
        for constraint in view.constraints {
            if constraint.firstItem === volumeStack && constraint.firstAttribute == .top &&
               constraint.secondItem === controlsStack && constraint.secondAttribute == .bottom {
                volumeTopConstraint = constraint
                break
            }
        }

        NSLayoutConstraint.activate([
            scrubBar.leadingAnchor.constraint(equalTo: volumeStack.leadingAnchor),
            scrubBar.trailingAnchor.constraint(equalTo: volumeStack.trailingAnchor),
            scrubBar.topAnchor.constraint(equalTo: controlsStack.bottomAnchor, constant: 12),

            currentTimeLabel.leadingAnchor.constraint(equalTo: scrubBar.leadingAnchor),
            currentTimeLabel.topAnchor.constraint(equalTo: scrubBar.bottomAnchor, constant: 2),

            durationLabel.trailingAnchor.constraint(equalTo: scrubBar.trailingAnchor),
            durationLabel.topAnchor.constraint(equalTo: scrubBar.bottomAnchor, constant: 2)
        ])

        scrubBar.addTarget(self, action: #selector(scrubBarValueChanged(_:)), for: .valueChanged)
        scrubBar.addTarget(self, action: #selector(scrubBarTouchDown(_:)), for: .touchDown)
        scrubBar.addTarget(self, action: #selector(scrubBarTouchUp(_:)), for: [.touchUpInside, .touchUpOutside])

        startTimeObserver()
    }

    private func startTimeObserver() {
        guard let avPlayer = player.avPlayer else { return }
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = avPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.updateScrubProgress()
            }
        }
    }

    private func stopTimeObserver() {
        if let observer = timeObserver, let avPlayer = player.avPlayer {
            avPlayer.removeTimeObserver(observer)
        }
        timeObserver = nil
    }

    private func updateScrubProgress() {
        let duration = player.itemDuration
        let current = player.itemCurrentTime
        let seekable = duration > 0

        let wasHidden = scrubBar.isHidden
        scrubBar.isHidden = !seekable
        currentTimeLabel.isHidden = !seekable
        durationLabel.isHidden = !seekable

        // Push volume slider down when scrub bar appears
        if wasHidden != scrubBar.isHidden {
            volumeTopConstraint?.constant = seekable ? volumeTopWithScrub : volumeTopDefault
            view.layoutIfNeeded()
        }

        guard seekable, !isScrubbing else { return }

        scrubBar.value = Float(current / duration)
        currentTimeLabel.text = formatTime(current)
        durationLabel.text = formatTime(duration)
        scrubBar.accessibilityValue = "\(formatTime(current)) of \(formatTime(duration))"
    }

    @objc private func scrubBarValueChanged(_ slider: UISlider) {
        let time = TimeInterval(slider.value) * player.itemDuration
        currentTimeLabel.text = formatTime(time)
        scrubBar.accessibilityValue = "\(formatTime(time)) of \(formatTime(player.itemDuration))"
    }

    @objc private func scrubBarTouchDown(_ slider: UISlider) {
        isScrubbing = true
    }

    @objc private func scrubBarTouchUp(_ slider: UISlider) {
        let time = TimeInterval(slider.value) * player.itemDuration
        player.seek(to: time)
        isScrubbing = false
    }

    private func formatTime(_ time: TimeInterval) -> String {
        guard time.isFinite, time >= 0 else { return "0:00" }
        let totalSeconds = Int(time)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    func stationDidChange() {
        albumImageView.image = nil
        albumImageView.accessibilityLabel = "Album artwork for \(manager.currentStation?.name ?? "unknown station")"
        Task {
            if let station = manager.currentStation {
                let image = await station.getImage()
                albumImageView.image = image
            }
        }
        stationDescLabel.text = manager.currentStation?.desc
        stationDescLabel.isHidden = player.currentArtworkURL != nil
        title = manager.currentStation?.name
        updateLabels()

        // Reset scrub bar for new station/episode
        scrubBar.value = 0
        currentTimeLabel.text = "0:00"
        durationLabel.text = "0:00"

        // Restart time observer in case AVPlayer was recreated
        stopTimeObserver()
        startTimeObserver()
    }

    // MARK: - Player Controls (Play/Pause/Volume)

    @IBAction func playingPressed(_ sender: Any) {
        player.togglePlaying()
    }

    @IBAction func stopPressed(_ sender: Any) {
        player.stop()
    }

    @IBAction func nextPressed(_ sender: Any) {
        manager.setNext()
    }

    @IBAction func previousPressed(_ sender: Any) {
        manager.setPrevious()
    }

    // Update track with new artwork
    func updateTrackArtwork() {
        guard let artworkURL = player.currentArtworkURL else {
            Task {
                if let station = manager.currentStation {
                    let image = await station.getImage()
                    albumImageView.image = image
                    stationDescLabel.isHidden = false
                }
            }
            return
        }

        Task {
            await albumImageView.load(url: artworkURL)
            albumImageView.animation = "wobble"
            albumImageView.duration = 2
            albumImageView.animate()
            stationDescLabel.isHidden = true

            // Force app to update display
            view.setNeedsDisplay()
        }
    }

    private func isPlayingDidChange(_ isPlaying: Bool) {
        playingButton.isSelected = isPlaying
        playingButton.accessibilityLabel = isPlaying ? "Pause" : "Play"
        startNowPlayingAnimation(isPlaying)
    }

    func playbackStateDidChange(_ playbackState: FRadioPlayer.PlaybackState, animate: Bool) {

        let message: String?

        switch playbackState {
        case .paused:
            message = "Station Paused..."
        case .playing:
            message = nil
        case .stopped:
            message = "Station Stopped..."
        }

        updateLabels(with: message, animate: animate)
        isPlayingDidChange(player.isPlaying)
    }

    func playerStateDidChange(_ state: FRadioPlayer.State, animate: Bool) {

        let message: String?

        switch state {
        case .loading:
            message = "Loading Station ..."
        case .urlNotSet:
            message = "Station URL not valide"
        case .readyToPlay, .loadingFinished:
            playbackStateDidChange(player.playbackState, animate: animate)
            return
        case .error:
            message = "Error Playing"
        }

        updateLabels(with: message, animate: animate)
    }

    // MARK: - UI Helper Methods

    func optimizeForDeviceSize() {

        // Adjust album size to fit iPhone 4s, 6s & 6s+
        let deviceHeight = self.view.bounds.height

        if deviceHeight == 480 {
            albumHeightConstraint.constant = 106
            view.updateConstraints()
        } else if deviceHeight == 667 {
            albumHeightConstraint.constant = 230
            view.updateConstraints()
        } else if deviceHeight > 667 {
            albumHeightConstraint.constant = 260
            view.updateConstraints()
        }
    }

    func updateLabels(with statusMessage: String? = nil, animate: Bool = true) {

        guard let statusMessage = statusMessage else {
            // Radio is (hopefully) streaming properly
            let trackName = manager.currentStation?.trackName
            let artistName = manager.currentStation?.artistName
            songLabel.text = trackName
            artistLabel.text = artistName
            shouldAnimateSongLabel(animate)

            if let trackName {
                UIAccessibility.post(notification: .announcement, argument: trackName)
            }
            return
        }

        // There's a an interruption or pause in the audio queue

        // Update UI only when it's not aleary updated
        guard songLabel.text != statusMessage else { return }

        songLabel.text = statusMessage
        artistLabel.text = manager.currentStation?.name

        UIAccessibility.post(notification: .announcement, argument: statusMessage)

        if animate {
            songLabel.animation = "flash"
            songLabel.repeatCount = 2
            songLabel.animate()
        }
    }

    // Animations

    func shouldAnimateSongLabel(_ animate: Bool) {
        // Animate if the Track has album metadata
        guard animate, player.currentMetadata != nil else { return }

        // songLabel animation
        songLabel.animation = "zoomIn"
        songLabel.duration = 1.5
        songLabel.damping = 1
        songLabel.animate()
    }

    func createNowPlayingAnimation() {
        // Setup ImageView
        nowPlayingImageView = UIImageView(image: UIImage(named: "NowPlayingBars-3"))
        nowPlayingImageView.autoresizingMask = []
        nowPlayingImageView.contentMode = UIView.ContentMode.center

        // Create Animation
        nowPlayingImageView.animationImages = AnimationFrames.createFrames()
        nowPlayingImageView.animationDuration = 0.7

        // Create Top BarButton
        let barButton = UIButton(type: .custom)
        barButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        barButton.addSubview(nowPlayingImageView)
        nowPlayingImageView.center = barButton.center

        let barItem = UIBarButtonItem(customView: barButton)
        self.navigationItem.rightBarButtonItem = barItem
    }

    func startNowPlayingAnimation(_ animate: Bool) {
        animate ? nowPlayingImageView.startAnimating() : nowPlayingImageView.stopAnimating()
    }

    @IBAction func infoButtonPressed(_ sender: UIButton) {
        guard let station = manager.currentStation else { return }
        delegate?.didTapInfoButton(self, station: station)
    }

    @IBAction func shareButtonPressed(_ sender: UIButton) {
        guard let station = manager.currentStation else { return }
        delegate?.didTapShareButton(self, station: station, artworkURL: player.currentArtworkURL)
    }

    @IBAction func handleCompanyButton(_ sender: Any) {
        delegate?.didTapCompanyButton(self)
    }
}

extension NowPlayingViewController: FRadioPlayerObserver {

    nonisolated func radioPlayer(_ player: FRadioPlayer, playerStateDidChange state: FRadioPlayer.State) {
        Task { @MainActor in
            playerStateDidChange(state, animate: true)
        }
    }

    nonisolated func radioPlayer(_ player: FRadioPlayer, playbackStateDidChange state: FRadioPlayer.PlaybackState) {
        Task { @MainActor in
            playbackStateDidChange(state, animate: true)
        }
    }

    nonisolated func radioPlayer(_ player: FRadioPlayer, metadataDidChange metadata: FRadioPlayer.Metadata?) {
        Task { @MainActor in
            updateLabels()
        }
    }

    nonisolated func radioPlayer(_ player: FRadioPlayer, artworkDidChange artworkURL: URL?) {
        Task { @MainActor in
            updateTrackArtwork()
        }
    }

}

extension NowPlayingViewController: StationsManagerObserver {

    func stationsManager(_ manager: StationsManager, stationDidChange station: RadioStation?) {
        stationDidChange()
    }
}
