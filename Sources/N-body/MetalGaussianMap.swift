//
//  MetalGaussianMap.swift
//  Metal N-Body
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/12/13.
//
//
/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 Utility class for creating a 2d Gaussian texture.
 */

import Metal

import simd

@objc(MetalGaussianMap)
class MetalGaussianMap : NSObject {
    
    // Query to find if a texture was generated successfully
    private(set) var haveTexture: Bool = false
    
    // Generate a texture from samples generated by convolving the initial
    // data with a Gaussian white noise
    private var _device: MTLDevice?
    var device: MTLDevice? {
        get {return _device}
        set {acquire(newValue)}
    }
    
    // Gaussian texture
    private(set) var texture: MTLTexture?
    
    // Gaussian texture resolution
    private var _texRes: Int = 0
    
    // Number of color channels. Defaults to 4 for RGBA
    private var _channels: CChannels = .unknown
    
    // Gaussian texture width
    private(set) var width: Int = 0
    
    // Gaussian texture height
    private(set) var height: Int = 0
    
    // Gaussian texture bytes per row
    private(set) var rowBytes: Int = 0
    
    enum CChannels: Int {
        case unknown = 0
        case r
        case rg
        case rgb
        case rgba
    }
    
    private var m_Region: MTLRegion?
    
    private var m_DQueue: [DispatchQueue?] = Array(repeating: nil, count: 2)
    
    private var mpQGen: CFQueueGenerator?
    
    override init() {
        
        texture     = nil
        _texRes      = 64
        width       = _texRes
        height      = _texRes
        _channels    = .rgba
        super.init()
        rowBytes    = width * _channels.rawValue
        haveTexture = false
        
        m_DQueue[0] = nil
        m_DQueue[1] = nil
        
        mpQGen = nil
        
        m_Region = MTLRegionMake2D(0, 0, width, height)
        
    }
    
    var texRes: Int {
        get {return _texRes}
        set {
            _texRes = newValue != 0 ? newValue : 64
            width  = _texRes
            height = _texRes
            
            m_Region = MTLRegionMake2D(0, 0, width, height)
        }
    }
    
    var channels: CChannels {
        get {return _channels }
        set {
            _channels = (newValue != .unknown) ? newValue : .rgba
        }
    }
    
    private func _initImage(_ pImage: UnsafeMutablePointer<UInt8>) {
        let nDelta = 2.0 / Float(_texRes)
        
        var i = 0
        var j = 0
        
        var w = float2(-1.0, -1.0)
        
        DispatchQueue.concurrentPerform(iterations: _texRes) {y in
            w.y += nDelta
            
            DispatchQueue.concurrentPerform(iterations: self._texRes) {x in
                w.x += nDelta
                
                let d = length(w)
                var t: Float = 1.0
                
                t = CM.isLT(d, t) ? d : 1.0
                
                // Hermite interpolation where u = {1, 0} and v = {0, 0}
                let nColor = UInt8(255.0 * ((2.0 * t - 3.0) * t * t + 1.0))
                
                switch self._channels {
                case .rgba:
                    pImage[j+3] = nColor
                    fallthrough
                    
                case .rgb:
                    pImage[j+2] = nColor
                    fallthrough
                    
                case .rg:
                    pImage[j+1] = nColor
                    fallthrough
                    
                case .r:
                    fallthrough
                default:
                    pImage[j] = nColor
                }
                
                i += 2
                j += self._channels.rawValue
            }
            
            w.x = -1.0
        }
    }
    
    private func _newQueues() -> Bool {
        if mpQGen == nil {
            mpQGen = CFQueueGenerator()
        }
        
        if let mpQGen = mpQGen {
            if m_DQueue[0] == nil {
                mpQGen.label = "com.apple.metal.gaussianmap.ycoord"
                
                m_DQueue[0] = mpQGen.queue
            }
            
            if m_DQueue[1] == nil {
                mpQGen.label = "com.apple.metal.gaussianmap.xcoord"
                
                m_DQueue[1] = mpQGen.queue
            }
        }
        
        return m_DQueue[0] != nil && m_DQueue[1] != nil
    }
    
    // Generate the Gaussian image
    private func _newImage() -> UnsafeMutablePointer<UInt8>? {
        var pImage: UnsafeMutablePointer<UInt8>? = nil
        
        if self._newQueues() {
            pImage = UnsafeMutablePointer.allocate(capacity: _channels.rawValue * _texRes * _texRes)
            
            if pImage != nil {
                self._initImage(pImage!)
            } else {
                NSLog(">> ERROR: Failed allocating backing-store for a Gaussian image!")
            }
        }
        
        return pImage
    }
    
    // Generate a Gaussian texture
    private func _acquire(_ device: MTLDevice?) -> Bool {
        guard let device = device else {
            NSLog(">> ERROR: Metal device is nil!")
            
            return false
        }
        // Create a Metal texture descriptor
        let pDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm,
            width: width,
            height: height,
            mipmapped: false)
        
        // Create a Metal texture from a descriptor
        let texture = device.makeTexture(descriptor: pDesc)
        self.texture = texture
        
        // Generate a Gaussian image data
        let pImage = self._newImage()
        
        if pImage == nil {
            return false
        }
        
        rowBytes = width * _channels.rawValue
        
        // Upload the Gaussian image into the Metal texture
        texture!.replace(region: m_Region!, mipmapLevel: 0, withBytes: pImage!, bytesPerRow: rowBytes)
        
        pImage!.deallocate()
        
        return true
        
    }
    
    // Generate a texture from samples generated by convolving the initial
    // data with a Gaussian white noise
    private func acquire(_ device: MTLDevice?) {
        if !haveTexture {
            haveTexture = self._acquire(device)
        }
    }
    
}
