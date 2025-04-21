//
//  KMeans.swift
//
//
//  Created by jung on 11/6/23.
//

import Foundation

final class KMeans<T: ClusterData>: ClusteringAlgorithm<T> {
  private var isChanged: Bool = false
  
  /// Cluster들의 Centriods
  var centroids: [Location] { clusters.map { $0.centroid } }

  override var isAsynchronous: Bool { true }
  
  // MARK: - Run Methods
  override func run() {
    initClusters()
    
    var iteration = 0
    repeat {
      runIteration(at: &iteration)
    } while isChanged && (iteration < maxIterations) && !isCancelled
  }
}

// MARK: - Setup methods
private extension KMeans {
	func initClusters() {
		let initCenteroids = randomCenteroids(count: k, data: data)
		self.clusters = generateClusters(centroids: initCenteroids)
  
		run(operations: classifyDataToNearestCluster)
	}
	
	func runIteration(at iteration: inout Int) {
		run(operations: updateClusters)
		iteration += 1
	}
  
  /// 랜덤하게 `k`만큼 centroid를 지정합니다.
  func randomCenteroids(count: Int, data: [T]) -> [Location] {
    return data.prefix(count).map(\.location)
  }
}

// MARK: - Update Method
private extension KMeans {
  /// Cluster를 업데이트 합니다.
  /// 시간 복잡도 : `O(KN)`
  func updateClusters() {
    let updatedCentroids = updatedCentroids()
    self.isChanged = isChanged(clusters: clusters, newCentroids: updatedCentroids)
    
    guard isChanged else { return }
    self.clusters = generateClusters(centroids: updatedCentroids)
    classifyDataToNearestCluster()
  }
  
	/// 업데이트된 centroid를 리턴합니다.
	func updatedCentroids() -> [Location] {
    return clusters.map { $0.center }
	}
  
  /// cluster의 data의 이동이 있는지 확인합니다. `O(KN)`
  func isChanged(clusters: [Cluster<T>], newCentroids: [Location]) -> Bool {
    for (index, cluster) in clusters.enumerated() {
      let newIndices = cluster.group.map { neareastDistanceIndex(for: $0, from: newCentroids) }
      
      if newIndices.contains(where: { $0 != index }) { return true }
    }
    return false
  }
}

// MARK: - Util Methods
private extension KMeans {
  /// Cluster를 생성합니다.
  func generateClusters(centroids: [Location]) -> [Cluster<T>] {
    return centroids.map { Cluster(centroid: $0) }
  }
  
  /// 각 data들을 가장 가까운 클러스터에 `insert`합니다.
  func classifyDataToNearestCluster() {
    let centroids = centroids
    data.forEach {
      let clusterIndex = neareastDistanceIndex(for: $0, from: centroids)
      clusters[clusterIndex].insert($0)
    }
  }
  
  func neareastDistanceIndex(for data: T, from centroids: [Location]) -> Int {
    return centroids
      .map { $0.distance(with: data.location) }
      .enumerated()
      .min { $0.element < $1.element }?.offset ?? 0
  }
}
