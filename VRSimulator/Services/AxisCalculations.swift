import Foundation

// MARK: - Axis Calculations

/// Check for collision risk using exact Python formula
func checkCollisionRisk(seatZ: Double, floorZ: Double, stgCenter: Double) -> (collisionRisk: Bool, remainingDistance: Double) {
    let deltaSeat = seatZ - SAFE_H5
    let deltaPlate = floorZ - SAFE_HF
    let deltaSteer = stgCenter - SAFE_H17
    
    let lost = deltaSeat - deltaPlate - K17 * deltaSteer
    let remaining = SAFE_CLEARANCE - max(0, lost)
    let collisionRisk = remaining < MIN_ALLOWED
    
    return (collisionRisk, max(0, remaining))
}

/// Check if position is dangerous (matching Python _is_danger function)
func isDanger(h5: Double, hf: Double, h17: Double) -> Bool {
    let remaining = remainingClearance(h5: h5, hf: hf, h17: h17)
    return remaining < MIN_ALLOWED
}

/// Calculate remaining clearance (matching Python _remaining_clearance function)
func remainingClearance(h5: Double, hf: Double, h17: Double) -> Double {
    let deltaSeat = h5 - SAFE_H5
    let deltaPlate = hf - SAFE_HF
    let deltaSteer = h17 - SAFE_H17
    
    let lost = deltaSeat - deltaPlate - K17 * deltaSteer
    return SAFE_CLEARANCE - max(0, lost)
}

/// Calculate H30 point value
func calculateH30Point(seatZ: Double, floorZ: Double) -> Double {
    return seatZ - floorZ
}

/// Validate and restrict input value to prevent collision
func validateInputValue(_ value: Double, for axis: AxisConfig, with currentState: SimulatorState) -> Double {
    // First check if value is within axis limits
    if value < axis.minValue || value > axis.maxValue {
        return axis.minValue..<axis.maxValue ~= value ? value : (value < axis.minValue ? axis.minValue : axis.maxValue)
    }
    
    // Set up test values using current state
    var testSeatZ = currentState.seatZSlider
    var testFloorZ = currentState.floorZSlider
    var testStgCenter = currentState.stgCenterSlider
    
    // Update the relevant test value
    switch axis.name {
    case "seat_z_axis":
        testSeatZ = value
    case "floor_z_axis":
        testFloorZ = value
    case "stg_wheel_center":
        testStgCenter = value
    case "seat_x_axis":
        return value  // X-axis doesn't affect collision
    default:
        return value
    }
    
    // Check if this would cause a collision
    let collisionCheck = checkCollisionRisk(seatZ: testSeatZ, floorZ: testFloorZ, stgCenter: testStgCenter)
    
    if collisionCheck.collisionRisk {
        // If it would cause collision, return the last known safe value
        switch axis.name {
        case "seat_z_axis":
            return currentState.seatZSlider
        case "floor_z_axis":
            return currentState.floorZSlider
        case "stg_wheel_center":
            return currentState.stgCenterSlider
        default:
            return value
        }
    }
    
    return value  // Value is safe to use
}

/// Find the maximum safe value for an axis to prevent collision
private func findMaxSafeValue(for axis: AxisConfig, with currentState: SimulatorState) -> Double {
    let minVal = axis.minValue
    let maxVal = axis.maxValue
    let step = abs(maxVal - minVal) / 100.0
    
    var safeValue = minVal
    var low = minVal
    var high = maxVal
    
    for _ in 0..<50 {
        let mid = (low + high) / 2.0
        
        var testSeatZ = currentState.seatZSlider
        var testFloorZ = currentState.floorZSlider
        var testStgCenter = currentState.stgCenterSlider
        
        switch axis.name {
        case "seat_z_axis":
            testSeatZ = mid
        case "floor_z_axis":
            testFloorZ = mid
        case "stg_wheel_center":
            testStgCenter = mid
        default:
            return mid
        }
        
        let collisionCheck = checkCollisionRisk(seatZ: testSeatZ, floorZ: testFloorZ, stgCenter: testStgCenter)
        
        if collisionCheck.collisionRisk {
            high = mid - step
        } else {
            safeValue = mid
            low = mid + step
        }
        
        if abs(high - low) < 1.0 {
            break
        }
    }
    
    return safeValue.rounded()
}
