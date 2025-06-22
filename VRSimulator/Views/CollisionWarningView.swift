import SwiftUI

struct CollisionWarningView: View {
    let remainingDistance: Double
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundColor(.yellow)
                .accessibilityHidden(true)
            
            Text("!! COLLISION RISK – adjust H5 / HF / H17 (Remaining: \(String(format: "%.1f", remainingDistance)))")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.yellow)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(Color.red)
        .cornerRadius(12)
        .shadow(color: .red.opacity(0.3), radius: 4, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Collision Risk Warning")
        .accessibilityValue("Remaining distance: \(String(format: "%.1f", remainingDistance))")
       // .accessibilityAddTraits(.isAlert)
        .transition(.opacity.combined(with: .scale))
        .animation(.easeInOut(duration: 0.3), value: remainingDistance)
    }
}

#Preview {
    CollisionWarningView(remainingDistance: 25.5)
        .padding()
}
