//
//  NBodyURDGenerator.swift
//  Metal N-Body
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/12/13.
//
//
/*
 <codex>
 <abstract>
 Base class for generating random packed or split data sets for the gpu bound simulator using unifrom real distribution.
 </abstract>
 </codex>
 */

import simd

import Foundation

func +(lhs: Float, rhs: float3) -> float3 {
    return float3(lhs+rhs.x, lhs+rhs.y, lhs+rhs.z)
}

@objc(NBodyURDGenerator)
class NBodyURDGenerator: NSObject {
    
    // Generate a inital simulation data
    private var _config: NBody.Defaults.Configs = .count
    var config: NBody.Defaults.Configs {
        get {return _config}
        set {acquire(newValue)}
    }
    
    // N-body simulation global parameters
    private var _globals: [String: Any]?
    
    // N-body parameters for simulation types
    private var _parameters: [String: Any]?
    
    // Coordinate points on the Eunclidean axis of simulation
    private var _axis: float3 = float3()
    
    // Position and velocity pointers
    var position: UnsafeMutablePointer<float4>? = nil
    var velocity: UnsafeMutablePointer<float4>? = nil
    
    // Colors pointer
    private var _colors: UnsafeMutablePointer<float4>? = nil
    
    private let kScale: Float = 1.0/1024.0
    
    struct NBodyScales {
        var mnCluster: Float = 0.0
        var mnVelocity: Float = 0.0
        var mnParticles: Float = 0.0
    }
    
    var isComplete: Bool = false
    
    var mnParticles: Int = 0
    
    var m_Scales: NBodyScales = NBodyScales()
    
    var m_DQueue: DispatchQueue?
    
    var mpGenerator: [CM.URD3.Generator]
    
    override init() {
        
        mpGenerator = [
            CM.URD3.Generator(),
            CM.URD3.Generator(min: -1.0, max: 1.0, len: 1.0)
        ]
        
        _globals    = nil
        _parameters = nil
        
        _config = .count
        
        _axis = float3(0.0, 0.0, 1.0)
        
        position = nil
        velocity = nil
        _colors = nil
        
        m_DQueue = nil
        
        mnParticles = Int(NBody.Defaults.kParticles)
        super.init()
        
        m_Scales.mnCluster = NBody.Defaults.Scale.kCluster
        m_Scales.mnVelocity = NBody.Defaults.Scale.kVelocity
        m_Scales.mnParticles = kScale * Float(mnParticles)
        
        isComplete = true
        
    }
    
    // Coordinate points on the Eunclidean axis of simulation
    var axis: float3 {
        get {return _axis}
        set {
            _axis = normalize(newValue)
        }
    }
    
    // Colors pointer
    var colors: UnsafeMutablePointer<float4>? {
        get {return _colors!}
        set {
            if newValue != nil {
                _colors = newValue
                
                DispatchQueue.concurrentPerform(iterations: mnParticles) {i in
                    let c = self.mpGenerator[0].rand()
                    self._colors?[i] = float4(c.x, c.y, c.z, 1.0)
                }
            }
        }
    }
    
    // N-body simulation global parameters
    var globals: [String: Any]? {
        get {return _globals}
        set {
            if newValue != nil {
                _globals = newValue
                
                mnParticles = _globals![kNBodyParticles] as! Int
                
                m_Scales.mnParticles = kScale * Float(mnParticles)
            }
        }
    }
    
    // N-body parameters for simulation types
    var parameters: [String: Any]? {
        get {return _parameters}
        set {
            if newValue != nil {
                _parameters = newValue
                
                m_Scales.mnCluster = _parameters![kNBodyClusterScale] as! Float
                m_Scales.mnVelocity = _parameters![kNBodyVelocityScale] as! Float
            }
        }
    }
    
    private func _configRandom() {
        let pscale = m_Scales.mnCluster  * max(1.0, m_Scales.mnParticles)
        let vscale = m_Scales.mnVelocity * pscale
        
        DispatchQueue.concurrentPerform(iterations: mnParticles) {i in
            let point = self.mpGenerator[1].nrand()
            let velocity = self.mpGenerator[1].nrand()
            
            self.position?[i] = float4(pscale * point.x, pscale * point.y, pscale * point.z, 1.0)
            
            self.velocity?[i] = float4(vscale * velocity.x, vscale * velocity.y, vscale * velocity.z, 1.0)
        }
    }
    
    func _configShell() {
        let pscale = m_Scales.mnCluster
        let vscale = pscale * m_Scales.mnVelocity
        let inner  = 2.5 * pscale
        let outer  = 4.0 * pscale
        let length = outer - inner
        
        DispatchQueue.concurrentPerform(iterations: mnParticles) {i in
            let nrpos    = self.mpGenerator[1].nrand()
            let rpos     = self.mpGenerator[0].rand()
            let position = nrpos * (inner + (length * rpos))
            
            self.position?[i] = float4(position.x, position.y, position.z, 1.0)
            
            var axis = self._axis
            
            let scalar = dot(nrpos, axis)
            
            if (1.0 - scalar) < 1e-6 {
                axis = float3(nrpos.y, nrpos.x, axis.z)
                
                axis = normalize(axis)
            }
            
            let velocity = cross(position, axis)
            
            self.velocity?[i] = float4(velocity.x * vscale, velocity.y * vscale, velocity.z * vscale, 1.0)
        }
    }
    
    private func _configExpand() {
        let pscale = m_Scales.mnCluster * max(1.0, m_Scales.mnParticles)
        let vscale = pscale * m_Scales.mnVelocity
        
        DispatchQueue.concurrentPerform(iterations: mnParticles) {i in
            let point = self.mpGenerator[1].rand()
            
            self.position?[i] = float4(point.x * pscale, point.y * pscale, point.z * pscale, 1.0)
            
            self.velocity?[i] = float4(point.x * vscale, point.y * vscale, point.z * vscale, 1.0)
        }
    }
    
    // Generate a inital simulation data
    func acquire(_ config: NBody.Defaults.Configs) {
        if isComplete && position != nil && velocity != nil {
            _config = config
            
            if m_DQueue == nil {
                let pQGen = CFQueueGenerator()
                
                pQGen.label = "com.apple.nbody.generator.main"
                
                m_DQueue = pQGen.queue
            }
            
            if m_DQueue != nil {
                switch _config {
                case .expand:
                    self._configExpand()
                    
                case .random:
                    self._configRandom()
                    
                case .shell:
                    fallthrough
                default:
                    self._configShell()
                }
            }
        }
    }
    
}
