//
//  MetalNBodyTransform.swift
//  Metal N-Body
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/12/13.
//
//
/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 Utility class for managing N-body linear transformation matrix and buffer.
 */

import simd
import Metal

private let kOrth2DBounds: [float3] = [
    float3(50.0, 50.0, 50.0),
    float3(50.0, 50.0, 50.0),
    float3(1.0,  1.0,  50.0),
    float3(5.0,  5.0,  50.0),
    float3(5.0,  5.0,  50.0),
    float3(50.0, 50.0, 50.0)
]

@objc(MetalNBodyTransform)
class MetalNBodyTransform: NSObject {
    
    // Query to determine if a Metal buffer was generated successfully
    private(set) var haveBuffer: Bool = false
    
    // Generate a Metal buffer and linear tranformations using a default system device
    private var _device: MTLDevice?
    var device: MTLDevice? {
        get {return _device}
        set {acquire(newValue)}
    }
    
    // Metal buffer for linear transformation matrix
    private(set) var buffer: MTLBuffer?
    
    // Linear transformation matrix
    private(set) var transform: matrix_float4x4 = matrix_float4x4()
    
    // Metal buffer size
    private(set) var size: Int = 0
    
    // Update the mvp linear transformation matrix
    private var _update: Bool = false
    
    // Set the aspect ratio for the orthographic 2d projection
    private var _aspect: Float = 0.0
    
    // Orthographic projection configuration type
    private var _config: NBody.Defaults.Configs = .random
    
    // Orthographic 2d bounds
    var bounds: float3 = float3()
    
    // (x,y,z) centers
    var center: Float = 0.0
    var zCenter: Float = 0.0
    
    private var mpTransform: UnsafeMutablePointer<matrix_float4x4>? = nil
    
    private var m_View: matrix_float4x4 = matrix_float4x4()
    private var m_Projection: matrix_float4x4 = matrix_float4x4()
    private var m_Ortho2D: matrix_float4x4 = matrix_float4x4()
    
    override init() {
        
        haveBuffer = false
        _update     = false
        _device     = nil
        buffer     = nil
        size       = MemoryLayout<matrix_float4x4>.size
        _config     = NBody.Defaults.Configs.random
        _aspect     = NBody.Defaults.kAspectRatio
        center     = NBody.Defaults.kCenter
        zCenter    = NBody.Defaults.kZCenter
        bounds = kOrth2DBounds[_config.rawValue]
        transform  = matrix_float4x4()
        
        let rotate1   = CM.rotate(0, 0.0, 1.0, 0.0)
        let rotate2   = CM.rotate(0, 1.0, 1.0, 1.0)
        let translate = CM.translate(0, 0, 1000)
        
        m_View = translate * rotate1 * rotate2
        
        m_Ortho2D = matrix_float4x4()
        m_Projection = matrix_float4x4()
        
        mpTransform = nil
        
        super.init()
    }
    
    private func _resize() {
        // We scale up from the OpenCL version since the dimensions are approximately
        // twice as big on the iPad as on the default view.  Also, we don't use the
        // y bound, in order to keep the aspect ratio.
        
        let aspect =  center/_aspect
        let left   =  bounds.x * center
        let right  = -bounds.x * center
        let bottom =  bounds.x * aspect
        let top    = -bounds.x * aspect
        let near   =  bounds.z * zCenter
        let far    = -bounds.z * zCenter
        
        m_Projection = CM.ortho2d(left, right, bottom, top, near, far)
    }
    
    // Update the mvp linear transformation matrix
    var update: Bool {
        get {return _update}
        set {
            if newValue {
                transform = m_Projection * m_View
                mpTransform?.pointee = transform
                
                _update = newValue
            }
        }
    }
    
    private func _acquire(_ device: MTLDevice?) -> Bool {
        guard let device = device else {
            NSLog(">> ERROR: Metal device is nil!")
            
            return false
        }
        // Generate a Metal buffer for linear transformation matrix
        let buffer = device.makeBuffer(length: size, options: [])
        self.buffer = buffer
        
        // Liner transformation mvp matrix
        mpTransform = UnsafeMutableRawPointer(buffer!.contents()).assumingMemoryBound(to: matrix_float4x4.self)
        
        guard mpTransform != nil else {
            NSLog(">> ERROR: Failed to acquire a host pointer to the transformation matrix buffer!")
            
            return false
        }
        
        return true
        
    }
    
    // Generate a Metal buffer and linear tranformations
    private func acquire(_ device: MTLDevice?) {
        if !haveBuffer {
            haveBuffer = self._acquire(device)
        }
    }
    
    // Set the aspect ratio for the orthographic 2d projection
    var aspect: Float {
        get {return _aspect}
        set {
            if !CM.isEQ(newValue, _aspect) {
                _aspect = newValue
                
                self._resize()
                
                self.update = true
            }
        }
    }
    
    // Orthographic projection configuration type
    var config: NBody.Defaults.Configs {
        get {return _config}
        set {
            if newValue != _config {
                _config = newValue
                bounds = kOrth2DBounds[_config.rawValue]
            }
        }
    }
    
}
