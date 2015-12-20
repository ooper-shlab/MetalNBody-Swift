//
//  MetalNBodyRenderStage.swift
//  Metal N-Body
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/12/14.
//
//
/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 Utility class for instantiating and encoding of vertex and fragment stages.
 */

import simd

import QuartzCore.CAMetalLayer
import Metal

@objc(MetalNBodyRenderStage)
class MetalNBodyRenderStage: NSObject {
    
    // Default library for creating vertexa nd fragment stages
    var library: MTLLibrary?
    
    // Command buffer for render command encoder
    var cmdBuffer: MTLCommandBuffer?
    
    // Buffer for point particle positions
    var positions: MTLBuffer?
    
    // Orthographic projection configuration type
    private var _config: NBody.Defaults.Configs = .Random
    
    // N-body simulation global parameters
    private var _globals: [String: AnyObject]?
    
    // N-body parameters for simulation types
    private var _parameters: [String: AnyObject]?
    
    // Query to determine if all the resources are instantiated for the render stage object
    private(set) var isStaged: Bool = false
    
    // Query to determine if all stages are encoded
    private(set) var isEncoded: Bool = false
    
    // Aspect ratio
    //@property (nonatomic) float aspect;
    private var _aspect: Float = 0.0
    
    // Update the linear transformation mvp matrix
    private var _update: Bool = false
    
    // Generate all the fragment, vertex and stages
    private var _device: MTLDevice?
    var device: MTLDevice? {
        get {return _device}
        set {acquire(newValue)}
    }
    
    // Encode vertex and fragment stages
    private var _drawable: CAMetalDrawable?
    var drawable: CAMetalDrawable? {
        get {return _drawable}
        set {encode(newValue)}
    }
    
    private var mnParticles: Int = 0
    
    private var mpFragment: MetalNBodyFragmentStage?
    private var mpVertex: MetalNBodyVertexStage?
    private var mpDescriptor: MetalNBodyRenderPassDescriptor?
    private var mpPipeline: MetalNBodyRenderPipeline?
    
    override init() {
        
        isStaged  = false
        isEncoded = false
        
        _globals    = nil
        _parameters = nil
        library    = nil
        cmdBuffer  = nil
        positions  = nil
        
        mnParticles = NBody.Defaults.kParticles
        
        mpDescriptor = nil
        mpPipeline   = nil
        mpFragment   = nil
        mpVertex     = nil
        
        super.init()
    }
    
    // N-body simulation global parameters
    var globals: [String: AnyObject]? {
        get {return _globals}
        set {
            if let globals = newValue where !isStaged {
                _globals = globals
                
                mnParticles = globals[kNBodyParticles] as! Int
                
                mpFragment?.globals = globals
            }
        }
    }
    
    // N-body parameters for simulation types
    var parameters: [String: AnyObject]? {
        get {return _parameters}
        set {
            if let parameters = newValue {
                _parameters = parameters
                
                mpVertex?.pointSz = parameters[kNBodyPointSize] as! Float
            }
        }
    }
    
    // Aspect ratio
    var aspect: Float {
        get {return _aspect}
        set {
            mpVertex?.aspect = newValue
        }
    }
    
    // Orthographic projection configuration type
    var config: NBody.Defaults.Configs {
        get {return _config}
        set {
            mpVertex?.config = newValue
        }
    }
    
    // Update the linear transformation mvp matrix
    var update: Bool {
        get {return _update}
        set {
            mpVertex?.update = newValue
        }
    }
    
    // Color host pointer
    var colors: UnsafeMutablePointer<float4> {
        var pColors: UnsafeMutablePointer<float4> = nil
        
        if let mpVertex = mpVertex {
            pColors = mpVertex.colors
        }
        
        return pColors
    }
    
    private func _acquire(device: MTLDevice?) -> Bool {
        guard let device = device else {
            NSLog(">> ERROR: Metal device is nil!")
            
            return false
        }
        guard let library = library else {
            NSLog(">> ERROR: Failed to instantiate a new default m_Library!")
            
            return false
        }
        
        let mpVertex = MetalNBodyVertexStage()
        self.mpVertex = mpVertex
        
        mpVertex.particles = mnParticles
        mpVertex.library   = library
        mpVertex.device    = device
        
        guard mpVertex.isStaged else {
            NSLog(">> ERROR: Failed to acquire a N-Body vertex stage resources!")
            
            return false
        }
        
        let mpFragment = MetalNBodyFragmentStage()
        self.mpFragment = mpFragment
        
        mpFragment.globals = _globals
        mpFragment.library = library
        mpFragment.device  = device
        
        guard mpFragment.isStaged else {
            NSLog(">> ERROR: Failed to acquire a N-Body fragment stage resources!")
            
            return false
        }
        
        let mpPipeline = MetalNBodyRenderPipeline()
        self.mpPipeline = mpPipeline
        
        mpPipeline.fragment = mpFragment.function
        mpPipeline.vertex   = mpVertex.function
        mpPipeline.device   = device
        
        guard mpPipeline.haveDescriptor else {
            NSLog(">> ERROR: Failed to acquire a N-Body render pipeline resources!")
            
            return false
        }
        
        let mpDescriptor = MetalNBodyRenderPassDescriptor()
        self.mpDescriptor = mpDescriptor
        
        return true
        
    }
    
    // Generate all the fragment, vertex and stages
    private func acquire(device: MTLDevice?) {
        if !isStaged {
            isStaged = self._acquire(device)
        }
    }
    
    private func _encode(drawable: CAMetalDrawable?) -> Bool {
        guard let cmdBuffer = cmdBuffer else {
            NSLog(">> ERROR: Command buffer is nil!")
            
            return false
        }
        
        guard let drawable = drawable else {
            NSLog(">> ERROR: Drawable is nil!")
            
            return false
        }
        
        mpDescriptor?.drawable = drawable
        
        guard mpDescriptor?.haveTexture ?? false else {
            NSLog(">> ERROR: Failed to acquire a texture from a CA drawable!")
            
            return false
        }
        
        let renderEncoder = cmdBuffer.renderCommandEncoderWithDescriptor(mpDescriptor!.descriptor!)
        
        renderEncoder.setRenderPipelineState(mpPipeline!.render!)
        
        mpVertex?.positions  = positions
        mpVertex?.cmdEncoder = renderEncoder
        
        mpFragment?.cmdEncoder = renderEncoder
        
        renderEncoder.drawPrimitives(.Point,
            vertexStart: 0,
            vertexCount: mnParticles,
            instanceCount: 1)
        
        renderEncoder.endEncoding()
        
        return true
    }
    
    // Encode vertex and fragment stages
    private func encode(drawable: CAMetalDrawable?) {
        isEncoded = self._encode(drawable)
    }
    
}