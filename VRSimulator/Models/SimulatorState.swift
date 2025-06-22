import Foundation

class SimulatorState: ObservableObject {
    @Published var seatXSlider: Double = 432.5
    @Published var seatZSlider: Double = 720
    @Published var floorZSlider: Double = 425
    @Published var stgCenterSlider: Double = 697.5
    
    @Published var seatXInput: String = ""
    @Published var seatZInput: String = ""
    @Published var floorZInput: String = ""
    @Published var stgCenterInput: String = ""
    
    @Published var seatXMeasurement: Double = 0
    @Published var seatZMeasurement: Double = 0
    @Published var floorZMeasurement: Double = 0
    @Published var stgCenterMeasurement: Double = 0
    
    @Published var h30Point: Double = 0
    @Published var collisionRisk: Bool = false
    @Published var remainingDistance: Double = 230
    
    @Published var seatXValid: Bool = false
    @Published var seatZValid: Bool = false
    @Published var floorZValid: Bool = false
    @Published var stgCenterValid: Bool = false
    
    // Track whether user has explicitly entered values
    @Published var seatXHasUserInput: Bool = false
    @Published var seatZHasUserInput: Bool = false
    @Published var floorZHasUserInput: Bool = false
    @Published var stgCenterHasUserInput: Bool = false
    
    private var prevSafeValues: [String: Double] = [:]
    
    init() {
        // Initialize with empty input values
        validateInitialValues()
        updateAllMeasurementsFromSliders()
        updateDerivedValues()
    }
    
    private func validateInitialValues() {
        // Start with empty input fields and invalid state
        seatXValid = false
        seatZValid = false
        floorZValid = false
        stgCenterValid = false
        
        seatXHasUserInput = false
        seatZHasUserInput = false
        floorZHasUserInput = false
        stgCenterHasUserInput = false
    }
    
    func setInputValidity(_ isValid: Bool, for axisName: String) {
        DispatchQueue.main.async {
            switch axisName {
            case AxisTag.seatXAxis.rawValue: self.seatXValid = isValid
            case AxisTag.seatZAxis.rawValue: self.seatZValid = isValid
            case AxisTag.floorZAxis.rawValue: self.floorZValid = isValid
            case AxisTag.stgWheelCenter.rawValue: self.stgCenterValid = isValid
            default: break
            }
        }
    }
    
    var areAllInputsValid: Bool {
        return seatXValid && seatZValid && floorZValid && stgCenterValid
    }
    
    func updateAllMeasurementsFromSliders() {
        // Only update measurement values, not input values
        for axis in AXES_CONFIG {
            let sliderValue = getSliderValue(for: axis.name)
            let measurement = axisMappings[axis.axisTag]?.sliderToMeasurement(sliderValue) ?? sliderValue
            setMeasurementValue(measurement, for: axis.name)
        }
    }
    
    func updateDerivedValues() {
        // Always use slider values for H30 point
        h30Point = seatZSlider - floorZSlider
        
        // Check current slider positions for collision
        let sliderCollision = checkCollisionRisk(
            seatZ: seatZSlider,
            floorZ: floorZSlider,
            stgCenter: stgCenterSlider
        )
        
        // Update collision status
        collisionRisk = sliderCollision.collisionRisk
        remainingDistance = sliderCollision.remainingDistance
        
        // Update input validities based on range checks only
        // This ensures GO buttons can work even with collision risks
        seatXValid = validateInputRange(seatXInput, for: AXES_CONFIG[0])
        seatZValid = validateInputRange(seatZInput, for: AXES_CONFIG[1])
        floorZValid = validateInputRange(floorZInput, for: AXES_CONFIG[2])
        stgCenterValid = validateInputRange(stgCenterInput, for: AXES_CONFIG[3])
        
    }
    
    private func validateInputRange(_ input: String, for axis: AxisConfig) -> Bool {
        guard let value = Double(input) else { return false }
        return value >= axis.minValue && value <= axis.maxValue
    }
    
    func checkCollisionRisk(seatZ: Double, floorZ: Double, stgCenter: Double) -> (collisionRisk: Bool, remainingDistance: Double) {
        let deltaSeat = seatZ - SAFE_H5
        let deltaPlate = floorZ - SAFE_HF
        let deltaSteer = stgCenter - SAFE_H17
        
        let lost = deltaSeat - deltaPlate - K17 * deltaSteer
        let remaining = SAFE_CLEARANCE - max(0, lost)
        let risk = remaining < MIN_ALLOWED
        
        return (risk, remaining)
    }
    
    func getSliderValue(for axisName: String) -> Double {
        switch axisName {
        case "seat_x_axis": return seatXSlider
        case "seat_z_axis": return seatZSlider
        case "floor_z_axis": return floorZSlider
        case "stg_wheel_center": return stgCenterSlider
        default: return 0
        }
    }
    
    func setSliderValue(_ value: Double, for axisName: String) {
        // Only update slider value, not input value
        switch axisName {
        case "seat_x_axis": seatXSlider = value
        case "seat_z_axis": seatZSlider = value
        case "floor_z_axis": floorZSlider = value
        case "stg_wheel_center": stgCenterSlider = value
        default: break
        }
    }
    
    func getMeasurementValue(for axisName: String) -> Double {
        switch axisName {
        case "seat_x_axis": return seatXMeasurement
        case "seat_z_axis": return seatZMeasurement
        case "floor_z_axis": return floorZMeasurement
        case "stg_wheel_center": return stgCenterMeasurement
        default: return 0
        }
    }
    
