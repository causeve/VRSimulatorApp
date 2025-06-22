import SwiftUI

@available(iOS 15.0, *)
struct AxisControlView: View {
    let axis: AxisConfig
    @Binding var value: Double
    let showAdvanced: Bool
    let disabled: Bool
    let simulatorState: SimulatorState
    let onGo: (Double) -> Void
    let onStop: () -> Void
    
    @StateObject private var viewModel = BLEViewModel()
    @State private var sliderValue: Double
    @State private var inputValue: String
    @State private var measurementValue: Double
    @State private var isUserInteracting: Bool = false
    @State private var goButtonState: ButtonState = .normal
    @State private var currentPosition: Double
    @State private var isInputValid: Bool = false
    @FocusState private var isInputFocused: Bool
    @State private var lastUserInput: String? = nil  // Track user's last input
    @State private var isUserInput: Bool = false     // Flag to track if current value is from user
    @State private var sliderAtLimit: Bool = false  // Add this state variable at the top with other @State variables
    
    init(axis: AxisConfig, value: Binding<Double>, showAdvanced: Bool, disabled: Bool, simulatorState: SimulatorState, onGo: @escaping (Double) -> Void, onStop: @escaping () -> Void) {
        self.axis = axis
        self._value = value
        self.showAdvanced = showAdvanced
        self.disabled = disabled
        self.simulatorState = simulatorState
        self.onGo = onGo
        self.onStop = onStop
        
        let sliderInitial = calculateSlider(for: axis.axisTag, fromMeasurement: value.wrappedValue)
        self._sliderValue = State(initialValue: sliderInitial)
        self._inputValue = State(initialValue: String(format: "%.1f", value.wrappedValue))
        self._measurementValue = State(initialValue: value.wrappedValue)
        self._currentPosition = State(initialValue: value.wrappedValue)
        
        // Validate initial value
        self._isInputValid = State(initialValue: false)
    }
    
