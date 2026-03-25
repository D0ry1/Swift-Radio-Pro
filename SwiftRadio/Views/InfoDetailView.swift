//
//  InfoDetailView.swift
//  SwiftRadio
//

import SwiftUI

struct InfoDetailView: View {

    let station: RadioStation
    var onDismiss: () -> Void

    @State private var stationImage: UIImage?

    private var longDesc: String {
        station.longDesc.isEmpty
            ? "You are listening to Swift Radio. This is a sweet open source project. Tell your friends, swiftly!"
            : station.longDesc
    }

    var body: some View {
        ZStack {
            Image("background")
                .resizable()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack(spacing: 8) {
                    Group {
                        if let stationImage {
                            Image(uiImage: stationImage)
                                .resizable()
                        } else {
                            Color.clear
                        }
                    }
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 110, height: 70)
                    .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
                    .accessibilityLabel("Logo for \(station.name)")

                    VStack(alignment: .leading, spacing: 8) {
                        Text(station.name)
                            .font(.headline)
                            .foregroundColor(.white)
                            .accessibilityAddTraits(.isHeader)
                        Text(station.desc)
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)

                // Long description
                ScrollView {
                    Text(longDesc)
                        .font(.body)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .frame(maxHeight: 340)

                Spacer()

                // Okay button
                Button(action: onDismiss) {
                    Text("Okay")
                        .font(.body)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(Color(red: 0.149, green: 0.149, blue: 0.153))
                }
                .accessibilityLabel("Close")
                .accessibilityHint("Returns to the now playing screen")
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .task {
            stationImage = await station.getImage()
        }
    }
}
