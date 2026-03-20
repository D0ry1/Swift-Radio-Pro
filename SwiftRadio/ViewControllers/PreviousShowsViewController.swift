//
//  PreviousShowsViewController.swift
//  SwiftRadio
//

import UIKit

@MainActor
protocol PreviousShowsViewControllerDelegate: AnyObject {
    func previousShowsViewController(_ controller: PreviousShowsViewController, didSelectEpisode episode: OnDemandEpisode)
}

@MainActor
class PreviousShowsViewController: BaseController {

    weak var delegate: PreviousShowsViewControllerDelegate?

    private var episodes: [OnDemandEpisode] = []

    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return refreshControl
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.backgroundView = nil
        tableView.separatorStyle = .none
        tableView.register(StationTableViewCell.self)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 90
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    override func loadView() {
        super.loadView()
        setupViews()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Previous Shows"
        navigationController?.navigationBar.prefersLargeTitles = true
        loadEpisodes()
    }

    override func setupViews() {
        super.setupViews()

        tableView.addSubview(refreshControl)
        view.addSubview(tableView)
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func loadEpisodes() {
        activityIndicator.startAnimating()
        Task {
            do {
                episodes = try await DataManager.getOnDemandEpisodes()
            } catch {
                if Config.debugLog { print("Error loading on-demand episodes: \(error)") }
            }
            activityIndicator.stopAnimating()
            tableView.reloadData()
        }
    }

    @objc private func refresh() {
        Task {
            do {
                episodes = try await DataManager.getOnDemandEpisodes()
            } catch {
                if Config.debugLog { print("Error refreshing on-demand episodes: \(error)") }
            }
            refreshControl.endRefreshing()
            tableView.reloadData()
        }
    }
}

// MARK: - UITableViewDataSource

extension PreviousShowsViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        episodes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as StationTableViewCell
        cell.backgroundColor = (indexPath.row % 2 == 0) ? .clear : .black.withAlphaComponent(0.2)

        let episode = episodes[indexPath.row]
        let station = episode.toRadioStation()
        cell.configureStationCell(station: station)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension PreviousShowsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let episode = episodes[indexPath.row]
        delegate?.previousShowsViewController(self, didSelectEpisode: episode)
    }
}
