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
    
    private func _acquire(device: MTLDevice?) -> Bool {
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
        
        pDescriptor.colorAttachments[0].pixelFormat         = MTLPixelFormat.BGRA8Unorm
        pDescriptor.colorAttachments[0].blendingEnabled     = true
        pDescriptor.colorAttachments[0].rgbBlendOperation   = MTLBlendOperation.Add
        pDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperation.Add
        
        if blend {
            pDescriptor.colorAttachments[0].sourceRGBBlendFactor        = MTLBlendFactor.One
            pDescriptor.colorAttachments[0].sourceAlphaBlendFactor      = MTLBlendFactor.One
            pDescriptor.colorAttachments[0].destinationRGBBlendFactor   = MTLBlendFactor.OneMinusSourceAlpha
            pDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactor.OneMinusSourceAlpha
        } else {
            pDescriptor.colorAttachments[0].sourceRGBBlendFactor        = MTLBlendFactor.SourceAlpha
            pDescriptor.colorAttachments[0].sourceAlphaBlendFactor      = MTLBlendFactor.SourceAlpha
            pDescriptor.colorAttachments[0].destinationRGBBlendFactor   = MTLBlendFactor.One
            pDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactor.One
        }
        
        do {
            
            render = try device.newRenderPipelineStateWithDescriptor(pDescriptor)
            
        } catch let pError as NSError {
            let pDescription = pError.description
            
            NSLog(">> ERROR: Failed to instantiate render pipeline: {%@}", pDescription)
            
            return false
        }
        
        return true
        
    }
    
    // Generate render pipeline state using a default system
    // device, fragment and vertex stages
    func acquire(device: MTLDevice?) {
        if !haveDescriptor {
            haveDescriptor = self._acquire(device)
        }
    }
    
}