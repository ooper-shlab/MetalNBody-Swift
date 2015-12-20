//
//  CMTransforms.swift
//  Metal N-Body
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/12/12.
//
//
/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 Utility methods for linear transformations of projective geometry of the left-handed coordinate systems.
 */

import Foundation
import simd

func * (lhs: matrix_float4x4, rhs: matrix_float4x4) -> matrix_float4x4 {
    return matrix_multiply(lhs, rhs)
}

//MARK: -
//MARK: Private - Constants

private let kPi_f      = Float(M_PI)
private let k1Div180_f: Float = 1.0 / 180.0
private let kRadians_f = k1Div180_f * kPi_f

extension CM {
//MARK: -
//MARK: Private - Utilities

    private static func radians(degrees: Float) -> Float {
        return kRadians_f * degrees
    }

//MARK: -
//MARK: Public - Transformations - Constructors

// Construct a float 2x2 matrix from an array
// of floats with 4 elements
    static func float2x2(transpose: Bool,
        M: UnsafePointer<Float>) -> matrix_float2x2
    {
        var N = matrix_float2x2()

        if M != nil {
            var v: [float2] = [float2(), float2()]

            v[0] = float2(M[0], M[1])
            v[1] = float2(M[2], M[3])

            N = transpose
            ? matrix_from_rows(v[0], v[1])
            : matrix_from_columns(v[0], v[1])
        } else {
            N = matrix_identity_float2x2
        }

        return N
    }

// Construct a float 3x3 matrix from an array
// of floats with 9 elements
    static func float3x3(transpose: Bool,
        M: UnsafePointer<Float>) -> matrix_float3x3
    {
        var N = matrix_float3x3()

        if M != nil {
            var v: [float3] = [float3(), float3(), float3()]

            v[0] = float3(M[0], M[1], M[2])
            v[1] = float3(M[3], M[4], M[5])
            v[2] = float3(M[6], M[7], M[8])

            N = transpose
            ? matrix_from_rows(v[0], v[1], v[2])
            : matrix_from_columns(v[0], v[1], v[2])
        } else {
            N = matrix_identity_float3x3
        }

        return N
    }

// Construct a float 4x4 matrix from an array
// of floats with 16 elements
    static func float4x4(transpose: Bool,
        M: UnsafePointer<Float>) -> matrix_float4x4
    {
        var N = matrix_float4x4()

        if M != nil {
            var v: [float4] = [float4(), float4(), float4(), float4()]

            v[0] = float4(M[0], M[1], M[2], M[3])
            v[1] = float4(M[4], M[5], M[6], M[7])
            v[2] = float4(M[8], M[9], M[10], M[11])
            v[3] = float4(M[12], M[13], M[14], M[15])

            N = transpose
            ? matrix_from_rows(v[0], v[1], v[2], v[3])
            : matrix_from_columns(v[0], v[1], v[2], v[3])
        } else {
            N = matrix_identity_float4x4
        }

        return N
    }

// Construct a float 3x3 matrix from a 4x4 matrix
    static func float3x3(transpose: Bool,
        M: matrix_float4x4) -> matrix_float3x3
    {
        let P = float3(M.columns.0.x, M.columns.0.y, M.columns.0.z)
        let Q = float3(M.columns.1.x, M.columns.1.y, M.columns.1.z)
        let R = float3(M.columns.2.x, M.columns.2.y, M.columns.2.z)

        return transpose ? matrix_from_rows(P, Q, R) : matrix_from_columns(P, Q, R)
    }

// Construct a float 4x4 matrix from a 3x3 matrix
    static func float4x4(transpose: Bool,
        M: matrix_float3x3) -> matrix_float4x4
    {
        let S = float4(0.0, 0.0, 0.0, 1.0)

        let P = float4(M.columns.0.x, M.columns.0.y, M.columns.0.z, 0.0)
        let Q = float4(M.columns.1.x, M.columns.1.y, M.columns.1.z, 0.0)
        let R = float4(M.columns.2.x, M.columns.2.y, M.columns.2.z, 0.0)

        return transpose ? matrix_from_rows(P, Q, R, S) : matrix_from_columns(P, Q, R, S)
    }

//MARK: -
//MARK: Public - Transformations - Scale

    static func scale(x: Float, _ y: Float, _ z: Float) -> matrix_float4x4 {
        var v = matrix_float4x4()
        v.columns.0.x = x
        v.columns.1.y = y
        v.columns.2.z = z
        v.columns.3.w = 1.0

        return v
    }

    static func scale(s: float3) -> matrix_float4x4 {
        var v = matrix_float4x4()
        v.columns.0.x = s.x
        v.columns.1.y = s.y
        v.columns.2.z = s.z
        v.columns.3.w = 1.0

        return v
    }

//MARK: -
//MARK: Public - Transformations - Translate

