//
//  NBodyComputePrefs-Swift.h
//  Metal N-Body
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/12/19.
//
//

#ifndef NBodyComputePrefs_Swift_h
#define NBodyComputePrefs_Swift_h

typedef struct NBody_Compute_Prefs
{
    float  timestep;
    float  damping;
    float  softeningSqr;
    
    unsigned int particles;
} NBody_Compute_Prefs;

#endif /* NBodyComputePrefs_Swift_h */