    func setMeasurementValue(_ value: Double, for axisName: String) {
        switch axisName {
        case "seat_x_axis": seatXMeasurement = value
        case "seat_z_axis": seatZMeasurement = value
        case "floor_z_axis": floorZMeasurement = value
        case "stg_wheel_center": stgCenterMeasurement = value
        default: break
        }
    }
    
    func getInputValue(for axisName: String) -> String {
        switch axisName {
        case "seat_x_axis": return seatXInput
        case "seat_z_axis": return seatZInput
        case "floor_z_axis": return floorZInput
        case "stg_wheel_center": return stgCenterInput
        default: return ""
        }
    }
    
    func setInputValue(_ value: String, for axisName: String) {
        // Track that user has explicitly entered a value
        switch axisName {
        case "seat_x_axis":
            seatXInput = value
            seatXHasUserInput = true
        case "seat_z_axis":
            seatZInput = value
            seatZHasUserInput = true
        case "floor_z_axis":
            floorZInput = value
            floorZHasUserInput = true
        case "stg_wheel_center":
            stgCenterInput = value
            stgCenterHasUserInput = true
        default: break
        }
        
        // Update derived values for collision warning display only
        updateDerivedValues()
        
        // Validate the input range only (not collision)
        if let numValue = Double(value) {
            let config = AXES_CONFIG.first { $0.name == axisName.replacingOccurrences(of: "_axis", with: "") }
            if let axis = config {
                let isValid = numValue >= axis.minValue && numValue <= axis.maxValue
                setInputValidity(isValid, for: axisName)
            }
        } else {
            setInputValidity(false, for: axisName)
        }
    }
    
    private func validateInputForCollision(value: Double, axisName: String) -> Bool {
        // First check if value is within axis limits
        let config = AXES_CONFIG.first { $0.name == axisName.replacingOccurrences(of: "_axis", with: "") }
        guard let axis = config else { return true }
        
        if value < axis.minValue || value > axis.maxValue {
            return false
        }
        
        // Use input value for the axis being changed, and current slider values for the others
        var testSeatZ = seatZSlider
        var testFloorZ = floorZSlider
        var testStgCenter = stgCenterSlider
        
        switch axisName {
        case "seat_z_axis": testSeatZ = value
        case "floor_z_axis": testFloorZ = value
        case "stg_wheel_center": testStgCenter = value
        case "seat_x_axis": return true  // X-axis doesn't affect collision
        default: return true
        }
        
        // Check if this would cause a collision
        let collisionCheck = checkCollisionRisk(
            seatZ: testSeatZ,
            floorZ: testFloorZ,
            stgCenter: testStgCenter
        )
            
        return !collisionCheck.collisionRisk
    }
    
    func setPrevSafeValue(_ value: Double, for axisName: String) {
        prevSafeValues[axisName] = value
    }
    
    func getPrevSafeValue(for axisName: String) -> Double {
        return prevSafeValues[axisName] ?? getSliderValue(for: axisName)
    }
    
    // Clamp a value to the safe range for an axis
    func clampToSafeRange(_ value: Double, for axis: AxisConfig) -> Double {
        // Exempt X axis from dynamic safe range
        if axis.axisTag == .seatXAxis {
            return min(max(value, axis.minValue), axis.maxValue)
        }
        
        // First clamp to axis min/max
        let clampedToRange = min(max(value, axis.minValue), axis.maxValue)
        
        // Then get safe range considering collisions
        let safeRange = getSafeRange(for: axis)
        return min(max(clampedToRange, safeRange.lowerBound), safeRange.upperBound)
    }
    
    // Calculate the maximum safe value for an axis to prevent collision
    func getSafeRange(for axis: AxisConfig) -> ClosedRange<Double> {
        // Exempt X axis from dynamic safe range
        if axis.axisTag == .seatXAxis {
            return axis.minValue...axis.maxValue
        }
        
        // Start with full range
        var minVal = axis.minValue
        var maxVal = axis.maxValue
        
        // Test values at current positions
        var testSeatZ = seatZSlider
        var testFloorZ = floorZSlider
        var testStgCenter = stgCenterSlider
        
        // Binary search for safe range
        for v in stride(from: axis.minValue, through: axis.maxValue, by: 1) {
            switch axis.axisTag {
            case .seatZAxis: testSeatZ = v
            case .floorZAxis: testFloorZ = v
            case .stgWheelCenter: testStgCenter = v
            default: break
            }
            
            let collision = checkCollisionRisk(
                seatZ: testSeatZ,
                floorZ: testFloorZ,
                stgCenter: testStgCenter
            )
            
            if !collision.collisionRisk {
                minVal = v
                break
            }
        }
        
        // Reset test values
        testSeatZ = seatZSlider
        testFloorZ = floorZSlider
        testStgCenter = stgCenterSlider
        
        for v in stride(from: axis.maxValue, through: axis.minValue, by: -1) {
            switch axis.axisTag {
            case .seatZAxis: testSeatZ = v
            case .floorZAxis: testFloorZ = v
            case .stgWheelCenter: testStgCenter = v
            default: break
            }
            
            let collision = checkCollisionRisk(
                seatZ: testSeatZ,
                floorZ: testFloorZ,
                stgCenter: testStgCenter
            )
            
            if !collision.collisionRisk {
                maxVal = v
                break
            }
        }
        
        return minVal...maxVal
    }
    
    // Add a function to check if all axes have user input
    var allAxesHaveUserInput: Bool {
        return seatXHasUserInput && seatZHasUserInput && floorZHasUserInput && stgCenterHasUserInput
    }
}
