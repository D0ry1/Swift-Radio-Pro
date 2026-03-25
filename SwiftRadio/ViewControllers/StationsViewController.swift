//
//  StationsViewController.swift
//  SwiftRadio
//
//  Created by Fethi El Hassasna on 2023-06-24.
//  Copyright © 2023 matthewfecher.com. All rights reserved.
//

import UIKit
import Combine
import FRadioPlayer

@MainActor
protocol StationsViewControllerDelegate: AnyObject {
    func pushNowPlayingController(_ stationsViewController: StationsViewController, newStation: Bool)
    func presentPopUpMenuController(_ stationsViewController: StationsViewController)
    func presentPreviousShows(_ stationsViewController: StationsViewController)
}

@MainActor
class StationsViewController: BaseController, Handoffable {

    // MARK: - Delegate
    weak var delegate: StationsViewControllerDelegate?

    // MARK: - Properties
    private let manager = StationsManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var observationTask: Task<Void, Never>?

    // MARK: - UI

    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return refreshControl
    }()

    private let searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.obscuresBackgroundDuringPresentation = false
        controller.hidesNavigationBarDuringPresentation = true
        return controller
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.backgroundView = nil
        tableView.separatorStyle = .none
        tableView.register(NothingFoundCell.self)
        tableView.register(StationTableViewCell.self)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    private let nowPlayingView: NowPlayingView = {
        return NowPlayingView()
    }()

    override func loadView() {
        super.loadView()
        setupViews()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true

        // NavigationBar items
        let menuButton = UIBarButtonItem(image: UIImage(named: "icon-hamburger"), style: .plain, target: self, action: #selector(handleMenuTap))
        menuButton.accessibilityLabel = "Menu"
        menuButton.accessibilityHint = "Opens the menu"
        navigationItem.leftBarButtonItem = menuButton

        // Previous Shows button in table header
        setupPreviousShowsHeader()

        // Subscribe to publishers
        bindPublishers()

        // Setup Handoff User Activity
        setupHandoffUserActivity()

        // Setup Search Bar
        setupSearchController()

        // Now Playing View
        nowPlayingView.tapHandler = { [weak self] in
            self?.nowPlayingBarButtonPressed()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = "Swift Radio"
    }

    private func bindPublishers() {
        let pub = RadioPlayerPublisher.shared
        let player = FRadioPlayer.shared

        pub.playbackState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                startNowPlayingAnimation(player.isPlaying)
            }
            .store(in: &cancellables)

        pub.metadata
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                updateNowPlayingButton(station: manager.currentStation)
                updateHandoffUserActivity(userActivity, station: manager.currentStation)
            }
            .store(in: &cancellables)

        observeManager()
    }

    private func observeManager() {
        observationTask?.cancel()
        let manager = self.manager
        observationTask = Task { [weak self] in
            while !Task.isCancelled {
                let oldStations = manager.stations
                let oldStation = manager.currentStation
                await withCheckedContinuation { continuation in
                    withObservationTracking {
                        _ = manager.stations
                        _ = manager.currentStation
                    } onChange: {
                        continuation.resume()
                    }
                }
                guard !Task.isCancelled, let self else { return }
                if manager.stations != oldStations {
                    self.tableView.reloadData()
                    if !manager.stations.isEmpty {
                        UIAccessibility.post(notification: .screenChanged, argument: self.tableView)
                    }
                }
                if manager.currentStation != oldStation {
                    guard let current = manager.currentStation else {
                        self.resetCurrentStation()
                        continue
                    }
                    self.updateNowPlayingButton(station: current)
                }
            }
        }
    }

    @objc func refresh(sender: AnyObject) {
        Task {
            do {
                _ = try await manager.fetch()
            } catch {
                showErrorBanner(error.localizedDescription)
            }

            try? await Task.sleep(nanoseconds: 2_000_000_000)
            refreshControl.endRefreshing()
            view.setNeedsDisplay()
        }
    }

    private func showErrorBanner(_ message: String) {
        let banner = UILabel()
        banner.text = message
        banner.textColor = .white
        banner.backgroundColor = UIColor.systemRed.withAlphaComponent(0.85)
        banner.textAlignment = .center
        banner.font = .preferredFont(forTextStyle: .footnote)
        banner.numberOfLines = 0
        banner.translatesAutoresizingMaskIntoConstraints = false
        banner.layer.cornerRadius = 8
        banner.clipsToBounds = true

        // Padding via content insets
        banner.layoutMargins = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)

        view.addSubview(banner)
        NSLayoutConstraint.activate([
            banner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            banner.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            banner.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])

        UIAccessibility.post(notification: .announcement, argument: message)

        UIView.animate(withDuration: 0.3, delay: 3, options: []) {
            banner.alpha = 0
        } completion: { _ in
            banner.removeFromSuperview()
        }
    }

    // Reset all properties to default
    private func resetCurrentStation() {
        nowPlayingView.reset()
        navigationItem.rightBarButtonItem = nil
    }

    // Update the now playing button title
    private func updateNowPlayingButton(station: RadioStation?) {

        guard let station = station else {
            nowPlayingView.reset()
            return
        }

        var playingTitle: String?

        if FRadioPlayer.shared.currentMetadata != nil {
            playingTitle = station.trackName + " - " + station.artistName
        }

        nowPlayingView.update(with: playingTitle, subtitle: station.name)
        createNowPlayingBarButton()
    }

    func startNowPlayingAnimation(_ animate: Bool) {
        animate ? nowPlayingView.startAnimating() : nowPlayingView.stopAnimating()
    }

    private func createNowPlayingBarButton() {
        guard navigationItem.rightBarButtonItem == nil else { return }
        let barButton = UIBarButtonItem(image: UIImage(named: "btn-nowPlaying"), style: .plain, target: self, action: #selector(nowPlayingBarButtonPressed))
        barButton.accessibilityLabel = "Now Playing"
        barButton.accessibilityHint = "Opens the now playing screen"
        navigationItem.rightBarButtonItem = barButton
    }

    @objc func nowPlayingBarButtonPressed() {
        pushNowPlayingController()
    }

    @objc func handleMenuTap() {
        delegate?.presentPopUpMenuController(self)
    }

    @objc func handlePreviousShowsTap() {
        delegate?.presentPreviousShows(self)
    }

    private func setupPreviousShowsHeader() {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 50))
        headerView.backgroundColor = .clear

        let button = UIButton(type: .system)
        button.setTitle("Previous Shows", for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.tintColor = .white
        button.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handlePreviousShowsTap), for: .touchUpInside)
        button.accessibilityHint = "Shows previously aired episodes"

        headerView.addSubview(button)

        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            button.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            button.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            button.heightAnchor.constraint(equalToConstant: 40)
        ])

        tableView.tableHeaderView = headerView
    }

    func nowPlayingPressed(_ sender: UIButton) {
        pushNowPlayingController()
    }

    func pushNowPlayingController(with station: RadioStation? = nil) {
        title = ""

        let newStation: Bool

        if let station = station {
            // User clicked on row, load/reset station
            newStation = station != manager.currentStation
            if newStation {
                manager.set(station: station)
            }
        } else {
            // User clicked on Now Playing button
            newStation = false
        }

        delegate?.pushNowPlayingController(self, newStation: newStation)
    }

    override func setupViews() {
        super.setupViews()

        let stackView = UIStackView(arrangedSubviews: [tableView, nowPlayingView])
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false

        tableView.addSubview(refreshControl)
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        ])
    }
}

