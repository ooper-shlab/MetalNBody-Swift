//
//  MetalNBodyPresenter.swift
//  Metal N-Body
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/12/14.
//
//
/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 Utility class for rendering (encoding into Metal pipeline components of) N-Body simulation and presenting the frame
 */

import simd

import QuartzCore.CAMetalLayer
import Metal

@objc(MetalNBodyPresenter)
class MetalNBodyPresenter: NSObject {
    
    // Aspect ratio
    private var _aspect: Float = 0.0
    
    // Orthographic projection configuration type
    private var _config: NBody.Defaults.Configs = .Random
    
    // Update the linear transformation mvp matrix
    private var _update: Bool = false
    
    // N-body simulation global parameters
    private var _globals: [String: AnyObject]?
    
    // N-body parameters for simulation types
    private var _parameters: [String: AnyObject]?
    
    // Query to determine if all the resources are instantiated for render encoder object
    private(set) var haveEncoder: Bool = false
    
    // Query to determine if all stages are encoded
    private(set) var isEncoded: Bool = false
    
    // Generate all the resources (including fragment, vertex and compute stages)
    // for rendering N-Body simulation
    private var _device: MTLDevice?
    var device: MTLDevice? {
        get {return _device}
        set {acquire(newValue)}
    }
    
    // Encode vertex, fragment, and compute stages, then present the drawable
    private var _drawable: CAMetalDrawable?
    var drawable: CAMetalDrawable? {
        get {return _drawable}
        set {encode(newValue)}
    }
    
    private var m_Library: MTLLibrary?
    private var m_CmdBuffer: MTLCommandBuffer?
    private var m_CmdQueue: MTLCommandQueue?
    
    private var mpRender: MetalNBodyRenderStage?
    private var mpCompute: MetalNBodyComputeStage?
    
    override init() {
        
        haveEncoder = false
        isEncoded   = false
        
        _globals    = nil
        _parameters = nil
        
        m_CmdBuffer = nil
        m_CmdQueue  = nil
        m_Library   = nil
        
        mpRender  = nil
        mpCompute = nil
        
        super.init()
    }
    
    // N-body simulation global parameters
    var globals: [String: AnyObject]? {
        get {return _globals}
        set {
            _globals = newValue
            
            mpRender?.globals = _globals
        }
    }
    
    // N-body parameters for simulation types
    var parameters: [String: AnyObject]? {
        get {return _parameters}
        set {
            _parameters = newValue
            
            mpRender?.parameters = _parameters
        }
    }
    
    // Aspect ratio
    var aspect: Float {
        get {return _aspect}
        set {
            mpRender?.aspect = newValue
        }
    }
    
    // Orthographic projection configuration type
    var config: NBody.Defaults.Configs {
        get {return _config}
        set {
            mpRender?.config = newValue
        }
    }
    
    // Update the linear transformation mvp matrix
    var update: Bool {
        get {return _update}
        set {
            mpRender?.update = newValue
        }
    }
    
    // Host pointers
    
    // Color host pointer
    var colors: UnsafeMutablePointer<float4> {
        var pColors: UnsafeMutablePointer<float4> = nil
        
        if let mpRender = mpRender {
            pColors = mpRender.colors
        }
        
        return pColors
    }
    
    // Position host pointer
    var position: UnsafeMutablePointer<float4> {
        var pPosition: UnsafeMutablePointer<float4> = nil
        
        if let mpCompute = mpCompute {
            pPosition = mpCompute.position
        }
        
        return pPosition
    }
    
    // Velocity host pointer
    var velocity: UnsafeMutablePointer<float4> {
        var pVelocity: UnsafeMutablePointer<float4> = nil
        
        if let mpCompute = mpCompute {
            pVelocity = mpCompute.velocity
        }
        
        return pVelocity
    }
    
    private func _acquire(device: MTLDevice?) -> Bool {
        guard let device = device else {
            NSLog(">> ERROR: Metal device is nil!")
            
            return false
        }
        m_Library = device.newDefaultLibrary()
        
        guard m_Library != nil else {
            NSLog(">> ERROR: Failed to instantiate a new default m_Library!")
            
            return false
        }
        
        let m_CmdQueue = device.newCommandQueue()
        self.m_CmdQueue = m_CmdQueue
        
        let mpCompute = MetalNBodyComputeStage()
        self.mpCompute = mpCompute
        
        mpCompute.globals = _globals
        mpCompute.library = m_Library
        mpCompute.device  = device
        
        guard mpCompute.isStaged else {
            NSLog(">> ERROR: Failed to acquire a N-Body compute resources!")
            
            return false
        }
        
        let mpRender = MetalNBodyRenderStage()
        self.mpRender = mpRender
        
        mpRender.globals = _globals
        mpRender.library = m_Library
        mpRender.device  = device
        
        guard mpRender.isStaged else {
            NSLog(">> ERROR: Failed to acquire a N-Body render stage resources!")
            
            return false
        }
        
        return true
        
    }
    
    // Generate all the resources (including fragment, vertex and compute stages)
    // for rendering N-Body simulation
    private func acquire(device: MTLDevice?) {
        if !haveEncoder {
            haveEncoder = self._acquire(device)
        }
    }
    
    private func _encode(drawable: CAMetalDrawable?) -> Bool {
        m_CmdBuffer = m_CmdQueue?.commandBuffer()
        
        guard let m_CmdBuffer = m_CmdBuffer else {
            NSLog(">> ERROR: Failed to acquire a command buffer!")
            
            return false
        }
        
        mpCompute?.parameters = _parameters
        mpCompute?.cmdBuffer  = m_CmdBuffer
        
        mpRender?.positions = mpCompute?.buffer
        mpRender?.cmdBuffer = m_CmdBuffer
        mpRender?.drawable  = drawable
        
        m_CmdBuffer.presentDrawable(drawable!)
        m_CmdBuffer.commit()
        
        mpCompute?.swapBuffers()
        
        return true
    }
    
    // Encode vertex, fragment, and compute stages, then present the drawable
    private func encode(drawable: CAMetalDrawable?) {
        isEncoded = self._encode(drawable)
    }
    
    // Wait until the render encoding is complete
    func finish() {
        
        m_CmdBuffer?.waitUntilCompleted()
    }
    
}