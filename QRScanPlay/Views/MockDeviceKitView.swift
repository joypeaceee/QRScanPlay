//
//  MockDeviceKitView.swift
//  QRScanPlay
//
//  Debug-only interface for managing mock Meta wearable devices.
//

#if DEBUG

import MWDATMockDevice
import SwiftUI

struct MockDeviceKitView: View {
    @ObservedObject var viewModel: MockDeviceKitViewModel

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Mock Device Kit")
                    .font(.title2)
                    .padding(.top)

                Text("\(viewModel.pairedDevices.count) device(s) paired")
                    .font(.subheadline)
                    .foregroundColor(.green)

                Button(action: {
                    viewModel.pairRaybanMeta()
                }) {
                    HStack {
                        Image(systemName: "eyeglasses")
                        Text("Pair Ray-Ban Meta")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(viewModel.pairedDevices.count > 2 ? Color.gray : Color.blue)
                    .cornerRadius(10)
                }
                .disabled(viewModel.pairedDevices.count > 2)
                .padding(.horizontal)

                if !viewModel.pairedDevices.isEmpty {
                    List {
                        ForEach(viewModel.pairedDevices, id: \.deviceIdentifier) { device in
                            HStack {
                                Image(systemName: "eyeglasses")
                                    .foregroundColor(.blue)
                                Text("Mock Device")
                                Spacer()
                                Button(action: {
                                    viewModel.unpairDevice(device)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }

                Spacer()
            }
            .navigationTitle("Mock Devices")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#endif
