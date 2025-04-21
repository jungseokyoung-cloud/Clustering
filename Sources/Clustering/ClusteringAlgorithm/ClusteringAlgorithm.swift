//
//  File.swift
//  Clustering
//
//  Created by jung on 4/21/25.
//

import Foundation

public enum ValidationMethodType {
  case silhouette
  case dbi
}

class ClusteringAlgorithm<T: ClusterData>: Operation {
  /// 최대 클러스터의 개수.
  let k: Int
  let data: [T]
  
  /// 클러스터링의 최대 Iteration
  let maxIterations: Int
  private let validationMethodType: ValidationMethodType
  
  var score: Double = 0
  var clusters = [Cluster<T>]()
  
  init(
    k: Int,
    data: [T],
    maxIterations: Int,
    validationType: ValidationMethodType
  ) {
    self.k = k
    self.data = data
    self.maxIterations = maxIterations
    self.validationMethodType = validationType
    super.init()
  }
  
  // MARK: - main Method
  override func main() {
    guard !isCancelled else { return }
    
    run()
    run(operations: setScore)
  }
  
  func run() { }
  
  func run(operations: (() -> Void)...) {
    guard !isCancelled else { return }
    
    operations.forEach { $0() }
  }
  
  func setScore() { }
}
