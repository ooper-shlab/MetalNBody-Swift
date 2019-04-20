//
//  AppViewController.swift
//  Metal N-Body
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/12/14.
//
//
/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 Application view controller implementing Metal Kit delgates.
 */

import MetalKit

@objc(AppViewController)
class AppViewController: UIViewController, MTKViewDelegate {
    
    // Default Metal system devive
    private var device: MTLDevice?
    
    // Metal-Kit view
    private var mpView: MTKView!
    
    // N-body simulation visualizer object
    private var mpVisualizer: NBodyVisualizer?
    
    private func _update(_ view: MTKView) {
        let bounds = view.bounds
        let aspect = Float(abs(bounds.size.width / bounds.size.height))
        
        // Set the new aspect ratio for the mvp linear transformation matrix
        mpVisualizer?.aspect = aspect
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Update the mvp linear transformation matrix
        self._update(view)
    }

    func draw(in view: MTKView) {
        autoreleasepool{
            self._update(view)
            
            // Draw the particles from the N-body simulation
            self.mpVisualizer?.drawable = view.currentDrawable
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Instantiate a new N-body visualizer object
        let mpVisualizer = NBodyVisualizer()
        self.mpVisualizer = mpVisualizer
        
        // Acquire all the resources for the visualizer object
        mpVisualizer.device = device
        
        // If successful in acquiring resources for the visualizer
        // object, then continue
        assert(mpVisualizer.haveVisualizer)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Acquire a default Metal system device
        device = MTLCreateSystemDefaultDevice()
        
        // If this is a valid system device, then continue
        assert(device != nil)
        
        // Our view should be a Metal-Kit view
        mpView = self.view as? MTKView
        
        // If this a valid Metal-kit view, then continue
        assert(mpView != nil)
        
        // Metal-kit view requires a Metal device and an app delegate
        mpView.device   = device
        mpView.delegate = self
    }
    
}
