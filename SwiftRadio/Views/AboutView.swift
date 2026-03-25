//
//  AboutView.swift
//  SwiftRadio
//

import SwiftUI

struct AboutView: View {

    var onWebsite: () -> Void
    var onEmail: () -> Void
    var onDismiss: () -> Void

    private let featuresText = """
    FEATURES: + Displays Artist, Track and Album/Station Art on lock screen.
    + Background Audio performance
    +iTunes API integration to automatically download album art
    + Loads and parses Icecast metadata (i.e. artist & track names)
    + Ability to update stations from server without resubmitting to the app store.
    """

    var body: some View {
        ZStack {
            Image("background")
                .resizable()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack(spacing: 8) {
                    Image("logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 80)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Xcode / Swift")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Radio App")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)

                // Features
                Text(featuresText)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .frame(maxHeight: 350, alignment: .top)

                Spacer()

                // Buttons
                VStack(spacing: 8) {
                    VStack(spacing: 4) {
                        Button("Website", action: onWebsite)
                            .font(.headline)
                            .foregroundColor(.white)
                        Button("email me", action: onEmail)
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }

                    Button(action: onDismiss) {
                        Text("Okay")
                            .font(.body)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(Color(red: 0.204, green: 0.202, blue: 0.209))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
    }
}
