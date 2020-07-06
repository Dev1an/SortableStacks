//
//  Rearrange+overlay.swift
//  Sample
//
//  Created by Damiaan on 02/07/2020.
//

import SwiftUI

extension SortableStack {
	class Model: ObservableObject {
		let id = UUID()
		let queue = DispatchQueue(label: "RearrangeableList: sequential operations", qos: .userInteractive, attributes: [])
		var properties: Properties {
			willSet {
				var garbage = Set(positions.keys)
				for element in newValue.elements {
					garbage.remove(element.id)
				}
				for trash in garbage {
					positions.removeValue(forKey: trash)
				}
			}
		}
		var positions = [Element.ID: CGPoint]()
		var insertionPoints = [Element.ID: CGPoint]()
		var insertAnimations = [Element.ID: CGPoint]()

		var removals = Set<Element.ID>()
		var reinsertions = [Element.ID: Int]()
		var insertions = [Element.ID: (Element, Int)]()
		var frame = CGRect.zero

		init () {
			self.properties = Properties(
				elements: [],
				insertionHandler: {_,_ in false},
				moveHandler: {_,_ in false},
				removeHandler: {_ in false}
			)
		}

		var localFrame: CGRect { CGRect(origin: .zero, size: frame.size) }

		func merge(anchors: IndexedPointAnchors.Value, in proxy: GeometryProxy) -> [(key: Element.ID, value: CGPoint)] {
			for (index, (anchor, isInsertion)) in anchors {
				if isInsertion {
					insertionPoints[index] = proxy[anchor]
				} else {
					positions[index] = proxy[anchor]
				}
			}
			var alteredPosition = positions
			for (id, position) in insertAnimations {
				if positions.keys.contains(id) {
					alteredPosition[id] = position
				}
			}
			return Array(alteredPosition)
		}

		var backings: [(element: Element, insertion: Bool)] {
			[(Element, Bool)](unsafeUninitializedCapacity: properties.elements.count + insertions.count) { (buffer, count) in
				for cursor in properties.elements.indices {
					for (id, insertionIndex) in reinsertions {
						// FIXME: Optimize reinsertion traversal
						if insertionIndex == cursor {
							buffer[count] = (properties.elementDictionary[id]!, true)
							count += 1
						}
					}
					for (element, insertionIndex) in insertions.values {
						if insertionIndex == cursor {
							buffer[count] = (element, true)
							count += 1
						}
					}
					if !removals.contains(properties.elements[cursor].id) {
						buffer[count] = (properties.elements[cursor], false)
						count += 1
					}
				}
				for (id, insertionIndex) in reinsertions {
					if insertionIndex == properties.elements.count {
						buffer[count] = (properties.elementDictionary[id]!, true)
						count += 1
					}
				}
				for (element, insertionIndex) in insertions.values {
					if insertionIndex == properties.elements.count {
						buffer[count] = (element, true)
						count += 1
					}
				}
			}
		}

		func optionalInsertionIndex(for location: CGPoint) -> Int? {
			/// FIXME: optimize containment (remove localFrame generation)
			guard localFrame.contains(location) else { return nil }
			return insertionIndex(for: location)
		}

		func insertionIndex(for location: CGPoint) -> Int {
			let insertionIndex = properties.elements.firstIndex {
				// FIXME: Use binary search here
				guard !removals.contains($0.id) else { return false }
				guard let position = positions[$0.id]?.x else { return false }
				return position > location.x
			}
			return insertionIndex ?? properties.elements.endIndex
		}
	}
}

// MARK: - Properties

extension SortableStack.Model {

	class Properties {
		let elements: [Element]
		let elementDictionary: [Element.ID: Element]

		let insertionHandler: SortableStack.InsertionHandler
		let moveHandler: SortableStack.MoveHandler
		let removeHandler: SortableStack.RemoveHandler

		init(elements: [Element], insertionHandler: @escaping SortableStack.InsertionHandler, moveHandler: @escaping SortableStack.MoveHandler, removeHandler: @escaping SortableStack.RemoveHandler) {
			self.elements = elements
			self.elementDictionary = Dictionary(uniqueKeysWithValues: elements.map{($0.id, $0)})
			self.insertionHandler = insertionHandler
			self.moveHandler = moveHandler
			self.removeHandler = removeHandler
		}
	}

}
