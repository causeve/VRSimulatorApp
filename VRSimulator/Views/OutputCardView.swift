//
//  OutputCardView.swift
//  VRSimulator
//
//  Created by Dhanalakshmi on 21/05/25.
//

import SwiftUI

// Helper view for output cards
struct OutputCardView: View {
    let title: String
    let value: String
    let description: String
    
    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(value)
                    .font(.system(size: 24, weight: .medium, design: .monospaced))
                
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// Custom button style
struct PrimaryButtonStyle: ButtonStyle {
    var backgroundColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .foregroundColor(.white)
            .background(backgroundColor.opacity(configuration.isPressed ? 0.7 : 1))
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
