//
//  DebugMenuViewModel.swift
//  QRScanPlay
//
//  Debug-only view model for mock device testing.
//

#if DEBUG

import Combine
import Foundation
import MWDATMockDevice
import SwiftUI

@MainActor
class DebugMenuViewModel: ObservableObject {
    @Published public var showDebugMenu: Bool = false
    @Published public var mockDeviceKitViewModel: MockDeviceKitViewModel

    init(mockDeviceKit: MockDeviceKitInterface) {
        self.mockDeviceKitViewModel = MockDeviceKitViewModel(mockDeviceKit: mockDeviceKit)
    }
}

#endif
