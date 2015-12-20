//
//  NBodyVisualizer.swift
//  Metal N-Body
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/12/14.
//
//
/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 N-body controller object for visualizing the simulation.
 */

import simd
import QuartzCore.CAMetalLayer
import Metal

@objc(NBodyVisualizer)
class NBodyVisualizer: NSObject {
    
    // Query to determine if all resources were instantiated
    private(set) var haveVisualizer: Bool = false
    
    // Generate all the resources necessary for N-body simulation
    private var _device: MTLDevice?
    var device: MTLDevice? {
        get {return _device}
        set {acquire(newValue)}
    }
    
    // Render a frame for N-body simaulation
    private var _drawable: CAMetalDrawable?
    var drawable: CAMetalDrawable? {
        get {return _drawable}
        set {render(newValue)}
    }
    
    // Orthographic projection configuration type
    var config: NBody.Defaults.Configs = .Random
    
    // Coordinate points on the Eunclidean axis of simulation
    private var _axis: float3 = float3()
    
    // Aspect ratio
    private var _aspect: Float = 0.0
    
    // Total number of frames to be rendered for a N-body simulation type
    private var _frames: Int = 0
    
    // The number of point particels
    private var _particles: Int = 0
    
    // Texture resolution.  The default is 64x64.
    private var _texRes: Int = 0
    
    // Becomes true once all the frames for a simulation type are rendered
    private(set) var isComplete: Bool = false
    
    // Current active simulation type
    private(set) var active: Int = 0
    
    // Current frame being rendered
    private(set) var frame: Int = 0
    
    private var mnCount: Int = 0
    
    private var mpProperties: NBodyProperties?
    private var mpGenerator: NBodyURDGenerator?
    private var mpPresenter: MetalNBodyPresenter?
    
    override init() {
        
        haveVisualizer = false
        isComplete     = false
        
        _aspect    = NBody.Defaults.kAspectRatio
        _frames    = NBody.Defaults.kFrames
        config    = NBody.Defaults.Configs.Shell
        _texRes    = NBody.Defaults.kTexRes
        _particles = Int(NBody.Defaults.kParticles)
        
        active = 0
        frame  = 0
        
        _device   = nil
        _drawable = nil
        
        mpProperties = nil
        mpGenerator  = nil
        mpPresenter  = nil
        
        super.init()
    }
    
    // Coordinate points on the Eunclidean axis of simulation
    var axis: float3 {
        get {return _axis}
        set {
            mpGenerator?.axis = newValue
        }
    }
    
    // Aspect ratio
    var aspect: Float {
        get {return _aspect}
        set {
            let nEPS = NBody.Defaults.kTolerance
            
            _aspect = CM.isLT(nEPS, newValue) ? newValue : 1.0
        }
    }
    
    // The number of point particels
    var particles: Int {
        get {return _particles}
        set {
            if !haveVisualizer {
                _particles = (newValue != 0) ? newValue : NBody.Defaults.kParticles
                mpProperties?.particles = _particles
            }
        }
    }
    
    // Texture resolution.  The default is 64x64.
    var texRes: Int {
        get {return _texRes}
        set {
            if !haveVisualizer {
                _texRes = (newValue > 64) ? newValue :  NBody.Defaults.kTexRes
                mpProperties?.texRes = _texRes
            }
        }
    }
    
    // Total number of frames to be rendered for a N-body simulation type
    var frames: Int {
        get {return _frames}
        set {
            _frames = (newValue != 0) ? newValue : NBody.Defaults.kFrames
        }
    }
    
    private func _acquire(device: MTLDevice?) -> Bool {
        guard let _ = device else {
            return false
        }
        // Get the N-body simulation properties from a property list file in app's resource
        let mpProperties = NBodyProperties()
        self.mpProperties = mpProperties
        
        mnCount = mpProperties.count
        
        guard mnCount != 0 else {
            NSLog(">> ERROR: Empty array for N-Body properties!")
            
            return false
        }
        
        // Instantiate a new generator object for initial simualtion random data
        let mpGenerator = NBodyURDGenerator()
        self.mpGenerator = mpGenerator
        
        // Instantiate a new render encoder object for N-body simaulation
        let mpPresenter = MetalNBodyPresenter()
        self.mpPresenter = mpPresenter
        
        mpPresenter.globals = mpProperties.globals
        mpPresenter.device  = device
        
        guard mpPresenter.haveEncoder else {
            NSLog(">> ERROR: Failed to acquire resources for the render encoder object!")
            
            return false
        }
        
        return true
    }
    
    private func _update() {
        NSLog(">> MESSAGE[N-Body]: Demo [\(active)] selected!")
        
        // Update the linear transformation matrices
        mpPresenter?.update = true
        
        // Select a new dictionary of key-value pairs for simulation properties
        mpProperties?.config = active
        
        // Using the properties dictionary generate initial data for the simulation
        mpGenerator?.parameters = mpProperties?.parameters
        mpGenerator?.colors     = mpPresenter?.colors ?? nil
        mpGenerator?.position   = mpPresenter?.position ?? nil
        mpGenerator?.velocity   = mpPresenter?.velocity ?? nil
        mpGenerator?.config     = config
    }
    
    // Generate all the resources necessary for N-body simulation
    private func acquire(device: MTLDevice?) {
        if !haveVisualizer {
            haveVisualizer = self._acquire(device)
            
            if haveVisualizer {
                self._update()
            }
        }
    }
    
    // Render a new frame
    private func _renderFrame(drawable: CAMetalDrawable?) {
        mpPresenter?.aspect     = _aspect;                 // Update the aspect ratio
        mpPresenter?.parameters = mpProperties?.parameters; // Update the simulation parameters
        mpPresenter?.drawable   = drawable;                // Set the new drawable and present
    }
    
    // Go to a new frame
    private func _nextFrame() {
        frame++
        
        isComplete = (frame % _frames) == 0
        
        // If we reach the maximum number of frames switch to a new simulation type
        if isComplete {
            mpPresenter?.finish()
            
            active = (active + 1) % mnCount
            
            self._update()
        }
    }
    
    // Render a frame for N-body simaulation
    private func render(drawable: CAMetalDrawable?) {
        if let drawable = drawable {
            self._renderFrame(drawable)
            self._nextFrame()
        }
    }
    
}