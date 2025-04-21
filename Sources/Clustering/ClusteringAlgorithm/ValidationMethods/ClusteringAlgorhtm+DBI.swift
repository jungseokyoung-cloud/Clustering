//
//  ClusteringAlgorhtm+DBI.swift
//  ClusteringDEMO
//
//  Created by jung on 4/16/25.
//

extension ClusteringAlgorithm {
  func daviesBouldinIndex(from clusters: [Cluster<T>]) -> Double {
    let n = clusters.count
    guard n >= 2 else { return 0 }
    
    let dispersions = clusters.map { dispersion(of: $0) }
    
    var dbiSum = 0.0
    
    for i in 0..<n {
      var maxRatio = Double.leastNonzeroMagnitude
      for j in 0..<n where i != j {
        let dij = centroidDistance(between: clusters[i], and: clusters[j])
        guard dij != 0 else { continue }
        
        let ratio = (dispersions[i] + dispersions[j]) / dij
        maxRatio = max(maxRatio, ratio)
      }
      dbiSum += maxRatio
    }
    
    return dbiSum / Double(n)
  }
}

fileprivate extension ClusteringAlgorithm {
  func dispersion(of cluster: Cluster<T>) -> Double {
    return totalDistance(to: cluster.centroid, in: cluster) / Double(cluster.size)
  }
  
  func centroidDistance(between cluster1: Cluster<T>, and cluster2: Cluster<T>) -> Double {
    return cluster1.centroid.distance(with: cluster2.centroid)
  }
  
  func totalDistance(to center: Location, in cluster: Cluster<T>) -> Double {
    return cluster.group.map(\.location).reduce(0) { $0 + $1.distance(with: center) }
  }
}
