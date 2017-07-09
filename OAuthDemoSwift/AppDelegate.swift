//
//  AppDelegate.swift
//  OAuthDemoSwift
//
//  Created by Admin on 28/06/2017.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var coordinator: Coordinator!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        let navigationController = UINavigationController()
        coordinator = Coordinator(navigationController)
        
        let frame = UIScreen.main.bounds
        window = UIWindow(frame: frame)
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        
        coordinator.startFromRoot()
        
        return true
    }
}

