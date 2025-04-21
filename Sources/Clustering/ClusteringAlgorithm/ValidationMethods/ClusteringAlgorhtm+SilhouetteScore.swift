//
//  ClusteringAlgorhtm+SilhouetteScore.swift
//  ClusteringDEMO
//
//  Created by jung on 4/16/25.
//

/// silhouetteScore기반으로 검증을 진행합니다.
/// 시간 복잡도 : `O(n^2)`
extension ClusteringAlgorithm {
  func silhouetteScore(from clusters: [Cluster<T>]) -> Double {
    guard !clusters.isEmpty else { return 0 }
    let allScores = clusters.flatMap { cluster -> [Double] in
      return cluster.group.map { point in
        let a = averageIntraDistance(point.location, in: cluster)

        let b = clusters.filter { $0 !== cluster }
          .map { averageInterDistance(point.location, to: $0) }
          .min() ?? 0
        return (b - a) / max(a, b)
      }
    }
    return allScores.reduce(0, +) / Double(allScores.count)
  }
}

// MARK: - Private Methods
fileprivate extension ClusteringAlgorithm {
  func averageIntraDistance(_ point: Location, in cluster: Cluster<T>) -> Double {
    guard cluster.size > 1 else { return 0 }
    
    let total = cluster.group.map(\.location)
      .reduce(0.0) { $0 + $1.distance(with: point) }
    
    return total / Double(cluster.size - 1)
  }

  func averageInterDistance(_ point: Location, to cluster: Cluster<T>) -> Double {
    guard !cluster.isEmpty else { return 0 }
    let total = cluster.group.map(\.location)
      .reduce(0.0) { $0 + $1.distance(with: point) }

    return total / Double(cluster.size)
  }
}
