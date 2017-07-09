//
//  MetalNBodyRenderPassDescriptor.swift
//  Metal N-Body
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/12/12.
//
//
/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 Utility class for creating a render pass descriptor.
 */

import QuartzCore.CAMetalLayer
import Metal

@objc(MetalNBodyRenderPassDescriptor)
class MetalNBodyRenderPassDescriptor: NSObject {
    
    // Set a drawable to set render pass descriptors texture
    private var _drawable: CAMetalDrawable?
    
    // Get the render pass descriptor object
    private(set) var descriptor: MTLRenderPassDescriptor?
    
    // Query to determine if a texture was acquired from a drawable
    private(set) var haveTexture: Bool = false
    
    // Read the types for render pass descriptors load/store
    private(set) var load: MTLLoadAction
    private(set) var store: MTLStoreAction
    
    // Get or set the clear color for the render pass descriptor
    private var _color: MTLClearColor
    
    private func _newDescriptor() -> MTLRenderPassDescriptor? {
        let pDescriptor = MTLRenderPassDescriptor()
        
        pDescriptor.colorAttachments[0].loadAction  = load
        pDescriptor.colorAttachments[0].storeAction = store
        pDescriptor.colorAttachments[0].clearColor  = _color
        
        return pDescriptor
    }
    
    override init() {
        
        load        = MTLLoadAction.clear
        store       = MTLStoreAction.store
        _color       = MTLClearColorMake(0.0, 0.0, 0.0, 0.0)
        haveTexture = false
        super.init()
        descriptor = self._newDescriptor()
        
    }
    
    var color: MTLClearColor {
        get {
            return _color
        }
        set {
            _color = newValue
            
            if let descriptor = descriptor {
                descriptor.colorAttachments[0].clearColor = _color
            }
        }
    }
    
    var drawable: CAMetalDrawable? {
        get {
            return _drawable
        }
        set {
            haveTexture = false
            
            if let drawable = newValue, let descriptor = descriptor {
                let texture = drawable.texture
                
                descriptor.colorAttachments[0].texture = texture
                
                haveTexture = true
            }
        }
    }
    
}
