//
//  MetalNBodyVertexStage.swift
//  Metal N-Body
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/12/13.
//
//
/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 Utility class for creating and managing of N-body simulation vertex stage and resources.
 */

import simd

import Metal

@objc(MetalNBodyVertexStage)
class MetalNBodyVertexStage: NSObject {
    
    // Query to determine if all the resource were instantiated.
    private(set) var isStaged: Bool = false
    
    // Update the linear transformation mvp matrix
    private var _update: Bool = false
    
    // Number of point particles in the N-body simulation
    private var _particles: Int = 0
    
    // Orthographic projection configuration type
    private var _config: NBody.Defaults.Configs = .random
    
    // Aspect ratio
    private var _aspect: Float = 0.0
    
    // Point particle size
    private var _pointSz: Float = 0.0
    
    // Vertex function name
    var name: String?
    
    // Metal library to use for instantiating a vertex stage
    var library: MTLLibrary?
    
    // Buffer for point particle positions
    var positions: MTLBuffer?
    
    // Vertex stage function
    private(set) var function: MTLFunction?
    
    // Point particle colors
    private(set) var colors: UnsafeMutablePointer<float4>? = nil
    
    // Generate all the necessary vertex stage resources using a default system device
    private var _device: MTLDevice?
    var device: MTLDevice? {
        get {return _device}
        set {acquire(newValue)}
    }
    
    // Encode the buffers for the vertex stage
    private var _cmdEncoder: MTLRenderCommandEncoder?
    var cmdEncoder: MTLRenderCommandEncoder? {
        get {return _cmdEncoder}
        set {encode(newValue)}
    }
    
    private var m_Colors: MTLBuffer?
    private var m_PointSz: MTLBuffer?
    
    private var mnParticles: Int = 0
    
    private var mnPointSz: Float = 0.0
    private var mpPointSz: UnsafeMutablePointer<Float>? = nil
    
    private var mpTransform: MetalNBodyTransform?
    
    override init() {
        
        isStaged = false
        
        name      = nil
        function  = nil
        positions = nil
        
        colors = nil
        
        mnPointSz   = NBody.Defaults.kPointSz
        mnParticles = NBody.Defaults.kParticles
        
        m_Colors  = nil
        m_PointSz = nil
        
        mpTransform = nil
        mpPointSz = nil
        
        super.init()
    }
    
    // Number of point particles in the N-body simulation
    var particles: Int {
        get {return _particles}
        set {
            mnParticles = (newValue != 0) ? newValue : NBody.Defaults.kParticles
        }
    }
    
    // Point particle size
    var pointSz: Float {
        get {return _pointSz}
        set {
            if mpPointSz != nil {
                mpPointSz?.pointee = CM.isLT(newValue, mnPointSz) ? mnPointSz : newValue
            }
        }
    }
    
    // Aspect ratio
    var aspect: Float {
        get {return _aspect}
        set {
            mpTransform?.aspect = newValue
        }
    }
    
    // Orthographic projection configuration type
    var config: NBody.Defaults.Configs {
        get {return _config}
        set {
            mpTransform?.config = newValue
        }
    }
    //
    //// Update the linear transformation mvp matrix
    var update: Bool {
        get {return _update}
        set {
            mpTransform?.update = newValue
        }
    }
    
    private func _acquire(_ device: MTLDevice?) -> Bool {
        guard let device = device else {
            NSLog(">> ERROR: Metal device is nil!")
            
            return false
        }
        guard let library = library else {
            NSLog(">> ERROR: Metal library is nil!")
            
            return false
        }
        
        function = library.makeFunction(name: name ?? "NBodyLightingVertex")
        
        guard let _ = function else {
            NSLog(">> ERROR: Failed to instantiate vertex function!")
            
            return false
        }
        
        let m_Colors = device.makeBuffer(length: MemoryLayout<float4>.size*mnParticles, options: [])
        self.m_Colors = m_Colors
        
        colors = UnsafeMutableRawPointer(m_Colors.contents()).assumingMemoryBound(to: float4.self)
        
        guard colors != nil else {
            NSLog(">> ERROR: Failed to acquire a host pointer for m_Colors buffer!")
            
            return false
        }
        
        let m_PointSz = device.makeBuffer(length: MemoryLayout<Float>.size, options: [])
        self.m_PointSz = m_PointSz
        
        mpPointSz = UnsafeMutableRawPointer(m_PointSz.contents()).assumingMemoryBound(to: Float.self)
        
        guard mpPointSz != nil else {
            NSLog(">> ERROR: Failed to acquire a host pointer for buffer representing m_PointSz size!")
            
            return false
        }
        
        let mpTransform = MetalNBodyTransform()
        self.mpTransform = mpTransform
        
        mpTransform.device = device
        
        guard mpTransform.haveBuffer else {
            NSLog(">> ERROR: Failed to acquire a N-Body transform buffer resource!")
            
            return false
        }
        
        return true
        
    }
    
    // Generate all the necessary vertex stage resources using a default system device
    private func acquire(_ device: MTLDevice?) {
        if !isStaged {
            isStaged = self._acquire(device)
        }
    }
    
    // Encode the buffers for the vertex stage
    private func encode(_ cmdEncoder: MTLRenderCommandEncoder?) {
        if let positions = positions {
            cmdEncoder?.setVertexBuffer(positions, offset: 0, at: 0)
            cmdEncoder?.setVertexBuffer(m_Colors, offset: 0, at: 1)
            cmdEncoder?.setVertexBuffer(mpTransform?.buffer, offset: 0, at: 2)
            cmdEncoder?.setVertexBuffer(m_PointSz, offset: 0, at: 3)
        }
    }
    
}
