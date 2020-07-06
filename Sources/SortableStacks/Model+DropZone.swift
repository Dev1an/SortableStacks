//
//  File.swift
//  
//
//  Created by Damiaan on 06/07/2020.
//

import Dispatch
import struct CoreGraphics.CGPoint
import func SwiftUI.withAnimation

extension SortableStack.Model: DropZone {
	typealias Object = Element

	func acceptDrop(info: Manager.Info) -> Bool {
		defer {
			insertions.removeValue(forKey: info.object.id)
		}
		guard !properties.elementDictionary.keys.contains(info.object.id) else { return false }
		let localMousePosition = localCoordinate(from: info.mousePosition)
		let index = insertionIndex(for: localMousePosition)
		var didSetInsertion: Bool
		if let globalPosition = info.objectPosition {
			let localPosition = localCoordinate(from: globalPosition)
			insertAnimations[info.object.id] = localPosition
			didSetInsertion = true
		} else {
			didSetInsertion = false
		}
		let inserted = properties.insertionHandler(info.object, index)
		if inserted && didSetInsertion {
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
				self.insertAnimations.removeValue(forKey: info.object.id)
				withAnimation { self.objectWillChange.send() }
			}
		} else {
			insertAnimations.removeValue(forKey: info.object.id)
		}
		return inserted
	}

	func localCoordinate(from global: CGPoint) -> CGPoint {
		// FIXME: Flip Y coordinates when needed
		let nonFlipped = (global - frame.origin)
		#if os(macOS)
		return [nonFlipped.x, frame.size.height - nonFlipped.y]
		#else
		return nonFlipped
		#endif
	}

	func dragHover(info: Manager.Info) {
		guard frame.contains(info.mousePosition) else { return }
		guard !properties.elementDictionary.keys.contains(info.object.id) else { return }
		let localMousePosition = localCoordinate(from: info.mousePosition)
		let index = insertionIndex(for: localMousePosition)
		let oldIndex = insertions[info.object.id]?.1
		insertions[info.object.id] = (info.object, index)
		if oldIndex == nil || index != oldIndex {
			withAnimation {
				objectWillChange.send()
			}
		}
	}

	func release(object: Element) {
		insertions.removeValue(forKey: object.id)
		withAnimation {
			objectWillChange.send()
		}
	}
}
