//
//  AxisConfig.swift
//  VRSimulator
//
//  Created by Dhanalakshmi on 21/05/25.
//

import Foundation

// Axis configuration model
struct AxisConfig: Identifiable {
    let id = UUID()
    let name: String
    let label: String
    let axisTag: AxisTag
    let minValue: Double
    let maxValue: Double
    let iconName: String
    let apiKey: String
}

// BLE status enum
enum BLEStatus: String {
    case disconnected
    case connecting
    case connected
}

// Axis value update model
struct AxisValue {
    let axis: String
    let value: Int
}

// Predefined axis configurations
let AXES_CONFIG: [AxisConfig] = [
    AxisConfig(
        name: "seatX",
        label: "Seat X Axis (L63)",
        axisTag: .seatXAxis,
        minValue: 345,
        maxValue: 520,
        iconName: "seat_x_new_1",
        apiKey: "x"
    ),
    AxisConfig(
        name: "seatZ",
        label: "Seat Z Axis (H5)",
        axisTag: .seatZAxis,
        minValue: 595,
        maxValue: 845,
        iconName: "seat_z_new_1",
        apiKey: "z"
    ),
    AxisConfig(
        name: "floorZ",
        label: "Floor Z Axis (HF)",
        axisTag: .floorZAxis,
        minValue: 300,
        maxValue: 550,
        iconName: "floor_z_new_1",
        apiKey: "f"
    ),
    AxisConfig(
        name: "stgCenter",
        label: "STG-Center (H17)",
        axisTag: .stgWheelCenter,
        minValue: 650,
        maxValue: 745,
        iconName: "stg_center_new_1",
        apiKey: "s"
    )
]

// MARK: - Button State for feedback
enum ButtonState {
    case normal
    case sent
}

// MARK: - Collision Detection Constants (matching Python)
let SAFE_H5: Double = 595        // baseline seat-lift slider value
let SAFE_HF: Double = 300        // baseline steering-plate slider value
let SAFE_H17: Double = 650       // baseline steering-tilt slider value
let SAFE_CLEARANCE: Double = 230 // mm physical gap at baseline
let MIN_ALLOWED: Double = 80     // mm absolute clearance tolerance
let K17: Double = 1.0           // steering-tilt's vertical contribution
