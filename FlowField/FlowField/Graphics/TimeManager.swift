//
//  TimeManager.swift
//  FlowField
//
//  Created by Hollan Sellars on 12/18/25.
//

import Foundation

public struct TimeSlice {
    /// The total amount of time elapsed since the first evaluation.
    public let timeElapsed: Float;
    /// The total amount of time elapsed between the current and previous call.
    public let timeDelta: Float;
}

public struct TimeManager {
    public init() {
        self.clock = .init();
    }
    
    private var timeLast: ContinuousClock.Instant? = nil;
    private var timeTally: Float = 0.0;
    private let clock: ContinuousClock;
    
    public static let attosecondsConversion: Float = pow(10.0, -18.0);
    
    public mutating func step() -> TimeSlice {
        let currentTimeInstant = self.clock.now;
        let currentTime: Float;
        let timeDelta: Float;
        if let previousTimeInstant = self.timeLast {
            let (secondsElapsed, attoSecondsElapsed) = (currentTimeInstant - previousTimeInstant).components;
            timeDelta = Float(secondsElapsed) + (Float(attoSecondsElapsed) * TimeManager.attosecondsConversion);
            
            currentTime = self.timeTally + timeDelta;
            self.timeTally += timeDelta;
        }
        else {
            currentTime = 0.0;
            timeDelta = 0.0;
        }
        self.timeLast = currentTimeInstant;
        
        return TimeSlice(timeElapsed: currentTime, timeDelta: timeDelta)
    }
}
