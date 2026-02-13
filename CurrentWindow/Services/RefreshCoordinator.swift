//
//  RefreshCoordinator.swift
//  CurrentWindow
//
//  Manages refresh timing, position tracking, and adaptive refresh rates
//

import Foundation
import ApplicationServices

class RefreshCoordinator {
    
    // Adaptive refresh rates
    private let fastRefreshInterval: TimeInterval = 0.3
    private let slowRefreshInterval: TimeInterval = 2.0
    private(set) var refreshInterval: TimeInterval = 0.3
    
    // Position tracking
    private var lastRefreshPosition: CGRect?
    private var timeSinceLastChange: TimeInterval = 0
    private let movementPauseThreshold: TimeInterval = 3.0
    
    // Timer management
    private var refreshTimer: Timer?
    private var isRefreshing: Bool = false
    
    // Callbacks
    var onRefreshNeeded: (() -> Void)?
    
    // MARK: - Public Methods
    
    /// Start periodic refresh with adaptive rates
    func startPeriodicRefresh() {
        stopPeriodicRefresh()
        
        refreshTimer = Timer.scheduledTimer(
            withTimeInterval: refreshInterval,
            repeats: true
        ) { [weak self] _ in
            self?.performPeriodicCheck()
        }
    }
    
    /// Stop periodic refresh
    func stopPeriodicRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    /// Restart with new interval
    func restartPeriodicRefresh() {
        startPeriodicRefresh()
    }
    
    /// Pause refresh (called when no overlays exist)
    func pauseRefresh() {
        stopPeriodicRefresh()
        lastRefreshPosition = nil
    }
    
    /// Check the current window position and determine if refresh is needed
    func checkPositionAndRefresh(currentPosition: CGRect?, onRefresh: () -> Void) {
        guard let currentRefreshPosition = currentPosition else {
            if !overlaysExist() {
                print("No overlays - pausing refresh timer")
                pauseRefresh()
            }
            return
        }
        
        // Check if position changed (with tolerance)
        if lastRefreshPosition == nil || !currentRefreshPosition.isEffectivelyEqual(to: lastRefreshPosition!, tolerance: 2.0) {
            // Position changed, refresh
            onRefresh()
            lastRefreshPosition = currentRefreshPosition
            timeSinceLastChange = 0
            refreshInterval = fastRefreshInterval
        } else {
            timeSinceLastChange += refreshInterval
            if timeSinceLastChange >= movementPauseThreshold && refreshInterval != slowRefreshInterval {
                refreshInterval = slowRefreshInterval
                // Position stable - using slower refresh
                restartPeriodicRefresh()
            }
        }
    }
    
    /// Trigger immediate refresh (for events like window move/resize)
    func triggerImmediateRefresh() {
        // Reset to fast refresh when user interacts
        refreshInterval = fastRefreshInterval
        timeSinceLastChange = 0
        
        // Restart timer with fast interval
        if refreshTimer != nil {
            restartPeriodicRefresh()
        }
        
        // Trigger callback immediately
        onRefreshNeeded?()
    }
    
    /// Reset position tracking
    func resetPositionTracking() {
        lastRefreshPosition = nil
        timeSinceLastChange = 0
        refreshInterval = fastRefreshInterval
    }
    
    // MARK: - Private Methods
    
    private func performPeriodicCheck() {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        onRefreshNeeded?()
        isRefreshing = false
    }
    
    private func overlaysExist() -> Bool {
        // This will be set externally by the coordinator
        return refreshTimer != nil
    }
}
