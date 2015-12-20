//
//  NBodyPreferences.swift
//  Metal N-Body
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/12/12.
//
//
/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 Keys for the N-Body application preferences, global parameters, and simulation properties.
 */

import Foundation

// Keys for the N-Body application prefs property list      // For values
let kNBodyGlobals    = "NBody_Globals"              // Dictionary
let kNBodyParameters = "NBody_Parameters"           // Array of dictionaries

// Keys for the N-Body globals parameters                   // For values
let kNBodyParticles = "NBody_Particles"             // Unsigned Integer 32
let kNBodyTexRes    = "NBody_Tex_Res"               // Unsigned Integer 32
let kNBodyChannels  = "NBody_Channels"              // Unsigned Integer 32

// Keys for the N-Body simulation properties                // For values
let kNBodyTimestep      = "NBody_Timestep"          // Float
let kNBodyClusterScale  = "NBody_Cluster_Scale"     // Float
let kNBodyVelocityScale = "NBody_Velocity_Scale"    // Float
let kNBodySoftening     = "NBody_Softening"         // Float
let kNBodyDamping       = "NBody_Damping"           // Float
let kNBodyPointSize     = "NBody_PointSize"         // Float
