//
//  CGPoint + SIMD.swift
//  Sample
//
//  Created by Damiaan on 30/06/2020.
//

import struct CoreGraphics.CGSize
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGFloat

extension CGSize: SIMD {
	public typealias MaskStorage = SIMD2<CGFloat.NativeType.SIMDMaskScalar>

	public subscript(index: Int) -> CGFloat {
		get {
			index == 0 ? width : height
		}
		set(newValue) {
			if index == 0 { width = newValue }
			else { height = newValue }
		}
	}

	public var scalarCount: Int { 2 }

	public typealias Scalar = CGFloat
}

extension CGPoint: SIMD {
	public typealias MaskStorage = SIMD2<CGFloat.NativeType.SIMDMaskScalar>

	public subscript(index: Int) -> CGFloat {
		get {
			index == 0 ? x : y
		}
		set(newValue) {
			if index == 0 { x = newValue }
			else { y = newValue }
		}
	}

	public var scalarCount: Int { 2 }

	public typealias Scalar = CGFloat
}
