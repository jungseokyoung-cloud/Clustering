//
//  KMeans.swift
//
//
//  Created by jung on 11/6/23.
//

import Foundation

final class KMeans<T: ClusterData>: Operation {
	let k: Int
	let data: [T]
	var clusters: [Cluster<T>]
	
	/// KMeans의 최대 Iteration
	var maxIterations: Int
	
	/// 센트로이드의 이동이 있었는지에 대한 여부.
	private(set) var isChanged: Bool
	
	/// Cluster들의 Centriods
	var centroids: [Location] { clusters.map { $0.centroid } }

	/// Clustering의 Silhouette 점수
	private(set) var silhouetteScore: Double = 0

	override var isAsynchronous: Bool { true }
	
	// MARK: - Initializers
	init(k: Int, data: [T], maxIterations: Int) {
		self.k = k
		self.data = data
		self.maxIterations = maxIterations
		self.clusters = []
		self.isChanged = false
	}
	
	// MARK: - main Method
	override func main() {
		guard !isCancelled else { return }
		
		run()
		setSilhouetteScore()
	}
}

// MARK: - run Methods
private extension KMeans {
	func run() {
		initClusters()
		
		var iteration = 0
		
		repeat {
			runIteration(at: &iteration)
		} while isChanged && (iteration < maxIterations) && !isCancelled
	}
	
	func initClusters() {
		let initCenteroids = randomCenteroids(count: k, data: data)
		
		self.clusters = generateClusters(centroids: initCenteroids)
		
		run(operations: classifyDataToNearestCluster, updateCentroids)
	}
	
	func runIteration(at iteration: inout Int) {
		run(operations: updateClusters, updateCentroids)
		iteration += 1
	}
	
	func run(operations: (() -> Void)...) {
		guard !isCancelled else { return }
		self.queuePriority = QueuePriority(rawValue: k + 4) ?? .high
		
		operations.forEach { $0() }
	}
}

// MARK: - Setup methods
private extension KMeans {
	/// 랜덤하게 `k`만큼 centroid를 지정합니다.
	func randomCenteroids(count: Int, data: [T]) -> [Location] {
		guard count != data.count else { return data.map { $0.location } }
		var result = Array<T>()
		
		while(result.count != count) {
			if
				let randomElement = data.randomElement(),
				!result.contains(randomElement) {
				result.append(randomElement)
			}
		}
		
		return result.map { $0.location }
	}
}

// MARK: - Update Method
private extension KMeans {
	/// Centroid를 업데이트 합니다.
	func updateCentroids() {
		clusters.forEach { $0.updateCentroid() }
	}
	
	/// Cluster를 업데이트 합니다.
	/// 시간 복잡도 : `O(N)`
	func updateClusters() {
		isChanged = false
		
		clusters.forEach { cluster in
			if isChanged { return }
			
			self.isChanged = isChanged(cluster: cluster)
		}
		
		// Cluster의 데이터 이동이 있으면, Cluster를 재생성합니다.
		if isChanged {
			self.clusters = generateClusters(centroids: centroids)
			classifyDataToNearestCluster()
		}
	}
	
	/// cluster의 data의 이동이 있는지 확인합니다.
	func isChanged(cluster: Cluster<T>) -> Bool {
		let changedCluster = cluster.group.allValues()
			.map { neareastCluster(from: $0) }
			.first(where: { $0 != cluster })
		
		return changedCluster != nil
	}
	
	/// Cluster를 생성합니다.
	func generateClusters(centroids: [Location]) -> [Cluster<T>] {
		return centroids.map { Cluster(centroid: $0) }
	}
	
	/// 각 data들을 가장 가까운 클러스터에 `insert`합니다.
	func classifyDataToNearestCluster() {
		data.forEach { neareastCluster(from: $0).insert($0) }
	}
	
	/// 해당 location으로 부터 가장 가까운 Cluster를 리턴합니다.
	func neareastCluster(from data: T) -> Cluster<T> {
		var minDistance = Double.greatestFiniteMagnitude
		var nearestClusterIndex = 0
		
		clusters.enumerated().forEach { index, cluster in
			let distance = cluster.centroid.distance(with: data.location)
			
			if distance < minDistance {
				nearestClusterIndex = index
				minDistance = distance
			}
		}
		
		return clusters[nearestClusterIndex]
	}
}

// MARK: - Validation Method
private extension KMeans {
	/// silhouetteScore을 계산하여 silhouetteScore 변수에 대입합니다.
	/// 시간 복잡도 : `O(n^2)`
	func setSilhouetteScore() {
		self.silhouetteScore = -1
		
		clusters.forEach { cluster in
			if cluster.size == 0 {
				silhouetteScore = max(silhouetteScore, 0)
			} else {
				silhouetteScore = max(silhouetteScore, meanSilhouetteCoefficient(at: cluster))
			}
		}
	}
	
	/// cluster의 평균 Silhouette 계수를 리턴합니다.
	func meanSilhouetteCoefficient(at cluster: Cluster<T>) -> Double {
		let cohesionCoefficients = cohesionCoefficients(cluster)
		var minSeparationCoefficients = [Double](
			repeating: .greatestFiniteMagnitude,
			count: cluster.size
		)
		
		clusters.filter { $0 != cluster }
			.forEach { otherCluster in
				minSeparationCoefficients = zip(
					seperationCoefficients(cluster, with: otherCluster),
					minSeparationCoefficients
				)
				.map { min($0.0, $0.1) }
			}
		
		let zipCoefficients = zip(cohesionCoefficients, minSeparationCoefficients)
		
		let dividend = zipCoefficients.map { $1 - $0 }
		let divisor = zipCoefficients.map { max($0, $1) }
		
		let sumOfSilhouetteIndex = zip(dividend, divisor)
			.map { $0 / $1 }
			.reduce(0) { $0 + $1 }
		
		return sumOfSilhouetteIndex / Double(cluster.size)
	}
	
	/// 해당 클러스터 내의 모든점의 cohesion 계수를 리턴합니다.
	/// 각 점이 속한 클러스터간의 응집도를 판별합니다.
	func cohesionCoefficients(_ cluster: Cluster<T>) -> [Double] {
		cluster.group.allValues()
			.map { cluster.deviation(from: $0) }
	}
	
	/// 클러스터내의 모든점의 seperation 계수를 리턴합니다.
	/// `with`파라미터를 통해 전달한 클러스터 간의 응집도를 판별합니다.
	func seperationCoefficients(
		_ cluster: Cluster<T>,
		with other: Cluster<T>
	) -> [Double] {
		cluster.group.allValues()
			.map { other.deviation(from: $0) }
	}
}
