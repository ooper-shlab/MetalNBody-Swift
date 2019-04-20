//
//  MetalNBodyComputeStage.swift
//  Metal N-Body
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/12/14.
//
//
/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 Utility class for managing the N-body compute resources.
 */

import simd
import Metal

private let kNBodyFloat4Size = MemoryLayout<float4>.size

@objc(MetalNBodyComputeStage)
class MetalNBodyComputeStage: NSObject {
    
    // Query to determine if all the resource were instantiated.
    private(set) var isStaged: Bool = false
    
    // Compute kernel's function name
    var name: String?
    
    // Metal library to use for instantiating a compute stage
    var library: MTLLibrary?
    
    // N-body simulation global parameters
    private var _globals: [String: Any]?
    
    // N-body parameters for simulation types
    private var _parameters: [String: Any]?
    
    // Thread execution width multiplier
    private var _multiplier: Int = 1
    
    // Generate all the necessary compute stage resources using a default system device
    private var _device: MTLDevice?
    var device: MTLDevice? {
        get {return _device}
        set {acquire(newValue)}
    }
    
    // Setup compute pipeline state and encode
    private var _cmdBuffer: MTLCommandBuffer?
    var cmdBuffer: MTLCommandBuffer? {
        get {return _cmdBuffer}
        set {encode(newValue)}
    }
    
    private var m_Function: MTLFunction?
    private var m_Kernel: MTLComputePipelineState?
    private var m_Position: [MTLBuffer?] = [nil, nil]
    private var m_Velocity: [MTLBuffer?] = [nil, nil]
    private var m_Params: MTLBuffer?
    
    private var mnStride: Int = kNBodyFloat4Size
    private var mnRead: Int = 0
    private var mnWrite: Int = 1
    
    private var mnSize: [Int] = [0, 0, 0]
    private var mnThreadDimX: Int = 0
    
    private var mpHostPos: [UnsafeMutablePointer<float4>?] = [nil, nil]
    private var mpHostVel: [UnsafeMutablePointer<float4>?] = [nil, nil]
    
    private var m_HostPrefs: NBody.Compute.Prefs = NBody.Compute.Prefs(
        timestep: NBody.Defaults.kTimestep,
        damping: NBody.Defaults.kDamping,
        softeningSqr: NBody.Defaults.kSofteningSqr,
        particles: UInt32(NBody.Defaults.kParticles))
    private var mpHostPrefs: UnsafeMutablePointer<NBody.Compute.Prefs>? = nil
    
    private var m_WGSize: MTLSize = MTLSize()
    private var m_WGCount: MTLSize = MTLSize()
    
    override init() {
        
        name       = nil
        _globals    = nil
        _parameters = nil
        
        isStaged = false
        _multiplier  = 1
        
        m_Function = nil
        m_Kernel   = nil
        m_Params   = nil
        
        m_Position[0] = nil
        m_Position[1] = nil
        
        m_Velocity[0] = nil
        m_Velocity[1] = nil
        
        m_HostPrefs.particles    = UInt32(NBody.Defaults.kParticles)
        m_HostPrefs.timestep     = NBody.Defaults.kTimestep
        m_HostPrefs.damping      = NBody.Defaults.kDamping
        m_HostPrefs.softeningSqr = NBody.Defaults.kSofteningSqr
        
        mnSize[0] = mnStride * Int(m_HostPrefs.particles)
        mnSize[1] = MemoryLayout<NBody.Compute.Prefs>.stride
        mnSize[2] = 0
        
        mnStride = kNBodyFloat4Size
        mnRead   = 0
        mnWrite  = 1
        
        mpHostPos[0] = nil
        mpHostPos[1] = nil
        
        mpHostVel[0] = nil
        mpHostVel[1] = nil
        
        mpHostPrefs = nil
        
        super.init()
    }
    
    // Position buffer
    var buffer: MTLBuffer? {
        return m_Position[mnRead]
    }
    
    // Host pointers
    
    // Position host pointer
    var position: UnsafeMutablePointer<float4>? {
        return mpHostPos[mnRead]
    }
    
    // Velocity host pointer
    var velocity: UnsafeMutablePointer<float4>? {
        return mpHostVel[mnRead]
    }
    
    var multiplier: Int {
        get {return _multiplier}
        set {
            if !isStaged {
                _multiplier = (newValue != 0) ? newValue : 1
            }
        }
    }
    
    // N-body simulation global parameters
    var globals: [String: Any]? {
        get {return _globals}
        set {
            if let globals = newValue, !isStaged {
                _globals = globals
                
                m_HostPrefs.particles = UInt32(globals[kNBodyParticles] as! Int)
                
                mnSize[0] = mnStride * Int(m_HostPrefs.particles)
            }
        }
    }
    
