//
//  PermissionCardView.swift
//  OpenCodeClient
//

import SwiftUI

struct PermissionCardView: View {
    let permission: PendingPermission
    let onRespond: (Bool) -> Void

    private let accent = Color.orange
    private let cornerRadius: CGFloat = 12

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.shield.fill")
                    .foregroundStyle(accent)
                    .font(.title3)
                Text("Permission Required")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(accent)
            }
            Text(permission.description)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 10) {
                Button {
                    onRespond(true)
                } label: {
                    Text("Approve")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                Button {
                    onRespond(false)
                } label: {
                    Text("Reject")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(accent.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(accent.opacity(0.14), lineWidth: 1)
        )
    }
}
