//
//  File.swift
//  
//
//  Created by Damiaan on 06/07/2020.
//

import SwiftUI

extension SortableStack {
	struct IndexedPointAnchors: PreferenceKey {
		typealias Value = [Element.ID: (Anchor<CGPoint>, Bool)]
		static var defaultValue: Value { Value() }

		static func reduce(value: inout Value, nextValue: () -> Value) {
			for (index, position) in nextValue() {
				value[index] = position
			}
		}
	}
}
