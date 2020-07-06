//
//  StateTest.swift
//  Sample
//
//  Created by Damiaan on 27/06/2020.
//

import SwiftUI
import SortableStacks

struct Example: View {

	struct IdentifiedNumber: Identifiable {
		let value: Int
		let id = UUID()
	}

	@State var numbers = (0..<4).map(IdentifiedNumber.init(value:))

	let dragManager = DragDropManager<IdentifiedNumber>()

	var body: some View {
		VStack(spacing: 8) {
			HStack {
				Button("+") {
					withAnimation {
						numbers.insert(.init(value: .random(in: 1..<31)), at: numbers.indices.randomElement()!)
					}
				}
				Button("Reset") {
					var result = [Int: IdentifiedNumber]()
					let newRange = 0..<4
					let newNumbers = newRange.map(IdentifiedNumber.init(value:))
					for number in newNumbers + self.numbers {
						if newRange.contains(number.value) { result[number.value] = number }
					}
					withAnimation {
						numbers = result.values.sorted {$0.value < $1.value}
					}
				}
				Button("Reverse") {
					withAnimation {
						numbers.reverse()
					}
				}
			}
			HStack {
				ForEach(10..<14) { number in
					MovableSourceBlock(number: number, dragManager: dragManager)
				}
			}.zIndex(1)
//			HStack {
				list
				list
//			}
		}
		.padding()
	}

	struct MovableSourceBlock: View {
		let number: Int
		let dragInfo: DragDropManager<IdentifiedNumber>.Info
		let drags: DragDropManager<IdentifiedNumber>
		@State var offset = CGSize.zero

		class Model { var position = CGPoint.zero }
		@State var model = Model()

		init(number: Int, dragManager: DragDropManager<IdentifiedNumber>) {
			self.number = number
			self.drags = dragManager
			dragInfo = dragManager.createInfo(for: .init(value: number))
		}

		var body: some View {
			Block(number: number, color: .red)
				.offset(offset)
				.zIndex(offset == .zero ? 0 : 1)
				.gesture(move.simultaneously(with: dragdrop))
				.background(
					// FIXME: optimize geometry reading
					// currently each offset state change triggers a geometry save
					GeometryReader(content: savePositionAndRenderBackground)
				)
		}

		func savePositionAndRenderBackground(with proxy: GeometryProxy) -> some View {
			let frame = proxy.frame(in: .global)
			model.position = [frame.midX, frame.midY]
			return Block(number: number, color: .red).opacity(offset == .zero ? 0 : 0.3)
		}

		var move: some Gesture {
			DragGesture(minimumDistance: 2)
				.onChanged { drag in
					offset = drag.translation
				}
		}

		var dragdrop: some Gesture {
			DragGesture(minimumDistance: 2, coordinateSpace: .global)
				.onChanged { drag in
					dragInfo.mousePosition = drag.location
					drags.dragHover(info: dragInfo)
				}
				.onEnded { drag in
					dragInfo.objectPosition = model.position + [drag.translation.width, drag.translation.height]
					let accepted = drags.drop(info: dragInfo)
					withAnimation(accepted ? .none : .default) { offset = .zero }
				}
		}
	}

	var list: some View {
		SortableStack(numbers: numbers, dragManager: dragManager) { number in
			Block(number: number.value, color: .blue)
		} onInsert: { (newElement, index) in
			withAnimation {
				numbers.insert(newElement, at: index)
			}
			return true
		} onMove: { (oldIndex, newIndex) in
			var newNumbers = numbers
			newNumbers.insert(numbers[oldIndex], at: newIndex)
			newNumbers.remove(at: oldIndex + (oldIndex > newIndex ? 1 : 0))
			withAnimation {
				numbers = newNumbers
			}
			return true
		} onRemove: { id in
			if numbers.count > 1 {
				withAnimation { ()->() in
					numbers.removeAll {$0.id == id}
				}
				return true
			} else {
				return false
			}
		}
	}
}

struct StateTest_Previews: PreviewProvider {
    static var previews: some View {
        Example()
    }
}