    static func translate(t: float3) -> matrix_float4x4 {
        var M = matrix_identity_float4x4

        M.columns.3 = float4(t.x, t.y, t.z, 1.0)

        return M
    }

    static func translate(x: Float, _ y: Float, _ z: Float) -> matrix_float4x4 {
        return translate(float3(x, y, z))
    }

//MARK: -
//MARK: Public - Transformations - Left-Handed - Rotate

    static func AAPLRadiansOverPi(degrees: Float) -> Float {
        return (degrees * k1Div180_f)
    }

    static func rotate(angle: Float, _ r: float3) -> matrix_float4x4 {
        let a = AAPLRadiansOverPi(angle)
        var c: Float = 0.0
        var s: Float = 0.0

    // Computes the sine and cosine of pi times angle (measured in radians)
    // faster and gives exact results for angle = 90, 180, 270, etc.
        __sincospif(a, &s, &c)

        let k = 1.0 - c

        let u = normalize(r)
        let v = s * u
        let w = k * u

        var P = float4()
        var Q = float4()
        var R = float4()
        var S = float4()

        P.x = w.x * u.x + c
        P.y = w.x * u.y + v.z
        P.z = w.x * u.z - v.y

        Q.x = w.x * u.y - v.z
        Q.y = w.y * u.y + c
        Q.z = w.y * u.z + v.x

        R.x = w.x * u.z + v.y
        R.y = w.y * u.z - v.x
        R.z = w.z * u.z + c

        S.w = 1.0

        return matrix_float4x4(columns: (P, Q, R, S))
    }

    static func rotate(angle: Float, _ x: Float, _ y: Float, _ z: Float) -> matrix_float4x4 {
        let r = float3(x, y, z)

        return rotate(angle, r)
    }

//MARK: -
//MARK: Public - Transformations - Left-Handed - Perspective

//simd::float4x4 CM::perspective(const float& width,
//                               const float& height,
//                               const float& near,
//                               const float& far)
//{
//    float zNear = 2.0f * near;
//    float zFar  = far / (far - near);
//
//    simd::float4 P = 0.0f;
//    simd::float4 Q = 0.0f;
//    simd::float4 R = 0.0f;
//    simd::float4 S = 0.0f;
//
//    P.x =  zNear / width;
//    Q.y =  zNear / height;
//    R.z =  zFar;
//    R.w =  1.0f;
//    S.z = -near * zFar;
//
//    return simd::float4x4(P, Q, R, S);
//} // perspective
//
//simd::float4x4 CM::perspective_fov(const float& fovy,
//                                   const float& aspect,
//                                   const float& near,
//                                   const float& far)
//{
//    float angle  = CM::radians(0.5f * fovy);
//    float yScale = 1.0f/ std::tan(angle);
//    float xScale = yScale / aspect;
//    float zScale = far / (far - near);
//
//    simd::float4 P = 0.0f;
//    simd::float4 Q = 0.0f;
//    simd::float4 R = 0.0f;
//    simd::float4 S = 0.0f;
//
//    P.x =  xScale;
//    Q.y =  yScale;
//    R.z =  zScale;
//    R.w =  1.0f;
//    S.z = -near * zScale;
//
//    return simd::float4x4(P, Q, R, S);
//} // perspective_fov
//
//simd::float4x4 CM::perspective_fov(const float& fovy,
//                                   const float& width,
//                                   const float& height,
//                                   const float& near,
//                                   const float& far)
//{
//    float aspect = width / height;
//
//    return CM::perspective_fov(fovy, aspect, near, far);
//} // perspective_fov

//MARK: -
//MARK: Public - Transformations - Left-Handed - LookAt

//simd::float4x4 CM::lookAt(const simd::float3& eye,
//                          const simd::float3& center,
//                          const simd::float3& up)
//{
//    simd::float3 E = -eye;
//    simd::float3 N = simd::normalize(center + E);
//    simd::float3 U = simd::normalize(simd::cross(up, N));
//    simd::float3 V = simd::cross(N, U);
//
//    simd::float4 P = 0.0f;
//    simd::float4 Q = 0.0f;
//    simd::float4 R = 0.0f;
//    simd::float4 S = 0.0f;
//
//    P.x = U.x;
//    P.y = V.x;
//    P.z = N.x;
//
//    Q.x = U.y;
//    Q.y = V.y;
//    Q.z = N.y;
//
//    R.x = U.z;
//    R.y = V.z;
//    R.z = N.z;
//
//    S.x = simd::dot(U, E);
//    S.y = simd::dot(V, E);
//    S.z = simd::dot(N, E);
//    S.w = 1.0f;
//
//    return simd::float4x4(P, Q, R, S);
//} // lookAt
//
//simd::float4x4 CM::lookAt(const float * const pEye,
//                          const float * const pCenter,
//                          const float * const pUp)
//{
//    simd::float3 eye    = {pEye[0], pEye[1], pEye[2]};
//    simd::float3 center = {pCenter[0], pCenter[1], pCenter[2]};
//    simd::float3 up     = {pUp[0], pUp[1], pUp[2]};
//
//    return CM::lookAt(eye, center, up);
//} // lookAt

//MARK: -
//MARK: Public - Transformations - Left-Handed - Orthographic

