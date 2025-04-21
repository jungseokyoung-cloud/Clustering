//
//  Cluster.swift
//
//
//  Created by jung on 11/6/23.
//

import Foundation

final class Cluster<T: ClusterData> {
	// MARK: - Properties
	/// Cluster의 중심
	var centroid: Location
		
	/// Cluster 내부 점들
	var group: [T]

	var size: Int { group.count }
  var isEmpty: Bool { group.isEmpty }
  
  private var sumOfLocation: Location
  
	// MARK: - Initalizers
	init(centroid: Location) {
		self.centroid = centroid
		self.group = [T]()
		sumOfLocation = .zero
	}
}

extension Cluster {
	/// Cluster에 새로운 데이터를 추가합니다.
	func insert(_ data: T) {
		group.append(data)
		sumOfLocation += data.location
	}

	@discardableResult
	/// 해당 값을 가지는 점을 Cluster에서 제거합니다.
	func remove(_ data: T) -> T? {
    guard let index = group.firstIndex(where: { $0 == data }) else { return nil }

    let value = group.remove(at: index)
		sumOfLocation -= data.location
		return value
	}
	
	/// 다른 Cluster와 합칩니다.
	func combine(with other: Cluster) {
    self.group += other.group
		sumOfLocation += other.sumOfLocation
		updateCentroid()
	}
}

// MARK: - Centriod 로직
extension Cluster {
	/// Cluster내의 모든 점의 평균을 통해 Centriod를 업데이트합니다.
	func updateCentroid() {
    guard size != 0 else { return }
		centroid = sumOfLocation / Double(size)
	}
}

// MARK: - Validation 로직
extension Cluster {
	/// Cluster의 Centriod로부터 분산을 리턴합니다.
	func deviation(from data: T) -> Double {
		// 해당 데이터가 클러스터내에 위치한다면, -1을 해줍니다.
    let divisor = group.contains(data) ? group.count - 1 : group.count

		return group
			.map { $0.location }
			.reduce(0) { $0 + data.location.distance(with: $1) } / Double(divisor)
	}
}

// MARK: - Equatable
extension Cluster: Equatable {
	static func == (lhs: Cluster, rhs: Cluster) -> Bool {
		return lhs.centroid == rhs.centroid
	}
}
