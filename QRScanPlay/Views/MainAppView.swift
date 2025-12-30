//
//  MainAppView.swift
//  QRScanPlay
//
//  Navigation hub that displays views based on registration and device states.
//

import MWDATCore
import SwiftUI

struct MainAppView: View {
    let wearables: WearablesInterface
    @ObservedObject var viewModel: WearablesViewModel
    @StateObject private var tourManager: TourSessionManager

    init(wearables: WearablesInterface, viewModel: WearablesViewModel) {
        self.wearables = wearables
        self.viewModel = viewModel
        self._tourManager = StateObject(wrappedValue: TourSessionManager(wearables: wearables))
    }

    var body: some View {
        if viewModel.registrationState == .registered || viewModel.hasMockDevice {
            TourView(tourManager: tourManager, wearablesVM: viewModel)
        } else {
            HomeScreenView(viewModel: viewModel)
        }
    }
}
