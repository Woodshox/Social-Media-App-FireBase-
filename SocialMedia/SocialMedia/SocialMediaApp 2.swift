//
//  SocialMediaApp.swift
//  SocialMedia
//
//  Created by Aleksandr Pavlov on 10.02.23.
//

import SwiftUI
import Firebase

@main
struct SocialMediaApp: App {
    init() {
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
