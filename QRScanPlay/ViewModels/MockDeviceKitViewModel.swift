//
//  MockDeviceKitViewModel.swift
//  QRScanPlay
//
//  View model for managing mock devices during development.
//

#if DEBUG

import Combine
import Foundation
import MWDATMockDevice

@MainActor
class MockDeviceKitViewModel: ObservableObject {
    private let mockDeviceKit: MockDeviceKitInterface
    @Published var pairedDevices: [MockDevice] = []

    init(mockDeviceKit: MockDeviceKitInterface) {
        self.mockDeviceKit = mockDeviceKit
        self.pairedDevices = mockDeviceKit.pairedDevices
    }

    func pairRaybanMeta() {
        let mockDevice = mockDeviceKit.pairRaybanMeta()
        pairedDevices.append(mockDevice)
    }

    func unpairDevice(_ device: MockDevice) {
        if let idx = pairedDevices.firstIndex(where: { $0.deviceIdentifier == device.deviceIdentifier }) {
            pairedDevices.remove(at: idx)
            mockDeviceKit.unpairDevice(device)
        }
    }
}

#endif
