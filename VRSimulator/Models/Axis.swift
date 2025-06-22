import Foundation
import SwiftUICore
import UIKit

// AxisTag enum helps avoid typos
enum AxisTag: String, CaseIterable {
    case seatXAxis       = "seat_x_axis"
    case seatZAxis       = "seat_z_axis"
    case floorZAxis      = "floor_z_axis"
    case stgWheelCenter  = "stg_wheel_center"
}

// Axis configuration for mapping slider ⇄ measurement (for display only)
struct AxisMapping {
    let sliderMin: Double
    let sliderMax: Double
    let measMin: Double
    let measMax: Double
    
    /// Maps slider value (UI) to measurement (for MEAS display)
    func sliderToMeasurement(_ sliderValue: Double) -> Double {
        // Normalize the slider value to 0-1 range
        let normalizedSlider = (sliderValue - sliderMin) / (sliderMax - sliderMin)
        // Map to measurement range
        return measMin + (measMax - measMin) * normalizedSlider
    }
}

// Mapping dictionary for each axis
let axisMappings: [AxisTag: AxisMapping] = [
    .seatXAxis: AxisMapping(sliderMin: 345, sliderMax: 520, measMin: 175, measMax: 0),
    .seatZAxis: AxisMapping(sliderMin: 595, sliderMax: 845, measMin: 300, measMax: 550),
    .floorZAxis: AxisMapping(sliderMin: 300, sliderMax: 550, measMin: 300, measMax: 550),
    .stgWheelCenter: AxisMapping(sliderMin: 650, sliderMax: 745, measMin: 5, measMax: 100)
]

// MARK: - Safe Wrappers

/// Use this only for showing MEAS SCALE (for display)
func calculateMeasurement(for tag: AxisTag, fromSliderValue slider: Double) -> Double {
    axisMappings[tag]?.sliderToMeasurement(slider) ?? slider
}

/// Direct passthrough for slider or BLE input – no mapping
func calculateSlider(for tag: AxisTag, fromMeasurement value: Double) -> Double {
    return value  // used for direct BLE update or user input
}


extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    @ViewBuilder
       func conditionalPadding(_ condition: Bool, edges: Edge.Set = .all, length: CGFloat) -> some View {
           if condition {
               self.padding(edges, length)
           } else {
               self
           }
       }
}
