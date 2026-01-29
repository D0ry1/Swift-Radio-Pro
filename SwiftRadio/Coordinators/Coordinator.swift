//
//  Coordinator.swift
//  SwiftRadio
//
//  Created by Fethi El Hassasna on 2022-11-23.
//  Copyright © 2022 matthewfecher.com. All rights reserved.
//

import UIKit

@MainActor
protocol Coordinator: AnyObject {
    var childCoordinators: [Coordinator] { get set }
    func start()
}

@MainActor
protocol NavigationCoordinator: Coordinator {
    var navigationController: UINavigationController { get }
}

@MainActor
protocol TabCoordinator: Coordinator {
    var tabBarController: UITabBarController { get }
}
