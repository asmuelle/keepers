import Foundation

/// Platform-free mirror of the device thermal state so scheduler logic stays
/// pure and testable with injected states (invariant 7).
public enum ThermalState: String, Sendable, CaseIterable {
    case nominal
    case fair
    case serious
    case critical
}

public protocol ThermalStateProviding: Sendable {
    func currentState() -> ThermalState
}

/// Live provider backed by ProcessInfo — the real input to invariant 7.
public struct ProcessInfoThermalProvider: ThermalStateProviding {
    public init() {}

    public func currentState() -> ThermalState {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: .nominal
        case .fair: .fair
        case .serious: .serious
        case .critical: .critical
        @unknown default: .serious // unknown future states degrade conservatively
        }
    }
}

/// Constant provider for tests, previews, and the demo session.
public struct FixedThermalProvider: ThermalStateProviding {
    public let state: ThermalState

    public init(_ state: ThermalState) {
        self.state = state
    }

    public func currentState() -> ThermalState {
        state
    }
}
