import SwiftUI

public struct SortableStack<Element: Identifiable, ElementView: View>: View {
	public typealias InsertionHandler = (Element, Int)->Bool
	public typealias RemoveHandler = (Element.ID)->Bool
	public typealias MoveHandler = (Int, Int)->Bool
	public typealias Renderer = (Element) -> ElementView

	let dragManager: DragDropManager<Element>
	let properties: Model.Properties
	let render: (Element)->ElementView

	@State var model = Model()

	public init(numbers: [Element], dragManager: DragDropManager<Element> = .init(), render: @escaping Renderer, onInsert: @escaping InsertionHandler, onMove: @escaping MoveHandler = {_,_ in false}, onRemove: @escaping RemoveHandler = {_ in false}) {
		self.dragManager = dragManager
		self.render = render
		properties = Model.Properties(elements: numbers, insertionHandler: onInsert, moveHandler: onMove, removeHandler: onRemove)
	}

	// MARK: Main body

	public var body: some View {
		model.properties = properties
		return Base(render: render, dragManager: dragManager, model: model)
	}

	struct Base: View {
		let render: (Element)->ElementView
		let space = UUID()
		let dragManager: DragDropManager<Element>

		@ObservedObject var model: Model

		var body: some View {
			HStack(spacing: 8) {
				ForEach(model.backings, id: \.element.id) { (number, insertion) in
					render(number)
						.transformAnchorPreference(key: IndexedPointAnchors.self, value: .center) { (value, anchor) in
							value[number.id] = (anchor, insertion)
						}
						.hidden()
				}
			}
			.animation(nil)
			.frame(maxWidth: .infinity)
			.overlayPreferenceValue(IndexedPointAnchors.self) { anchors in
				GeometryReader { proxy in
					createOverlaysAndSaveCoordinates(proxy: proxy, anchors: anchors)
				}
			}
			.onAppear {
				dragManager.register(dropZone: model, with: model.id)
			}
			.onDisappear {
				dragManager.unregister(id: model.id)
			}
		}

		func createOverlaysAndSaveCoordinates(proxy: GeometryProxy, anchors: IndexedPointAnchors.Value) -> some View {
			model.frame = proxy.frame(in: .global)
			let overlays = model.merge(anchors: anchors, in: proxy)
			return ZStack {
				ForEach(overlays, id: \.key) { (id, position) in
					Overlay(model: model, index: id, view: render(model.properties.elementDictionary[id]!), space: space)
						.position(position)
						.opacity(model.removals.contains(id) && !model.reinsertions.keys.contains(id) ? 0.4 : 1)
				}
			}
			.coordinateSpace(name: space)
		}
	}
}
