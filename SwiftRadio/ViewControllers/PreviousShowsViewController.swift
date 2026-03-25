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
        indicator.accessibilityLabel = "Loading previous shows"
        return indicator
    }()

    private let errorLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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
        view.addSubview(errorLabel)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }

    private func loadEpisodes() {
        errorLabel.isHidden = true
        activityIndicator.startAnimating()
        Task {
            do {
                episodes = try await DataManager.getOnDemandEpisodes()
            } catch {
                showError(error)
            }
            activityIndicator.stopAnimating()
            tableView.reloadData()
            if !episodes.isEmpty {
                UIAccessibility.post(notification: .screenChanged, argument: tableView)
            }
        }
    }

    @objc private func refresh() {
        errorLabel.isHidden = true
        Task {
            do {
                episodes = try await DataManager.getOnDemandEpisodes()
            } catch {
                showError(error)
            }
            refreshControl.endRefreshing()
            tableView.reloadData()
        }
    }

    private func showError(_ error: Error) {
        guard episodes.isEmpty else { return }
        errorLabel.text = error.localizedDescription
        errorLabel.isHidden = false
        UIAccessibility.post(notification: .screenChanged, argument: errorLabel)
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
        cell.accessibilityHint = "Double tap to play this episode"
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
