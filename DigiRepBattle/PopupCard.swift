//
//  PopupCard.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/11/02.
//
import SwiftUI

struct PopupCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(spacing: 0) {
            content
                .padding(16)
        }
        .frame(maxWidth: 420)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
        )
        .shadow(radius: 20, y: 8)
        .padding(24)
    }
}
