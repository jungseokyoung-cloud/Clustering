//
//  KMedoids.swift
//  Clustering
//
//  Created by jung on 4/21/25.
//

import Foundation

/// Medoid와의 근접성 관련 정보
fileprivate struct MedoidProximity {
  let nearestIndex: Int
  let nearestDistance: Double
  let secondDistance: Double
}

final class KMedoids<T: ClusterData>: ClusteringAlgorithm<T> {
  var medoids: [Location] { clusters.map { $0.centroid } }
  private var isChanged: Bool = false
  
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
private extension KMedoids {
  func initClusters() {
    let initMedoids = pamBUILDMedoids(count: k, from: data)
    
    self.clusters = generateClusters(medoids: initMedoids)
    let nearestInices = data.map { nearestMedoidIndex(of: $0) }
    classifyDataToNearestCluster(nearestClusterIndices: nearestInices)
   }
  
  /// 랜덤하게 `k`만큼 medoids를 지정합니다. `O(N)`
  func randomMedoids(count: Int, from data: [T]) -> [Location] {
    return data.shuffled().prefix(count).map(\.location)
  }
  
  /// PAM의 BUILD Process를 통해 Medoids를 초기화합니다. `O(kN^2)`
  func pamBUILDMedoids(count: Int, from data: [T]) -> [Location] {
    let n = data.count
    var medoidIndices: [Int] = []
    var nearstDistances = Array(repeating: Double.infinity, count: n)
    var assignments = Array(repeating: -1, count: n)
    
    // Step 1: TD가 가장 낮은 데이터로 첫번째 memoid를 결정 O(N^2)
    let m1Index = data.map { totalDeviation(of: $0, within: data) }.enumerated()
      .min { $0.1 < $1.1 }?.0
    
    guard let m1Index else { return [] }
    medoidIndices.append(m1Index)
    
    // Step 2: nearest distance를 초기화 O(N)
    for xo in 0..<n {
      let d = data[m1Index].location.distance(with: data[xo].location)
      nearstDistances[xo] = d
      assignments[xo] = m1Index
    }
    
    // Step 3: 나머지 k-1개의 memoid를 선정 O(N^2 K)
    while medoidIndices.count < k {
      var bestDelta = 0.0
      var bestCandidateIndex = -1
      
      for xc in 0..<n where !medoidIndices.contains(xc) {
        let deltas = data.enumerated().map { data[xc].location.distance(with: $0.1.location) - nearstDistances[$0.0] }
        let deltaTD = deltas.filter { $0 < 0 }.reduce(0, +)
        
        guard deltaTD < bestDelta else { continue }
        bestDelta = deltaTD
        bestCandidateIndex = xc
      }
      
      medoidIndices.append(bestCandidateIndex)
      guard bestCandidateIndex >= 0 else { break }
      
      data
        .map { data[bestCandidateIndex].location.distance(with: $0.location) }
        .enumerated()
        .filter { $0.element < nearstDistances[$0.offset] }
        .forEach {
          nearstDistances[$0.offset] = $0.element
          assignments[$0.offset] = bestCandidateIndex
        }
    }
    
    return medoidIndices.map { data[$0].location }
  }
}


// MARK: - Run Methods
private extension KMedoids {
  func runIteration(at iteration: inout Int) {
    run(operations: updateClusters)
    iteration += 1
  }
}

// MARK: - Update Methods
private extension KMedoids {
  func updateClusters() {
    let (memoids, nearestIndices) = updatedMedoids()
    guard isChanged else { return }
    
    self.clusters = generateClusters(medoids: memoids)
    classifyDataToNearestCluster(nearestClusterIndices: nearestIndices)
  }
  
  func updatedMedoids() -> ([Location], [Int]) {
    var updatedMedoids = self.medoids
    var medoidProximities = precomputedProximities(medoids: updatedMedoids)
    isChanged = false
    let epsilon = 1e-6
    
    var isImproved = true
    repeat {
      isImproved = false
      let candidates = data.filter { datum in !updatedMedoids.contains(where: { datum.location == $0 }) }
      
      for candidate in candidates {
        let newMemoidIndex = configureTotalDeltas(for: candidate, proximities: medoidProximities)
          .enumerated()
          .first { $0.1 < 0 }?.offset

        guard let newMemoidIndex = newMemoidIndex else { continue }
        updatedMedoids[newMemoidIndex] = candidate.location
        isChanged = true
        isImproved = true
        medoidProximities = precomputedProximities(medoids: updatedMedoids)
        break
      }
    } while isImproved
    
    return (updatedMedoids, medoidProximities.map { $0.nearestIndex })
  }
  
  func configureTotalDeltas(for candidate: T, proximities: [MedoidProximity]) -> [Double] {
    var removalLoss = configureRemovalLoss(from: proximities)
    var sharedGain = 0.0
    let distancesToCandiate = data.map(\.location).map { candidate.location.distance(with: $0) }
    
    zip(distancesToCandiate, proximities).forEach { (distanceToCandidate, proximity) in
      if distanceToCandidate < proximity.nearestDistance {
        sharedGain += distanceToCandidate - proximity.nearestDistance
        removalLoss[proximity.nearestIndex] += proximity.nearestDistance - proximity.secondDistance
      } else if distanceToCandidate < proximity.secondDistance {
        removalLoss[proximity.nearestIndex] += distanceToCandidate - proximity.secondDistance
      }
    }
    
    return removalLoss.map { $0 + sharedGain }
  }
  
  func precomputedProximities(medoids: [Location]) -> [MedoidProximity] {
    return data.compactMap { datum -> MedoidProximity? in
      let distances = medoids.map { $0.distance(with: datum.location) }
      let sortedDistances = distances.enumerated().sorted { $0.1 < $1.1 }
      
      guard let first = sortedDistances.first else { return nil }
      let secondDistance = sortedDistances.count >= 2 ? sortedDistances[1].element : first.element
      return .init(nearestIndex: first.offset, nearestDistance: first.element, secondDistance: secondDistance)
    }
  }
}

// MARK: - Util Methods
private extension KMedoids {
  /// 각 data들을 가장 가까운 클러스터에 `insert`합니다.
  func classifyDataToNearestCluster(nearestClusterIndices: [Int]) {
    zip(data, nearestClusterIndices).forEach { (datum, index) in
      clusters[index].group.append(datum)
    }
  }

  func nearestMedoidIndex(of data: T) -> Int {
    return medoids.map { $0.distance(with: data.location) }.enumerated()
      .min { $0.element < $1.element }?.offset ?? 0
  }
  
  func totalDeviation(of point: T, within group: [T]) -> Double {
    return group.map(\.location).reduce(0.0) { $0 + point.location.distance(with: $1) }
  }
  
  /// Cluster를 생성합니다.
  func generateClusters(medoids: [Location]) -> [Cluster<T>] {
    return medoids.map { Cluster(centroid: $0) }
  }

  func configureRemovalLoss(from medoidProximities: [MedoidProximity]) -> [Double] {
    var removalLoss = Array<Double>(repeating: 0, count: clusters.count)
    medoidProximities.forEach {
      removalLoss[$0.nearestIndex] += $0.secondDistance - $0.nearestDistance
    }
    return removalLoss
  }
}