    var body: some View {
        VStack {
            HStack(spacing: 8) {
                Image(axis.iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                
                Text(axis.label)
                    .font(.system(size: 16, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                // MIN label
                VStack(spacing: 2) {
                    Text("MIN")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Text("\(Int(axis.minValue))")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                .frame(width: 50)
                // Slider control section
                VStack(alignment: .leading, spacing: 4) {
                    Text("CUR POS : \(currentPosition, specifier: "%.1f")")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Slider(
                        value: $sliderValue,
                        in: sliderRange(),
                        step: 1,
                        onEditingChanged: { isEditing in
                            isUserInteracting = isEditing
                            if !isEditing {
                                // Only update input value if this was a user interaction
                                if isUserInput {
                                    inputValue = String(format: "%.1f", sliderValue)
                                    validateAndUpdateState(inputValue, isFromUser: true)
                                }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    if !isUserInteracting {
                                        sliderValue = currentPosition
                                    }
                                }
                            }
                            // Check if we hit the limit when stopping drag
                            if !isEditing {
                                checkSliderLimit()
                            }
                        }
                    )
                    .onChange(of: sliderValue) { newValue in
                        // Only update input value if user is dragging the slider
                        if isUserInteracting {
                            isUserInput = true  // Mark this as user input
                            inputValue = String(format: "%.1f", sliderValue)
                            validateAndUpdateState(inputValue, isFromUser: true)
                            // Check if we hit the limit while dragging
                            checkSliderLimit()
                        }
                    }
                    
                    // Warning text below slider
                    if let warningMessage = getWarningMessage() {
                        Text(warningMessage)
                            .font(.caption2)
                            .foregroundColor(.red)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    } else {
                        Color.clear
                            .frame(height: 12)
                    }
                }
                .frame(width: 180)
                
                // MAX label
                VStack(spacing: 2) {
                    Text("MAX")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Text("\(Int(axis.maxValue))")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                .frame(width: 50)
                
                
                // Input field
                TextField("Value", text: $inputValue)
                    .font(.system(.body, design: .monospaced))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 80)
                    .padding(8)
                    .background(isInputValid ? Color(.systemGray6) : Color.red.opacity(0.2))
                    .cornerRadius(6)
                    .focused($isInputFocused)
                .onChange(of: isInputFocused) { focused in
                    isUserInteracting = focused
                    if !focused {
                        clampInputToSafeRange()
                        updateFromInput()
                    }
                }
                .onChange(of: inputValue) { newValue in
                    validateAndUpdateState(newValue, isFromUser: true)
                    simulatorState.setInputValue(newValue, for: axis.axisTag.rawValue) // Sync input to global state
                    if newValue.isEmpty {
                        value = 0.0
                    } else {
                        updateFromInput()
                    }
                }
                .accessibilityLabel("\(axis.label) input value")
                
                HStack(spacing: 4) {
                    Button(action: handleGoClick) {
                        Text(goButtonState == .sent ? "SENT" : "GO")
                            .font(.caption2)
                            .frame(width: 44, height: 24)
                            .background(isGoButtonDisabled ? Color.gray : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }.disabled(isGoButtonDisabled)
                    
                    Button(action: onStop) {
                        Text("STOP")
                            .font(.caption2)
                            .frame(width: 44, height: 24)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }
                
                if showAdvanced {
                    VStack {
                        Text("MEAS").font(.caption2)
                        Text("\(Int(measurementValue))").font(.caption2)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray5))
            .cornerRadius(12)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            // Validate initial value
            validateAndUpdateState(String(format: "%.1f", value), isFromUser: true)
        }
        .onChange(of: value) { newValue in
            if !isUserInteracting {
                currentPosition = newValue
                sliderValue = calculateSlider(for: axis.axisTag, fromMeasurement: newValue)
                let newValueStr = String(format: "%.1f", newValue)
                inputValue = newValueStr
                measurementValue = calculateMeasurement(for: axis.axisTag, fromSliderValue: newValue)
                validateAndUpdateState(newValueStr, isFromUser: true)
            }
        }
        .onReceive(viewModel.$axisValue.compactMap { $0 }) { axisVal in
            guard let tag = mapBLEKeyToAxisTag(axisVal.axis), tag == axis.axisTag else { return }
            
            // Allow BLE updates regardless of input validity
            if !isUserInteracting {
                let bleValue = Double(axisVal.value)
                sliderValue = bleValue
                currentPosition = bleValue
                value = bleValue
                measurementValue = calculateMeasurement(for: axis.axisTag, fromSliderValue: bleValue)
                
                // Only update slider value in simulator state, not input value
                simulatorState.setSliderValue(bleValue, for: axis.axisTag.rawValue)
            }
        }
        
        // Reset user input flag when switching to a different axis
        .onDisappear {
            isUserInput = false
            lastUserInput = nil
        }
    }
    
    private func sliderRange() -> ClosedRange<Double> {
        // For slider movement, use the safe range to prevent collisions
        simulatorState.getSafeRange(for: axis)
    }
    
    private func updateFromSlider() {
        measurementValue = calculateMeasurement(for: axis.axisTag, fromSliderValue: sliderValue)
        inputValue = String(format: "%.0f", sliderValue)
    }
    
    private func updateFromInput() {
        if let parsed = Double(inputValue) {
            validateAndUpdateState(inputValue, isFromUser: true)
            if isInputValid {
                value = parsed
                measurementValue = calculateMeasurement(for: axis.axisTag, fromSliderValue: parsed)
            }
        } else {
            validateAndUpdateState("", isFromUser: true)
        }
    }
    
    private var isGoButtonDisabled: Bool {
        disabled || !isInputValid
    }
    
    private func handleGoClick() {
        guard !disabled && isInputValid, let inputNumValue = Double(inputValue) else { return }
        
        // If there's a collision risk, only allow movements that reduce the risk
        if simulatorState.collisionRisk {
            let currentValue = Double(currentPosition)
            let safeRange = simulatorState.getSafeRange(for: axis)
            
            // Only allow movement if it's towards a safer position
            if axis.axisTag == .seatZAxis && inputNumValue >= currentValue {
                return // Prevent moving seat up if there's already a collision risk
            }
            if axis.axisTag == .floorZAxis && inputNumValue <= currentValue {
                return // Prevent moving floor down if there's already a collision risk
            }
        }
        
        goButtonState = .sent
        onGo(inputNumValue)  // Send the actual input value
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            goButtonState = .normal
        }
    }
    
    private func validateAndUpdateState(_ value: String, isFromUser: Bool = false) {
        if isFromUser {
            isUserInput = true
            lastUserInput = value
        }
        
        if let numValue = Double(value) {
            // First validate basic range
            let inRange = numValue >= axis.minValue && numValue <= axis.maxValue
            
            // If the value was adjusted due to collision risk, show warning but don't invalidate
            let safeValue = simulatorState.clampToSafeRange(numValue, for: axis)
            if abs(numValue - safeValue) > 0.1 {
                sliderAtLimit = true
            }
            
            // Set input as valid if it's in range, regardless of collision risk
            isInputValid = inRange
        } else {
            isInputValid = false
        }
        
        simulatorState.setInputValidity(isInputValid, for: axis.axisTag.rawValue)
    }
    
    private func validateInput(_ value: String) -> Bool {
        guard let numValue = Double(value) else {
            return false
        }
        
        // Only check if the value is within the axis's min/max range
        let isValid = numValue >= axis.minValue && numValue <= axis.maxValue
        return isValid
    }
    
    private func clampInputToSafeRange() {
        if let v = Double(inputValue) {
            let safe = simulatorState.clampToSafeRange(v, for: axis)
            if v != safe {
                inputValue = String(format: "%.0f", safe)
                // Set sliderAtLimit to true to show the warning message
                sliderAtLimit = true
            }
        }
    }
    
    private func getWarningMessage() -> String? {
        guard let value = Double(inputValue) else { return nil }
        
        // Get the full range (without collision restrictions)
        let fullRange = axis.minValue...axis.maxValue
        let safeRange = simulatorState.getSafeRange(for: axis)
        
        // If slider is at limit and the full range is bigger, show why it's restricted
        if sliderAtLimit && value == safeRange.upperBound && safeRange.upperBound < fullRange.upperBound {
            return "Restricted \(Int(safeRange.upperBound)) (collision risk)"
        }
        if sliderAtLimit && value == safeRange.lowerBound && safeRange.lowerBound > fullRange.lowerBound {
            return "Restricted \(Int(safeRange.lowerBound)) (collision risk)"
        }
        
        // Check if value is outside axis range
        if value < axis.minValue {
            return "Below min (\(Int(axis.minValue)))"
        }
        if value > axis.maxValue {
            return "Above max (\(Int(axis.maxValue)))"
        }
        
        return nil
    }
    
    // Add this function to check if slider is at its limit
    private func checkSliderLimit() {
        let safeRange = simulatorState.getSafeRange(for: axis)
        let fullRange = axis.minValue...axis.maxValue
        
        // Check if we're at a limit that's different from the full range
        sliderAtLimit = (abs(sliderValue - safeRange.upperBound) < 0.1 && safeRange.upperBound < fullRange.upperBound) ||
                       (abs(sliderValue - safeRange.lowerBound) < 0.1 && safeRange.lowerBound > fullRange.lowerBound)
    }
}

func mapBLEKeyToAxisTag(_ key: String) -> AxisTag? {
    switch key {
    case "x": return .seatXAxis
    case "z": return .seatZAxis
    case "f": return .floorZAxis
    case "s": return .stgWheelCenter
    default: return nil
    }
}
