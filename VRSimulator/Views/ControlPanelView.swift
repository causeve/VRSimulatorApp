import SwiftUI
import Combine

struct ControlPanelView: View {
    @StateObject private var viewModel = BLEViewModel()
    @StateObject private var bleManager = BLEManager()
    @StateObject private var simulatorState = SimulatorState()
    @State private var showAdvanced = false
    @State private var allGoButtonState: ButtonState = .normal
    @State private var allStopButtonState: ButtonState = .normal
    @State private var orientation = UIDeviceOrientation.unknown
    @EnvironmentObject var authService: AuthenticationService
    
    private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 0) {
                    // Top Bar
                    topBar
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    
                    // Main Content
                    VStack {
                        // Advanced Mode Toggle
                        advancedModeToggle
                        
                        // Axis Controls
                        VStack(spacing: 10) {
                            ForEach(AXES_CONFIG) { axis in
                                AxisControlView(
                                    axis: axis,
                                    value: binding(for: axis.name),
                                    showAdvanced: showAdvanced,
                                    disabled: false,
                                    simulatorState: simulatorState,
                                    onGo: { value in handleAxisGo(axis, value) },
                                    onStop: { handleAxisStop(axis) }
                                )
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .padding(.horizontal, 20)
                        
                        // Output Display
                        outputDisplay
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        
                        // Command Buttons
                        commandButtons
                            .padding(.horizontal, 20)
                        
                        // Diagram view based on interface orientation
                        if geometry.size.width < geometry.size.height {
                            diagramView
                        } else {
                            Text("Please rotate to portrait mode to see the diagram")
                                .padding()
                        }
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .navigationBarHidden(true)
        .preferredColorScheme(.light)
        .onAppear {
            if let axiz = viewModel.axisValue {
                updateAxisValue(axiz)
            }
        }
        .onDisappear {
            bleManager.cleanup()
        }
        .onReceive(viewModel.$axisValue.compactMap { $0 }) { axisValue in
            updateAxisValue(axisValue)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    hideKeyboard()
                }
            }
        }
    }
    
    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            BLEStatusIndicatorView(status: bleManager.status)
            
            Spacer()
            
            Text("VR Simulator Control Panel")
                .font(.system(size: 35, weight: .bold))
                .foregroundColor(.primary)
            
            Spacer()
            
            Button("Logout") {
                authService.logout()
            }
            .buttonStyle(.bordered)
            .font(.title3)
            .padding(.bottom, 10)
        }
    }
    
    // MARK: - Advanced Mode Toggle
    private var advancedModeToggle: some View {
        HStack {
            Spacer()
            Text("Advanced Mode")
                .font(.body)
                .fontWeight(.medium)
            
            Toggle("", isOn: $showAdvanced)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: .blue))
        }
        .padding(.trailing)
    }
    
    // MARK: - Command Buttons
    private var commandButtons: some View {
        HStack(spacing: 20) {
            Button(action: handleAllGo) {
                HStack {
                    if allGoButtonState == .sent {
                        Text("SENT")
                            .fontWeight(.bold)
                            .font(.title2)
                    } else {
                        Text("ALL GO")
                            .fontWeight(.bold)
                            .font(.title2)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isAllGoDisabled ? Color.gray : Color.green)
                .cornerRadius(12)
            }
            .disabled(isAllGoDisabled)
            .accessibilityLabel("Send all axis commands")
            
            Button(action: handleAllStop) {
                HStack {
                    if allStopButtonState == .sent {
                        Text("SENT")
                            .fontWeight(.bold)
                            .font(.title2)
                    } else {
                        Text("ALL STOP")
                            .fontWeight(.bold)
                            .font(.title2)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.red)
                .cornerRadius(12)
            }
            .accessibilityLabel("Stop all axis movements")
        }
    }
    
    private var isAllGoDisabled: Bool {
        // Check if all inputs are valid numbers within their ranges AND user has entered all values
        let hasInvalidInputs = !simulatorState.seatXValid || 
                              !simulatorState.seatZValid || 
                              !simulatorState.floorZValid || 
                              !simulatorState.stgCenterValid
        
        let hasAllUserInput = simulatorState.allAxesHaveUserInput
        
        return hasInvalidInputs || !hasAllUserInput
    }
    
    // MARK: - Output Display
    private var outputDisplay: some View {
        OutputCardView(
            title: "H30 Point",
            value: String(format: "%.1f", simulatorState.h30Point),
            description: "= H5 - HF"
        )
    }
    
    // MARK: - Helper Methods
    
    private func binding(for axisName: String) -> Binding<Double> {
        switch axisName {
        case "seat_x_axis":
            return $simulatorState.seatXSlider
        case "seat_z_axis":
            return $simulatorState.seatZSlider
        case "floor_z_axis":
            return $simulatorState.floorZSlider
        case "stg_wheel_center":
            return $simulatorState.stgCenterSlider
        default:
            return .constant(0)
        }
    }
    
    private func updateAxisValue(_ axisValue: AxisValue) {
        // Update slider values from BLE notifications (matching Python notification processing)
        let value = Double(axisValue.value)
        switch axisValue.axis {
        case "x":
            simulatorState.setSliderValue(value, for: "seat_x_axis")
        case "z":
            simulatorState.setSliderValue(value, for: "seat_z_axis")
        case "f":
            simulatorState.setSliderValue(value, for: "floor_z_axis")
        case "s":
            simulatorState.setSliderValue(value, for: "stg_wheel_center")
        default:
            break
        }
        
        // Only update measurements and derived values, not input values
        simulatorState.updateAllMeasurementsFromSliders()
        simulatorState.updateDerivedValues()
    }
    
    private func handleAxisGo(_ axis: AxisConfig, _ value: Double) {
        
        let success = bleManager.sendCommand(axis: axis.apiKey, value: Int(value))
    }
    
    private func handleAxisStop(_ axis: AxisConfig) {
        let currentValue = getCurrentValue(for: axis.name)
        let success = bleManager.sendCommand(axis: axis.apiKey, value: Int(currentValue))
        if success {
          //  print("Sent stop command for \(axis.label): \(currentValue)")
        }
    }
    
    private func getCurrentValue(for axisName: String) -> Double {
        switch axisName {
        case "seatX": return simulatorState.seatXSlider
        case "seatZ": return simulatorState.seatZSlider
        case "floorZ": return simulatorState.floorZSlider
        case "stgCenter": return simulatorState.stgCenterSlider
        default: return 0
        }
    }
    
    private func handleAllGo() {
        // Check both input validity and user input
        if !simulatorState.areAllInputsValid || !simulatorState.allAxesHaveUserInput {
            return 
        }
        
        // Get input field values and convert to numbers
        guard let seatX = Double(simulatorState.seatXInput),
              let seatZ = Double(simulatorState.seatZInput),
              let floorZ = Double(simulatorState.floorZInput),
              let stgCenter = Double(simulatorState.stgCenterInput) else {
            return
        }
        
        let commands: [(axis: String, value: Int)] = [
            ("x", Int(seatX)),
            ("z", Int(seatZ)),
            ("f", Int(floorZ)),
            ("s", Int(stgCenter))
        ]
        
        allGoButtonState = .sent
        bleManager.sendSequentialCommands(commands: commands) { success in
            DispatchQueue.main.async {
                self.allGoButtonState = .normal
            }
        }
    }
    
    private func handleAllStop() {
        let commands: [(axis: String, value: Int)] = [
            ("x", Int(simulatorState.seatXSlider)),
            ("z", Int(simulatorState.seatZSlider)),
            ("f", Int(simulatorState.floorZSlider)),
            ("s", Int(simulatorState.stgCenterSlider))
        ]
        
        allStopButtonState = .sent
        
        bleManager.sendSequentialCommands(commands: commands) { success in
            DispatchQueue.main.async {
                self.allStopButtonState = .normal
            }
        }
    }
    
    // Add new view for diagram with measurements
    private var diagramView: some View {
        VStack {
            GeometryReader { geometry in
                Image("simulator_diagram")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width - 40)
                    .padding(.horizontal, 40)
                    .overlay(
                        ZStack {
                            // L63 (432) - Adjust to be right above L63 line
                            Text("= \(Int(simulatorState.seatXSlider))")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.red)
                                .padding(4)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white)
                                        .shadow(color: .gray.opacity(0.6), radius: 3, x: 1, y: 2)
                                )
                                .position(x: geometry.size.width * 0.47, y: geometry.size.height * 0.1965)
                            
                            // H5 (720) - Adjust to be next to seat height
                            Text("= \(Int(simulatorState.seatZSlider))")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.red)
                                .padding(4)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white)
                                        .shadow(color: .gray.opacity(0.6), radius: 3, x: 1, y: 2)
                                )
                                .position(x: geometry.size.width * 0.28, y: geometry.size.height * 0.70)
                            
                            // HF (425) - Adjust to be at bottom left
                            Text("= \(Int(simulatorState.floorZSlider))")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.red)
                                .padding(4)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white)
                                        .shadow(color: .gray.opacity(0.6), radius: 3, x: 1, y: 2)
                                )
                                .position(x: geometry.size.width * 0.852, y: geometry.size.height * 0.80)
                            
                            // H17 (697) - Keep current position as it's correct
                            Text("= \(Int(simulatorState.stgCenterSlider))")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.red)
                                .padding(4)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white)
                                        .shadow(color: .gray.opacity(0.6), radius: 3, x: 1, y: 2)
                                )
                                .position(x: geometry.size.width * 0.852, y: geometry.size.height * 0.47)
                            
                            // H30 (295) - Adjust to be in center of H30 measurement
                            Text("= \(Int(simulatorState.h30Point))")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.red)
                                .padding(4)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white)
                                        .shadow(color: .gray.opacity(0.6), radius: 3, x: 1, y: 2)
                                )
                                .position(x: geometry.size.width * 0.55, y: geometry.size.height * 0.59)
                        }
                    )
            }
            .frame(height: UIScreen.main.bounds.height * 0.3)
            .padding(.horizontal, 5)
        }
        .padding(.top, 20)
    }
}