// MARK: - TableViewDataSource

extension StationsViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        90.0
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive {
            return manager.searchedStations.count
        } else {
            return manager.stations.isEmpty ? 1 : manager.stations.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if manager.stations.isEmpty {
            let cell: NothingFoundCell = tableView.dequeueReusableCell(for: indexPath)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(for: indexPath) as StationTableViewCell

            // alternate background color
            cell.backgroundColor = (indexPath.row % 2 == 0) ? .clear : .black.withAlphaComponent(0.2)

            let station = searchController.isActive ? manager.searchedStations[indexPath.row] : manager.stations[indexPath.row]
            cell.configureStationCell(station: station)
            return cell
        }
    }
}

// MARK: - TableViewDelegate

extension StationsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let station = searchController.isActive ? manager.searchedStations[indexPath.item] : manager.stations[indexPath.item]

        pushNowPlayingController(with: station)
    }
}

// MARK: - UISearchControllerDelegate / Setup

extension StationsViewController: UISearchResultsUpdating {

    func setupSearchController() {
        guard Config.searchable else { return }

        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
    }

    func updateSearchResults(for searchController: UISearchController) {
        guard let filter = searchController.searchBar.text else { return }
        manager.updateSearch(with: filter)
        tableView.reloadData()
    }
}
