//
//  DebugMenuView.swift
//  QRScanPlay
//
//  Debug-only overlay for mock device access during development.
//

#if DEBUG

import SwiftUI

struct DebugMenuView: View {
    @ObservedObject var debugMenuViewModel: DebugMenuViewModel

    var body: some View {
        HStack {
            Spacer()
            VStack {
                Spacer()
                Button(action: {
                    debugMenuViewModel.showDebugMenu = true
                }) {
                    Image(systemName: "ladybug.fill")
                        .foregroundColor(.white)
                        .padding()
                        .background(.secondary)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .accessibilityIdentifier("debug_menu_button")
                Spacer()
            }
            .padding(.trailing)
        }
    }
}

#endif
