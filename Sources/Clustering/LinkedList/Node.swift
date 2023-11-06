//
//  Node.swift
//  
//
//  Created by jung on 11/6/23.
//

import Foundation

final class Node<T: Equatable> {
	var value: T
	var next: Node<T>?
	var prev: Node<T>?
	
	init(value: T) {
		self.value = value
		self.next = nil
		self.prev = nil
	}
}

// MARK: - Method
extension Node {
	/// `previous`와 `after`사이로 Node를 이동합니다.
	func moveBetween(
		_ previous: Node<T>?,
		and after: Node<T>?
	) {
		self.next = after
		self.prev = previous
		
		previous?.next = self
		after?.prev = self
	}
	
	/// `previous`와 `after`사이로 Node를 제거합니다.
	func removeBetween(
		_ previous: Node<T>?,
		and after: Node<T>?
	) {
		previous?.next = after
		after?.prev = previous
	}
}

// MARK: - Equatable
extension Node: Equatable {
	static func == (lhs: Node<T>, rhs: Node<T>) -> Bool {
		return lhs.value == rhs.value
	}
}
