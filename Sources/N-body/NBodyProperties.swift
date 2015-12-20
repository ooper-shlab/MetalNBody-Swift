//
//  NBodyProperties.swift
//  Metal N-Body
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/12/13.
//
//
/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 Utility class for managing a set of defualt initial conditions for n-body simulation.
 */

import Foundation

@objc(NBodyProperties)
class NBodyProperties: NSObject {
    
    // Select the specific type of N-body simulation
    private var _config: Int = 0
    
    // Number of color channels.  Default is 4 for RGBA.
    private var _channels: Int = 0
    
    // Number of point particles
    private var _particles: Int = 0
    
    // Texture resolution.  The default is 64x64.
    private var _texRes: Int = 0
    
    // The number of N-body simulation types
    private(set) var count: Int = 0
    
    private var mpGlobals: [String: AnyObject]?
    private var mpParameters: [String: AnyObject]?
    
    private var mpProperties: [[String: AnyObject]]?
    
    func _newProperties(pFileName: String?) -> [String: AnyObject]? {
        var pProperties: [String: AnyObject]?
        
        guard let pFileName = pFileName else {
            NSLog(">> ERROR: File name is nil!")
            
            return nil
        }
        
        let pBundle = NSBundle.mainBundle()
        
        let pPathname = "\(pBundle.resourcePath!)/\(pFileName)"
        
        guard let pXML = NSData(contentsOfFile: pPathname) else {
            
            NSLog(">> ERROR: Failed instantiating a xml data from the contents of a file!")
            
            return nil
        }
        
        do {
            
            var format = NSPropertyListFormat.XMLFormat_v1_0
            
            pProperties = try NSPropertyListSerialization.propertyListWithData(pXML,
                options: .MutableContainers,
                format: &format) as? [String: AnyObject]
            
        } catch let pError as NSError {
            NSLog(">> ERROR: \"%@\"", pError.description)
            return nil
        }
        
        return pProperties
    }
    
    // Designated initializer for loading the property list file containing
    // global and simulation parameters
    init(file fileName: String?) {
        super.init()
        
        guard let pProperties = self._newProperties(fileName) else {return}
        
        mpGlobals = pProperties[kNBodyGlobals] as! [String: AnyObject]?
        
        if let globals = mpGlobals {
            _particles = globals[kNBodyParticles] as! Int
            _texRes = globals[kNBodyTexRes] as! Int
            _channels = globals[kNBodyChannels] as! Int
        }
        
        mpProperties = pProperties[kNBodyParameters] as! [[String: AnyObject]]?
        
        if let properties = mpProperties {
            count = properties.count
            _config = count
        }
        
        mpParameters = nil
        
    }
    
    convenience override init() {
        self.init(file: "NBodyAppPrefs.plist")
    }
    
    // N-body simulation global parameters
    var globals: [String: AnyObject]? {
        return mpGlobals
    }
    
    // N-body parameters for simulation types
    var parameters: [String: AnyObject]? {
        return mpParameters
    }
    
    // Select the specific type of N-body simulation
    var config: Int {
        get {return _config}
        set {
            if newValue != _config {
                _config = newValue
                
                mpParameters = mpProperties?[_config]
            }
        }
    }
    
    // Number of point particles
    var particles: Int {
        get {return _particles}
        set {
            let ptparticles = (newValue > 1024) ? newValue : NBody.Defaults.kParticles
            
            if ptparticles != _particles {
                _particles = ptparticles
                
                mpGlobals?[kNBodyParticles] = _particles
            }
        }
    }
    
    // Number of color channels.  Default is 4 for RGBA.
    var channels: Int {
        get {return _channels}
        set {
            let nChannels = (newValue != 0) ? newValue : NBody.Defaults.kChannels
            
            if nChannels != _channels {
                _channels = nChannels
                
                mpGlobals?[kNBodyChannels] = _channels
            }
        }
    }
    
    // Texture resolution.  The default is 64x64.
    var texRes: Int {
        get {return _texRes}
        set {
            let nTexRes = (newValue != 0) ? newValue : NBody.Defaults.kTexRes
            
            if nTexRes != _texRes {
                _texRes = nTexRes
                
                mpGlobals?[kNBodyTexRes] = _texRes
            }
        }
    }
    
}