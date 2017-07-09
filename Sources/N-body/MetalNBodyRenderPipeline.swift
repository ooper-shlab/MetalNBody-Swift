//
//  MetalNBodyRenderPipeline.swift
//  Metal N-Body
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/12/12.
//
//
/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 Utility class for creating a render state pipeline.
 */

import Metal

@objc(MetalNBodyRenderPipeline)
class MetalNBodyRenderPipeline: NSObject {
    
    // Query to determine if render pipeline state is instantiated
    private(set) var haveDescriptor: Bool = false
    
    // Vertex function
    var vertex: MTLFunction?
    
    // Fragment function
    var fragment: MTLFunction?
    
    // Generate render pipeline state using a default system
    // device, fragment and vertex stages
    var _device: MTLDevice?
    var device: MTLDevice? {
        get {return _device}
        set {acquire(newValue)}
    }
    
    // Render pipeline descriptor state
    private(set) var render: MTLRenderPipelineState?
    
    // Set blending
    var blend: Bool = false
    
    override init() {
        blend = false
        haveDescriptor = false
        
        fragment = nil
        vertex = nil
        render = nil
        
        super.init()
    }
    
    private func _acquire(_ device: MTLDevice?) -> Bool {
        guard let device = device else {
            NSLog(">> ERROR: Metal device is nil!")
            
            return false
        }
        guard let vertex = vertex else {
            NSLog(">> ERROR: Vertex stage object is nil!")
            
            return false
        }
        
        guard let fragment = fragment else {
            NSLog(">> ERROR: Fragment stage object is nil!")
            
            return false
        }
        
        let pDescriptor = MTLRenderPipelineDescriptor()
        
        pDescriptor.vertexFunction = vertex
        pDescriptor.fragmentFunction = fragment
        
        pDescriptor.colorAttachments[0].pixelFormat         = MTLPixelFormat.bgra8Unorm
        pDescriptor.colorAttachments[0].isBlendingEnabled     = true
        pDescriptor.colorAttachments[0].rgbBlendOperation   = MTLBlendOperation.add
        pDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperation.add
        
        if blend {
            pDescriptor.colorAttachments[0].sourceRGBBlendFactor        = MTLBlendFactor.one
            pDescriptor.colorAttachments[0].sourceAlphaBlendFactor      = MTLBlendFactor.one
            pDescriptor.colorAttachments[0].destinationRGBBlendFactor   = MTLBlendFactor.oneMinusSourceAlpha
            pDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactor.oneMinusSourceAlpha
        } else {
            pDescriptor.colorAttachments[0].sourceRGBBlendFactor        = MTLBlendFactor.sourceAlpha
            pDescriptor.colorAttachments[0].sourceAlphaBlendFactor      = MTLBlendFactor.sourceAlpha
            pDescriptor.colorAttachments[0].destinationRGBBlendFactor   = MTLBlendFactor.one
            pDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactor.one
        }
        
        do {
            
            render = try device.makeRenderPipelineState(descriptor: pDescriptor)
            
        } catch let pError {
            let pDescription = pError.localizedDescription
            
            NSLog(">> ERROR: Failed to instantiate render pipeline: {%@}", pDescription)
            
            return false
        }
        
        return true
        
    }
    
    // Generate render pipeline state using a default system
    // device, fragment and vertex stages
    func acquire(_ device: MTLDevice?) {
        if !haveDescriptor {
            haveDescriptor = self._acquire(device)
        }
    }
    
}
