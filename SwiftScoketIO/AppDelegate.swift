//
//  AppDelegate.swift
//  SwiftScoketIO
//
//  Created by Debug.s on 2022/4/20.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        SocketUtil.share.connect()
        
        
      
        
        
        return true
    }
 

}

