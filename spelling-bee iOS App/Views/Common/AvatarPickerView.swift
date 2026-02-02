//
//  AvatarPickerView.swift
//  spelling-bee iOS App
//
//  Reusable avatar picker grid for selecting profile avatars.
//

import SwiftUI

struct AvatarPickerView: View {
    @Binding var selectedAvatar: String

    private let avatars = ProfileManager.avatarOptions
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 8)

    var body: some View {
        VStack(spacing: 24) {
            // Large preview
            Text(selectedAvatar)
                .font(.system(size: 80))
                .padding(.top, 16)

            // Avatar grid
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(avatars, id: \.self) { avatar in
                    Button {
                        selectedAvatar = avatar
                    } label: {
                        Text(avatar)
                            .font(.system(size: 32))
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(selectedAvatar == avatar ? Color.purple.opacity(0.3) : Color.clear)
                            )
                            .overlay(
                                Circle()
                                    .stroke(selectedAvatar == avatar ? Color.purple : Color.clear, lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
}
