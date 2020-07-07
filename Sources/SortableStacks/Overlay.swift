//
//  File.swift
//  
//
//  Created by Damiaan on 06/07/2020.
//

import SwiftUI

extension SortableStack {
	struct Overlay: View {
		let model: Model
		let index: Element.ID
		let view: ElementView
		let space: UUID
		@State var offset = CGSize.zero

		var body: some View {
			view
				.offset(offset)
				.zIndex(offset == .zero ? 0 : 1)
				.gesture(move)
				.transition(
					.asymmetric(
						insertion: model.insertAnimations[index] == nil ? .opacity : .identity,
						removal: .opacity
					)
				)
		}

//		var center: UnitPoint {
//			UnitPoint(
//				x: ((model.positions[index]?.x ?? 0) + offset.width)  / model.frame.width,
//				y: ((model.positions[index]?.y ?? 0) + offset.height) / model.frame.height
//			)
//		}

		var originalIndex: Int {
			model.properties.elements.firstIndex { $0.id == index }!
		}

		var move: some Gesture {
			DragGesture(minimumDistance: 2, coordinateSpace: .named(space))
				.onChanged{ (drag) in
					offset = drag.translation
					let inserted = model.removals.insert(index).inserted
					let oldIndex = model.reinsertions[index]
					let newIndex = model.optionalInsertionIndex(for: drag.location)
					model.reinsertions[index] = newIndex
					withAnimation {
						if inserted || oldIndex != newIndex {
							model.objectWillChange.send()
						}
					}
				}
				.onEnded { (drag) in
					model.queue.sync {
						let removal: Bool
						model.reinsertions.removeValue(forKey: index)
						model.removals.remove(index)
						if let insertion = model.optionalInsertionIndex(for: drag.location) {
							let positionDifference: CGSize
							if let newPosition = model.insertionPoints[index] {
								let currentPosition = model.positions[index]!
								let difference = currentPosition - newPosition
								positionDifference = [difference.x, difference.y]
							} else {
								positionDifference = .zero
							}
							if model.properties.moveHandler(originalIndex, insertion) {
								offset += positionDifference
							}
							removal = false
						} else {
							if model.properties.removeHandler(index) {
								model.positions.removeValue(forKey: index)
								removal = true
							} else {
								removal = false
							}
						}
						withAnimation {
							if !removal { offset = .zero }
							model.objectWillChange.send()
						}
					}
				}
		}
	}
}
