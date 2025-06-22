//
//  BLEStatusIndicatorView.swift
//  VRSimulator
//
//  Created by Dhanalakshmi on 21/05/25.
//

import SwiftUI

struct BLEStatusIndicatorView: View {
    let status: BLEStatus
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
                .shadow(radius: 1)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 1)
                )
            
            Text(statusText)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    var statusColor: Color {
        switch status {
        case .connected: return .green
        case .connecting: return .yellow
        case .disconnected: return .red
        }
    }
    
    var statusText: String {
        switch status {
        case .connected: return "Connected"
        case .connecting: return "Connecting..."
        case .disconnected: return "Disconnected"
        }
    }
}
