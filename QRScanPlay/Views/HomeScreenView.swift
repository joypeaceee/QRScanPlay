//
//  HomeScreenView.swift
//  QRScanPlay
//
//  Welcome screen that guides users through glasses connection.
//

import MWDATCore
import SwiftUI

struct HomeScreenView: View {
    @ObservedObject var viewModel: WearablesViewModel

    var body: some View {
        ZStack {
            Color(.systemBackground).edgesIgnoringSafeArea(.all)

            VStack(spacing: 24) {
                Spacer()

                // App icon/logo
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)

                Text("Museum Tour Guide")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)

                Text("Hands-free audio tours with\nMeta AI glasses")
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Spacer()

                // Feature highlights
                VStack(spacing: 20) {
                    FeatureRow(
                        icon: "eyeglasses",
                        title: "Scan QR Codes",
                        description: "Use your glasses camera to scan exhibit codes"
                    )

                    FeatureRow(
                        icon: "speaker.wave.2.fill",
                        title: "Audio Guides",
                        description: "Listen through your glasses speakers"
                    )

                    FeatureRow(
                        icon: "hand.raised.slash.fill",
                        title: "Hands-Free",
                        description: "Keep your hands free while exploring"
                    )
                }
                .padding(.horizontal, 24)

                Spacer()

                // Connect button
                VStack(spacing: 16) {
                    Text("You'll be redirected to the Meta AI app to confirm your connection.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    Button(action: {
                        viewModel.connectGlasses()
                    }) {
                        HStack {
                            Image(systemName: "link")
                            Text(viewModel.registrationState == .registering ? "Connecting..." : "Connect my glasses")
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(viewModel.registrationState == .registering ? Color.gray : Color.blue)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.registrationState == .registering)
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 32)
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}
