//
//  QRScanPlayApp.swift
//  QRScanPlay
//
//  Museum Tour Guide App - Hands-free audio tours using Meta AI glasses
//

import Foundation
import MWDATCore
import SwiftUI

#if DEBUG
import MWDATMockDevice
#endif

@main
struct QRScanPlayApp: App {
    #if DEBUG
    @StateObject private var debugMenuViewModel: DebugMenuViewModel
    #endif

    private let wearables: WearablesInterface
    @StateObject private var wearablesViewModel: WearablesViewModel

    init() {
        // Configure Wearables SDK FIRST before accessing any shared instances
        do {
            try Wearables.configure()
        } catch {
            #if DEBUG
            NSLog("[QRScanPlay] Failed to configure Wearables SDK: \(error)")
            #endif
            fatalError("Failed to configure Wearables SDK: \(error)")
        }

        let wearables = Wearables.shared
        self.wearables = wearables
        self._wearablesViewModel = StateObject(wrappedValue: WearablesViewModel(wearables: wearables))

        #if DEBUG
        // Initialize debug view model AFTER Wearables is configured
        self._debugMenuViewModel = StateObject(wrappedValue: DebugMenuViewModel(mockDeviceKit: MockDeviceKit.shared))
        #endif
    }

    var body: some Scene {
        WindowGroup {
            MainAppView(wearables: wearables, viewModel: wearablesViewModel)
                .alert("Error", isPresented: $wearablesViewModel.showError) {
                    Button("OK") {
                        wearablesViewModel.dismissError()
                    }
                } message: {
                    Text(wearablesViewModel.errorMessage)
                }
            #if DEBUG
            .sheet(isPresented: $debugMenuViewModel.showDebugMenu) {
                MockDeviceKitView(viewModel: debugMenuViewModel.mockDeviceKitViewModel)
            }
            .overlay {
                DebugMenuView(debugMenuViewModel: debugMenuViewModel)
            }
            #endif

            RegistrationView(viewModel: wearablesViewModel)
        }
    }
}