    static func ortho2d(left: Float,
        _ right: Float,
        _ bottom: Float,
        _ top: Float,
        _ near: Float,
        _ far: Float) -> matrix_float4x4
    {
        let sLength = 1.0 / (right - left)
        let sHeight = 1.0 / (top   - bottom)
        let sDepth  = 1.0 / (far   - near)

        var P = float4()
        var Q = float4()
        var R = float4()
        var S = float4()

        P.x =  2.0 * sLength
        Q.y =  2.0 * sHeight
        R.z =  sDepth
        S.z = -near  * sDepth
        S.w =  1.0

        return matrix_float4x4(columns: (P, Q, R, S))
    }

    static func ortho2d(origin: float3, _ size: float3) -> matrix_float4x4 {
        return CM.ortho2d(origin.x, origin.y, origin.z, size.x, size.y, size.z)
    }

//MARK: -
//MARK: Public - Transformations - Left-Handed - Off-Center Orthographic

    static func ortho2d_oc(left: Float,
        _ right: Float,
        _ bottom: Float,
        _ top: Float,
        _ near: Float,
        _ far: Float) -> matrix_float4x4
    {
        let sLength = 1.0 / (right - left)
        let sHeight = 1.0 / (top   - bottom)
        let sDepth  = 1.0 / (far   - near)

        var P = float4()
        var Q = float4()
        var R = float4()
        var S = float4()

        P.x =  2.0 * sLength
        Q.y =  2.0 * sHeight
        R.z =  sDepth
        S.x = -sLength * (left + right)
        S.y = -sHeight * (top + bottom)
        S.z = -sDepth  * near
        S.w =  1.0

        return matrix_float4x4(columns: (P, Q, R,S))
    }

    static func ortho2d_oc(origin: float3,
        _ size: float3) -> matrix_float4x4
    {
        return ortho2d_oc(origin.x, origin.y, origin.z, size.x, size.y, size.z)
    }

//MARK: -
//MARK: Public - Transformations - Left-Handed - frustum

    static func frustum(fovH: Float,
        _ fovV: Float,
        _ near: Float,
        _ far: Float) -> matrix_float4x4
    {
        let width  = 1.0 / tan(radians(0.5 * fovH))
        let height = 1.0 / tan(radians(0.5 * fovV))
        let sDepth = far / ( far - near )

        var P = float4()
        var Q = float4()
        var R = float4()
        var S = float4()

        P.x =  width
        Q.y =  height
        R.z =  sDepth
        R.w =  1.0
        S.z = -sDepth * near

        return matrix_float4x4(columns: (P, Q, R, S))
    }

    static func frustum(left: Float,
        _ right: Float,
        _ bottom: Float,
        _ top: Float,
        _ near: Float,
        _ far: Float) -> matrix_float4x4
    {
        let width  = right - left
        let height = top   - bottom
        let depth  = far   - near
        let sDepth = far / depth

        var P = float4()
        var Q = float4()
        var R = float4()
        var S = float4()

        P.x =  width
        Q.y =  height
        R.z =  sDepth
        R.w =  1.0
        S.z = -sDepth * near

        return matrix_float4x4(columns: (P, Q, R, S))
    }

    static func frustum_oc(left: Float,
        _ right: Float,
        _ bottom: Float,
        _ top: Float,
        _ near: Float,
        _ far: Float) -> matrix_float4x4
    {
        let sWidth  = 1.0 / (right - left)
        let sHeight = 1.0 / (top   - bottom)
        let sDepth  = far  / (far   - near)
        let dNear   = 2.0 * near

        var P = float4()
        var Q = float4()
        var R = float4()
        var S = float4()

        P.x =  dNear * sWidth
        Q.y =  dNear * sHeight
        R.x = -sWidth  * (right + left)
        R.y = -sHeight * (top   + bottom)
        R.z =  sDepth
        R.w =  1.0
        S.z = -sDepth * near

        return matrix_float4x4(columns: (P, Q, R, S))
    }
}