//
//  LinkedList.swift
//  
//
//  Created by jung on 11/6/23.
//

import Foundation

final class LinkedList<T: Equatable> {
	// MARK: - Properties
	/// 연결리스트의 첫번째 노드를 가리킵니다.
	private var head: Node<T>?
	
	/// 연결리스트의 마지막 노드를 가리킵니다.
	private var tail: Node<T>?
	
	/// 연결리스트의 현재 노드를 리턴합니다.
	var now: Node<T>?
	
	/// 연결리스트의 사이즈를 리턴합니다.
	private(set) var size: Int

	/// 연결리스트가 비어있는지 여부를 리턴합니다.
	var isEmpty: Bool { size == 0 }
	
	// MARK: - Initiazliers
	init () {
		self.size = 0
		self.head = nil
		self.tail = nil
		self.now = nil
	}
	
	deinit {
		removeAllNode()
	}
}

// MARK: - add Method
extension LinkedList {
	/// 연결리스트 맨 뒤에 데이터를 추가합니다.
	func append(_ input: T) {
		let new: Node<T> = Node(value: input)
		
		new.moveBetween(tail, and: nil)
		self.tail = new
		
		if size == 0 { head = new }
		self.size += 1
	}
}

// MARK: - Remove Methods
extension LinkedList {
	/// `now `가 가리키는 노드를 제거한 후, 리턴합니다.
	func remove() -> T? {
		guard !isEmpty else { return nil }
		
		if now == head {
			return removeHead()
		} else if now == tail {
			return removeTail()
		}
		
		let value = now?.value
		
		now?.removeBetween(now?.prev, and: now?.next)
		now = now?.prev
		self.size -= 1
		
		return value
	}
	
	/// 해당 인덱스의 노드를 제거한 후, 리턴합니다.
	func remove(at index: Int) -> T? {
		guard
			!isEmpty,
			index >= 0 && index < size
		else { return nil }
		
		moveToHead()
		for _ in (0..<index) { moveToNext() }
		
		return remove()
	}
	
	/// 연결리스트의 맨앞 노드를 제거합니다.
	private func removeHead() -> T? {
		head?.removeBetween(nil, and: head?.next)
		
		let value = self.head?.value
		self.head = self.head?.next
		
		self.size -= 1
		if size == 0 { tail = nil }
		
		now = head
		
		return value
	}
	
	/// 연결리스트의 맨 뒤 노드를 제거합니다.
	private func removeTail() -> T? {
		tail?.removeBetween(tail?.prev, and: nil)
		
		let value = self.tail?.value
		self.tail = self.tail?.prev
		
		self.size -= 1
		if size == 0 { head = nil }
		
		now = now?.prev
		
		return value
	}
}

// MARK: - Move Methods
extension LinkedList {
	/// 링크 리스트의 맨 앞 노드로 이동합니다.
	func moveToHead() {
		now = head
	}
	
	/// 이전 노드로 이동합니다.
	func moveToPrevious() {
		now = now?.prev
	}
	
	/// 다음 노드로 이동합니다.
	func moveToNext() {
		now = now?.next
	}
	
	/// 링크 리스트 마지막 노드로 이동합니다.
	func moveToTail() {
		now = tail
	}
}

// MARK: - Util Methods
extension LinkedList {
	/// 해당 값을 가진 노드의 첫번째 인덱스를 리턴합니다.
	func indexOf(_ target: T) -> Int {
		var index: Int = 0
		
		moveToHead()
		while now != nil {
			if now?.value == target {
				return index
			}
			index += 1
			
			moveToNext()
		}
		
		return -1
	}
	
	/// `other`을 현재 링크 리스트 뒤에 병합합니다.
	func merge(other: LinkedList<T>) {
		self.tail?.moveBetween(tail?.prev, and: other.head)

		self.tail = other.tail
		self.size += other.size
	}
	
	/// 링크 리스트의 모든 값들을 리턴합니다.
	func allValues() -> [T] {
		var values: [T?] = []
		
		moveToHead()
		while now != nil {
			values.append(now?.value)
			moveToNext()
		}
		
		return values.compactMap { $0 }
	}
	
	private func removeAllNode() {
		moveToTail()
		repeat {
			tail = now
			now = tail?.prev
			tail?.prev = nil
			tail?.next = nil
		} while(now != nil)
	}
}