    // N-body parameters for simulation types
    var parameters: [String: Any]? {
        get {return _parameters}
        set {
            if let parameters = newValue {
                _parameters = parameters
                
                let nSoftening = (parameters[kNBodySoftening] as! NSNumber).floatValue
                
                m_HostPrefs.timestep     = (parameters[kNBodyTimestep] as! NSNumber).floatValue
                m_HostPrefs.damping      = (parameters[kNBodyDamping] as! NSNumber).floatValue
                m_HostPrefs.softeningSqr = nSoftening * nSoftening
                
                if mpHostPrefs != nil {mpHostPrefs?.pointee = m_HostPrefs}
            }
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
        
        m_Function = library.makeFunction(name: name ?? "NBodyIntegrateSystem")
        
        guard let m_Function = m_Function else {
            NSLog(">> ERROR: Failed to instantiate function!")
            
            return false
        }
        
        do {
            
            m_Kernel = try device.makeComputePipelineState(function: m_Function)
            
        } catch let pError {
            let pDescription = pError.localizedDescription
            
            NSLog(">> ERROR: Failed to instantiate kernel: {%@}!", pDescription)
            
            return false
        }
        
        mnThreadDimX = _multiplier * m_Kernel!.threadExecutionWidth
        
        guard (Int(m_HostPrefs.particles) % mnThreadDimX) == 0 else {
            NSLog(">> ERROR: The number of bodies needs to be a multiple of the workgroup size!")
            
            return false
        }
        
        mnSize[2] = kNBodyFloat4Size * mnThreadDimX
        
        m_WGCount = MTLSizeMake(Int(m_HostPrefs.particles)/mnThreadDimX, 1, 1)
        m_WGSize  = MTLSizeMake(mnThreadDimX, 1, 1)
        
        m_Position[mnRead] = device.makeBuffer(length: mnSize[0], options: [])
        
        mpHostPos[mnRead] = UnsafeMutableRawPointer(m_Position[mnRead]!.contents()).assumingMemoryBound(to: float4.self)
        
        guard mpHostPos[mnRead] != nil else {
            NSLog(">> ERROR: Failed to get the base address to position buffer 1!")
            
            return false
        }
        
        m_Position[mnWrite] = device.makeBuffer(length: mnSize[0], options: [])
        
        mpHostPos[mnWrite] = UnsafeMutableRawPointer(m_Position[mnWrite]!.contents()).assumingMemoryBound(to: float4.self)
        
        guard mpHostPos[mnWrite] != nil else {
            NSLog(">> ERROR: Failed to get the base address to position buffer 2!")
            
            return false
        }
        
        m_Velocity[mnRead] = device.makeBuffer(length: mnSize[0], options: [])
        
        mpHostVel[mnRead] = UnsafeMutableRawPointer(m_Velocity[mnRead]!.contents()).assumingMemoryBound(to: float4.self)
        
        guard mpHostVel[mnRead] != nil else {
            NSLog(">> ERROR: Failed to get the base address to velocity buffer 1!")
            
            return false
        }
        
        m_Velocity[mnWrite] = device.makeBuffer(length: mnSize[0], options: [])
        
        mpHostVel[mnWrite] = UnsafeMutableRawPointer(m_Velocity[mnWrite]!.contents()).assumingMemoryBound(to: float4.self)
        
        guard mpHostVel[mnWrite] != nil else {
            NSLog(">> ERROR: Failed to get the base address to velocity buffer 2!")
            
            return false
        }
        
        m_Params = device.makeBuffer(length: mnSize[1], options: [])
        
        mpHostPrefs = UnsafeMutableRawPointer(m_Params!.contents()).assumingMemoryBound(to: NBody.Compute.Prefs.self)
        
        guard mpHostPrefs != nil else {
            NSLog(">> ERROR: Failed to get the base address to compute kernel parameter buffer!")
            
            return false
        }
        
        return true
        
    }
    
    // Generate all the necessary compute stage resources using a default system device
    private func acquire(_ device: MTLDevice?) {
        if !isStaged {
            isStaged = self._acquire(device)
        }
    }
    
    // Setup compute pipeline state and encode
    private func encode(_ cmdBuffer: MTLCommandBuffer?) {
        guard let cmdBuffer = cmdBuffer else {return}
        let encoder = cmdBuffer.makeComputeCommandEncoder()!
        
        encoder.setComputePipelineState(m_Kernel!)
        
        encoder.setBuffer(m_Position[mnWrite], offset: 0, index: 0)
        encoder.setBuffer(m_Velocity[mnWrite], offset: 0, index: 1)
        encoder.setBuffer(m_Position[mnRead], offset: 0, index: 2)
        encoder.setBuffer(m_Velocity[mnRead], offset: 0, index: 3)
        
        encoder.setBuffer(m_Params, offset: 0, index: 4)
        
        encoder.setThreadgroupMemoryLength(mnSize[2], index: 0)
        
        encoder.dispatchThreadgroups(m_WGCount, threadsPerThreadgroup: m_WGSize)
        
        encoder.endEncoding()
    }
    
    // Swap the read/write buffers
    func swapBuffers() {
        CM.swap(&mnRead, &mnWrite)
    }
    
}
