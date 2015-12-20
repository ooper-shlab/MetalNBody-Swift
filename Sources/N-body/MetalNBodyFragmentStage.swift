//
//  MetalNBodyFragmentStage.swift
//  Metal N-Body
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/12/13.
//
//
/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 Utility class for creating N-body simulation fragment stage.
 */

import Metal

@objc(MetalNBodyFragmentStage)
class MetalNBodyFragmentStage: NSObject {
    
    // Query to determine if all the resource were instantiated.
    private(set) var isStaged: Bool = false
    
    // N-body simulation global parameters
    private var _globals: [String: AnyObject]?
    
    // Fragment function name
    var name: String?
    
    // Metal library to use for instantiating a fragment stage
    var library: MTLLibrary?
    
    // Fragment stage function
    private(set) var function: MTLFunction?
    
    // Generate all the necessary fragment stage resources using a default system device
    private var _device: MTLDevice?
    var device: MTLDevice? {
        get {return _device}
        set {acquire(newValue)}
    }
    
    // Encode texture and sampler for the fragment stage
    private var _cmdEncoder: MTLRenderCommandEncoder?
    var cmdEncoder: MTLRenderCommandEncoder? {
        get {return _cmdEncoder}
        set {encode(newValue)}
    }
    
    private var mnParticles: Int = 0
    private var mnChannels: Int = 0
    private var mnTexRes: Int = 0
    
    private var mpGaussian: MetalGaussianMap?
    private var mpSampler: MetalNBodySampler?
    
    override init() {
        
        name     = nil
        _globals  = nil
        function = nil
        
        isStaged = false
        
        mnParticles = NBody.Defaults.kParticles
        mnTexRes    = NBody.Defaults.kTexRes
        mnChannels  = NBody.Defaults.kChannels
        
        mpGaussian = nil
        mpSampler  = nil
        
        super.init()
    }
    
    // N-body simulation global parameters
    var globals: [String: AnyObject]? {
        get {return _globals}
        set {
            if newValue != nil && !isStaged {
                _globals = newValue
                
                mnParticles = _globals![kNBodyParticles] as! Int
                mnTexRes = _globals![kNBodyTexRes] as! Int
                mnChannels = _globals![kNBodyChannels] as! Int
            }
        }
    }
    
    private func _acquire(device: MTLDevice?) -> Bool {
        guard let device = device else {
            NSLog(">> ERROR: Metal device is nil!")
            
            return false
        }
        guard let library = library else {
            NSLog(">> ERROR: Metal library is nil!")
            
            return false
        }
        
        function = library.newFunctionWithName(name ?? "NBodyLightingFragment")
        
        guard let _ = function else {
            NSLog(">> ERROR: Failed to instantiate fragment function!")
            
            return false
        }
        
        let mpSampler = MetalNBodySampler()
        self.mpSampler = mpSampler
        
        mpSampler.device = device
        
        guard mpSampler.haveSampler else {
            NSLog(">> ERROR: Failed to acquire a N-Body sampler resources!")
            
            return false
        }
        
        let mpGaussian = MetalGaussianMap()
        self.mpGaussian = mpGaussian
        
        mpGaussian.channels = MetalGaussianMap.CChannels(rawValue: mnChannels)!
        mpGaussian.texRes   = mnTexRes
        mpGaussian.device   = device
        
        guard mpGaussian.haveTexture else {
            NSLog(">> ERROR: Failed to acquire a N-Body Gaussian texture resources!")
            
            return false
        }
        
        return true
        
    }
    
    // Generate all the necessary fragment stage resources using a default system device
    private func acquire(device: MTLDevice?) {
        if !isStaged {
            isStaged = self._acquire(device)
        }
    }
    
    // Encode texture and sampler for the fragment stage
    func encode(cmdEncoder: MTLRenderCommandEncoder?) {
        cmdEncoder?.setFragmentTexture(mpGaussian?.texture, atIndex: 0)
        cmdEncoder?.setFragmentSamplerState(mpSampler?.sampler, atIndex: 0)
    }
    
}