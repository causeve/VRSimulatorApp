//
//  BLEViewModel.swift
//  VRSimulator
//
//  Created by Dhanalakshmi on 21/05/25.
//


import Combine
import Foundation

class BLEViewModel: ObservableObject {
    @Published var axisValue: AxisValue?
    private var cancellables = Set<AnyCancellable>()
    private let bleManager = BLEManager()
    
    init() {
        setupBLE()
    }
    
    private func setupBLE() {
        //        bleManager.axisPublisher
        //            .sink { axisValue in
        //                print("Received value: \(axisValue.axis) = \(axisValue.value)")
        //            }
        bleManager.axisPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] axisValue in
                self?.axisValue = axisValue
            }
            .store(in: &cancellables)
    }
}
