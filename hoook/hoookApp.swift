//
//  hookApp.swift
//  hook
//
//  Created by Tanush Saxena on 1/9/26.
//

import SwiftUI

@main
struct hookApp: App {
    @State private var showSplash = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashScreenView(showSplash: $showSplash)
                } else {
                    ContentView()
                }
            }
        }
    }
}
