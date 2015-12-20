//
//  MetalNBodySampler.swift
//  Metal N-Body
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/12/13.
//
//
/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 Utility class for creating a sampler.
 */

import Metal

@objc(MetalNBodySampler)
class MetalNBodySampler: NSObject {

// Generate a Metal sampler state using a default system device
    private var _device: MTLDevice?
    var device: MTLDevice? {
        get {return _device}
        set {acquire(newValue)}
    }

// Sample state object for N-body simulation
    private(set) var sampler: MTLSamplerState?

// Query to find if the sampler state object was generated
    private(set) var haveSampler: Bool = false

    override init() {

        haveSampler = false
        sampler     = nil

        super.init()
    }

    private func _acquire(device: MTLDevice?) -> Bool {
        guard let device = device else {
            NSLog(">> ERROR: Metal device is nil!")
            
            return false
        }
        let pDescriptor = MTLSamplerDescriptor()

        pDescriptor.minFilter             = MTLSamplerMinMagFilter.Linear
        pDescriptor.magFilter             = MTLSamplerMinMagFilter.Linear
        pDescriptor.sAddressMode          = MTLSamplerAddressMode.Repeat
        pDescriptor.tAddressMode          = MTLSamplerAddressMode.Repeat
        pDescriptor.mipFilter             = MTLSamplerMipFilter.NotMipmapped
        pDescriptor.maxAnisotropy         = 1
        pDescriptor.normalizedCoordinates = true
        pDescriptor.lodMinClamp           = 0.0
        pDescriptor.lodMaxClamp           = 255.0

        sampler = device.newSamplerStateWithDescriptor(pDescriptor)

        if sampler == nil {
            NSLog(">> ERROR: Failed to instantiate sampler state with descriptor!")

            return false
        }

        return true

    }

    private func acquire(device: MTLDevice?) {
            if !haveSampler {
                haveSampler = self._acquire(device)
            }
        }

}