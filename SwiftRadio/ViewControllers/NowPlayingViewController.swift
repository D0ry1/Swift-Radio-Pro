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
class NowPlayingViewController: BaseController {

    weak var delegate: NowPlayingViewControllerDelegate?

    // MARK: - UI

    private let albumImageView: SpringImageView = {
        let iv = SpringImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private var albumHeightConstraint: NSLayoutConstraint!

    private let stationDescLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "AvenirNext-Regular", size: 15)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.heightAnchor.constraint(equalToConstant: 21).isActive = true
        return label
    }()

    private lazy var playingButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "btn-play"), for: .normal)
        button.setImage(UIImage(named: "btn-pause"), for: .selected)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 45).isActive = true
        button.heightAnchor.constraint(equalToConstant: 45).isActive = true
        button.addTarget(self, action: #selector(playingPressed), for: .touchUpInside)
        return button
    }()

    private lazy var previousButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "btn-previous"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 45).isActive = true
        button.heightAnchor.constraint(equalToConstant: 45).isActive = true
        button.addTarget(self, action: #selector(previousPressed), for: .touchUpInside)
        return button
    }()

    private lazy var stopButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "btn-stop"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 45).isActive = true
        button.heightAnchor.constraint(equalToConstant: 45).isActive = true
        button.addTarget(self, action: #selector(stopPressed), for: .touchUpInside)
        return button
    }()

    private lazy var nextButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "btn-next"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 45).isActive = true
        button.heightAnchor.constraint(equalToConstant: 45).isActive = true
        button.addTarget(self, action: #selector(nextPressed), for: .touchUpInside)
        return button
    }()

    private let songLabel: SpringLabel = {
        let label = SpringLabel()
        label.font = .preferredFont(forTextStyle: .title1)
        label.textColor = .white
        label.textAlignment = .center
        label.minimumScaleFactor = 0.5
        label.adjustsFontSizeToFitWidth = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let artistLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title3)
        label.textColor = .white
        label.textAlignment = .center
        label.minimumScaleFactor = 0.5
        label.adjustsFontSizeToFitWidth = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let volumeParentView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.alpha = 0.5
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: 60).isActive = true
        return v
    }()

    private let airPlayView: UIView = {
        let v = UIView()
        v.backgroundColor = .gray
        v.translatesAutoresizingMaskIntoConstraints = false
        v.widthAnchor.constraint(equalToConstant: 42).isActive = true
        v.heightAnchor.constraint(equalToConstant: 45).isActive = true
        return v
    }()

    private lazy var companyButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "logo"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 90).isActive = true
        button.heightAnchor.constraint(equalToConstant: 36).isActive = true
        button.addTarget(self, action: #selector(handleCompanyButton), for: .touchUpInside)
        return button
    }()

    private lazy var shareButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "share"), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 26).isActive = true
        button.heightAnchor.constraint(equalToConstant: 26).isActive = true
        button.addTarget(self, action: #selector(shareButtonPressed), for: .touchUpInside)
        return button
    }()

    private lazy var infoButton: UIButton = {
        let button = UIButton(type: .infoLight)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 22).isActive = true
        button.heightAnchor.constraint(equalToConstant: 22).isActive = true
        button.addTarget(self, action: #selector(infoButtonPressed), for: .touchUpInside)
        return button
    }()

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
    nonisolated(unsafe) private var timeObserver: Any?
    private var volumeTopConstraint: NSLayoutConstraint?
    private let volumeTopDefault: CGFloat = 12
    private let volumeTopWithScrub: CGFloat = 56

    // References to stacks for scrub bar layout
    private var controlsStack: UIStackView!
    private var volumeStack: UIStackView!

    deinit {
        if let observer = timeObserver {
            player.avPlayer?.removeTimeObserver(observer)
        }
    }

    // MARK: - Init

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    override func setupViews() {
        super.setupViews()

        // Album art
        albumHeightConstraint = albumImageView.heightAnchor.constraint(greaterThanOrEqualToConstant: 180)
        NSLayoutConstraint.activate([
            albumImageView.widthAnchor.constraint(equalTo: albumImageView.heightAnchor),
            albumHeightConstraint
        ])

        // Controls stack: [prev, play, stop, next]
        controlsStack = UIStackView(arrangedSubviews: [previousButton, playingButton, stopButton, nextButton])
        controlsStack.spacing = 12
        controlsStack.translatesAutoresizingMaskIntoConstraints = false

        // Volume stack: [vol-min, volume view, vol-max]
        let volMinImage = UIImageView(image: UIImage(named: "vol-min"))
        volMinImage.contentMode = .top
        volMinImage.translatesAutoresizingMaskIntoConstraints = false
        volMinImage.widthAnchor.constraint(equalToConstant: 18).isActive = true
        volMinImage.heightAnchor.constraint(equalToConstant: 16).isActive = true

        let volMaxImage = UIImageView(image: UIImage(named: "vol-max"))
        volMaxImage.contentMode = .top
        volMaxImage.translatesAutoresizingMaskIntoConstraints = false
        volMaxImage.widthAnchor.constraint(equalToConstant: 18).isActive = true
        volMaxImage.heightAnchor.constraint(equalToConstant: 16).isActive = true

        volumeStack = UIStackView(arrangedSubviews: [volMinImage, volumeParentView, volMaxImage])
        volumeStack.alignment = .center
        volumeStack.spacing = 8
        volumeStack.translatesAutoresizingMaskIntoConstraints = false
        volumeStack.heightAnchor.constraint(equalToConstant: 60).isActive = true

        // Labels stack: [song, artist]
        let labelsStack = UIStackView(arrangedSubviews: [songLabel, artistLabel])
        labelsStack.axis = .vertical
        labelsStack.alignment = .center
        labelsStack.spacing = 8
        labelsStack.translatesAutoresizingMaskIntoConstraints = false

        // Bottom bar: company button (left), AirPlay (center), share+info stack (right)
        let rightStack = UIStackView(arrangedSubviews: [shareButton, infoButton])
        rightStack.alignment = .bottom
        rightStack.spacing = 10
        rightStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(albumImageView)
        view.addSubview(stationDescLabel)
        view.addSubview(controlsStack)
        view.addSubview(volumeStack)
        view.addSubview(labelsStack)
        view.addSubview(companyButton)
        view.addSubview(airPlayView)
        view.addSubview(rightStack)

        let safeArea = view.safeAreaLayoutGuide

        let vTop = volumeStack.topAnchor.constraint(equalTo: controlsStack.bottomAnchor, constant: volumeTopDefault)
        volumeTopConstraint = vTop

        NSLayoutConstraint.activate([
            // Album art
            albumImageView.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 37),
            albumImageView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 70),
            albumImageView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -70),

            // Station desc - overlapping album bottom
            stationDescLabel.topAnchor.constraint(equalTo: albumImageView.bottomAnchor, constant: -32),
            stationDescLabel.leadingAnchor.constraint(equalTo: albumImageView.leadingAnchor),
            stationDescLabel.trailingAnchor.constraint(equalTo: albumImageView.trailingAnchor),

            // Controls
            controlsStack.topAnchor.constraint(equalTo: albumImageView.bottomAnchor, constant: 30),
            controlsStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // Volume
            vTop,
            volumeStack.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 12),
            volumeStack.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -12),

            // Labels
            labelsStack.topAnchor.constraint(equalTo: volumeStack.bottomAnchor, constant: 12),
            labelsStack.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 12),
            labelsStack.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -12),

            // Bottom bar
            companyButton.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 12),
            companyButton.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -8),

            airPlayView.centerXAnchor.constraint(equalTo: labelsStack.centerXAnchor),
            airPlayView.bottomAnchor.constraint(equalTo: rightStack.bottomAnchor, constant: 10),

            rightStack.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -12),
            rightStack.centerYAnchor.constraint(equalTo: companyButton.centerYAnchor)
        ])
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

    @objc func playingPressed(_ sender: Any) {
        player.togglePlaying()
    }

    @objc func stopPressed(_ sender: Any) {
        player.stop()
    }

    @objc func nextPressed(_ sender: Any) {
        manager.setNext()
    }

    @objc func previousPressed(_ sender: Any) {
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

    @objc func infoButtonPressed(_ sender: UIButton) {
        guard let station = manager.currentStation else { return }
        delegate?.didTapInfoButton(self, station: station)
    }

    @objc func shareButtonPressed(_ sender: UIButton) {
        guard let station = manager.currentStation else { return }
        delegate?.didTapShareButton(self, station: station, artworkURL: player.currentArtworkURL)
    }

    @objc func handleCompanyButton(_ sender: Any) {
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
