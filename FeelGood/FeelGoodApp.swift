//
//  FeelGoodApp.swift
//  FeelGood
//
//  Created by Ayush Shah on 3/20/25.
//

import SwiftUI

@main
struct FeelGoodApp: App {
  // Create a shared instance of UserModel
  @StateObject private var userModel = UserModel()

  var body: some Scene {
    WindowGroup {
      NavigationView {
        ContentView()
          .environmentObject(userModel)
          .preferredColorScheme(.light)
      }
      .tint(userModel.activeTheme.colors[0])
      .onDisappear {
        // Save user preferences when app closes
        userModel.savePreferences()
      }
    }
  }
}
