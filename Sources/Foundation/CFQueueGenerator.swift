//
//  CFQueueGenerator.swift
//  Metal N-Body
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/12/13.
//
//
/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 A functor for creating dispatch queue with a unique identifier.
 */

import Foundation

@objc(CFQueueGenerator)
class CFQueueGenerator: NSObject {
    
    // Desired dispatch queue attribute.  Defaults to serial.
    // Desired dispatch queue attribute.
    var attribute: DispatchQueue.Attributes?
    
    // Dispatch queue identifier
    // Dispatch queue id.
    private var mnQID: UUID?
    
    // Dispatch queue label
    // Dispatch queue label.
    private var m_Label: String
    
    // Dispatch queue label plus an attched id.
    private var m_SQID: String
    
    override init() {
        
        // Initialize with an empty string
        m_SQID  = ""
        m_Label = ""
        
        // Default dispatch queue attribute is for a serial queue.
        attribute = DispatchQueue.Attributes()
        super.init()
        
    }
    
    var label: String {
        get {
            return m_Label
        }
        set {
            m_Label = newValue
        }
    }
    
    var identifier: String {
        return m_SQID
    }
    
    // A dispatch queue created with the set attribute.
    // Defaults to a serial dispatch queue.
    var queue: DispatchQueue? {
        mnQID = UUID()
        
        let sqid = mnQID!.uuidString
        
        if m_Label.isEmpty {
            m_SQID = sqid
        } else {
            m_SQID = "\(m_Label).\(sqid)"
        }
        
        return DispatchQueue(label: m_SQID, attributes: attribute!)
    }
    
}
