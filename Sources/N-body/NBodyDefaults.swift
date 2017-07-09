//
//  NBodyDefaults.swift
//  Metal N-Body
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/12/13.
//
//
/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 Default values for N-body simulation.
 */

import Foundation

extension NBody {
    enum Defaults {
        static let kParticles = 1024 * 8
        static let kChannels  = 4
        static let kFrames    = 300
        static let kTexRes    = 64
        
        static let kAspectRatio: Float  = 1.0
        static let kCenter: Float       = 0.5
        static let kDamping: Float      = 1.0
        static let kPointSz: Float      = 10.0
        static let kSofteningSqr: Float = 1.0
        static let kTolerance: Float    = 1.0e-9
        static let kTimestep: Float     = 0.016
        static let kZCenter: Float      = 100.0
        
        enum Scale {
            static let kCluster: Float  = 1.54
            static let kVelocity: Float = 8.0
        }
        
        enum Configs: Int {
            case random = 0
            case shell
            case expand
            case count
        }
    }
}

