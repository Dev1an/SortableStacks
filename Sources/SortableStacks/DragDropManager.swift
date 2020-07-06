//
//  DragDropManager.swift
//  Sample
//
//  Created by Damiaan on 03/07/2020.
//

import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGRect

public protocol DropZone: AnyDropZone {
	associatedtype Object: Identifiable
	typealias Manager = DragDropManager<Object>
	func acceptDrop(info: Manager.Info) -> Bool
	func dragHover(info: Manager.Info)
	func release(object: Object)
}

extension DropZone {
	func acceptDrop(unsafeInfo: ErasedDropZoneInfo) -> Bool {
		acceptDrop(info: unsafeInfo as! DragDropManager<Object>.Info)
	}
	func dragHover(unsafeInfo: ErasedDropZoneInfo) {
		dragHover(info: unsafeInfo as! DragDropManager<Object>.Info)
	}
	func release(unsafeObject: Any) {
		release(object: unsafeObject as! Object)
	}
}

public protocol AnyDropZone {
	var frame: CGRect {get}

	func acceptDrop(unsafeInfo: ErasedDropZoneInfo) -> Bool
	func dragHover(unsafeInfo: ErasedDropZoneInfo)
	func release(unsafeObject: Any)
}

public protocol ErasedDropZoneInfo {
	var mousePosition: CGPoint {get}
	var objectPosition: CGPoint? {get}
}

public class DragDropManager<Object: Identifiable> {
	public class Info: ErasedDropZoneInfo {
		let object: Object
		let release: ()->Void
		public var mousePosition = CGPoint.zero
		public var objectPosition: CGPoint?

		fileprivate init(object: Object, release: @escaping ()->Void) {
			self.object = object
			self.release = release
		}

		deinit {
			release()
		}
	}

	public init() {}

	public func createInfo(for object: Object) -> Info {
		Info(object: object) { [weak self] in
			self?.release(object: object)
		}
	}

	private(set) var dropzones = [AnyHashable: AnyDropZone]()
	var objectHovers = [Object.ID: AnyHashable]()

	func register<Zone: DropZone, ID: Hashable>(dropZone: Zone, with id: ID) where Zone.Object == Object {
		let key = AnyHashable(id)
		#if DEBUG
		if dropzones.keys.contains(key) {
			print("WARNING: duplicate dropzone registration for", dropZone)
		}
		#endif
		dropzones[key] = dropZone
	}

	func unregister<ID: Hashable>(id: ID) {
		let key = AnyHashable(id)
		#if DEBUG
		if !dropzones.keys.contains(key) {
			print("WARNING: trying to remove unregistered drop zone", key)
		}
		#endif
		dropzones.removeValue(forKey: key)
	}

	func dropZoneID(under location: CGPoint) -> AnyHashable? {
		dropzones.first { $1.frame.contains(location) }?.key
	}

	public func dragHover(info: Info) {
		if let newZoneID = dropZoneID(under: info.mousePosition) {
			if let previousZoneID = objectHovers[info.object.id], previousZoneID != newZoneID, let previousZone = dropzones[previousZoneID] {
				previousZone.release(unsafeObject: info.object)
			}
			if let newZone = dropzones[newZoneID] {
				newZone.dragHover(unsafeInfo: info)
				objectHovers[info.object.id] = newZoneID
			} else {
				objectHovers.removeValue(forKey: info.object.id)
			}
		} else if let previousZoneID = objectHovers[info.object.id] {
			dropzones[previousZoneID]?.release(unsafeObject: info.object)
			objectHovers.removeValue(forKey: info.object.id)
		}
	}

	public func drop(info: Info) -> Bool {
		if let newZoneID = dropZoneID(under: info.mousePosition) {
			if let previousZoneID = objectHovers[info.object.id], previousZoneID != newZoneID, let previousZone = dropzones[previousZoneID] {
				previousZone.release(unsafeObject: info.object)
			}
			if let newZone = dropzones[newZoneID] {
				return newZone.acceptDrop(unsafeInfo: info)
			}
		}
		objectHovers.removeValue(forKey: info.object.id)
		return false
	}

	func release(object: Object) {
		dropzones.values.forEach { dropzone in dropzone.release(unsafeObject: object) }
	}
}

