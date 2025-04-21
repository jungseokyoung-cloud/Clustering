// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

public protocol ClusteringDelegate<DataType>: AnyObject {
  associatedtype DataType: ClusterData
  
  func didFinishClustering(with result: ClusteringResult<DataType>)
}

public final class Clustering<DataType: ClusterData> {
  public enum ClusteringMode {
    /// 클러스터의 평균값을 가지고, 클러스터링 진행합니다. distance는 유클리디안으로 고정됩니다. 시간 복잡도는 `O(IKN)`
    case kMeans
    /// 커스텀 distance를 지정할 수 있으며, 실제값을 가지고 Total Dissimalrity를 최소화시키는 방향으로 업데이트를 진행합니다. 시간 복잡도는 `O(IKN^2)`
    case kMemoids
  }
  
  // MARK: - Properties
  public weak var delegate: (any ClusteringDelegate<DataType>)?
  
  private let queue: OperationQueue = {
    let queue = OperationQueue()
    queue.underlyingQueue = .global(qos: .userInteractive)
    queue.qualityOfService = .userInteractive
    
    return queue
  }()
  
  // MARK: - Intializer
  public init() { }
}

// MARK: - Run Methods
public extension Clustering {
  /// KMeans를 실행합니다. `maxIteration`을 통해 최대 실행횟수를 지정할 수 있으며,
  /// `kRange`를 통해 k값의 범위를 지정할 수 있습니다.
  /// default는 `maxIteration = 20`, `kRange = (2..<9)`입니다
  func run(
    data: [DataType],
    mode: ClusteringMode,
    validationType: ValidationMethodType,
    maxIterations: Int = 20,
    kRange: Range<Int> = (2..<9)
  ) {
    queue.cancelAllOperations()
    let clusteringResults = kRange
      .filter { $0 <= data.count && $0 >= 2 }
      .map { k -> ClusteringAlgorithm in
        let clustering: ClusteringAlgorithm<DataType>
        
        switch mode {
          case .kMeans:
            clustering = KMeans(k: k, data: data, maxIterations: maxIterations, validationType: validationType)
          case .kMemoids:
            clustering = KMedoids(k: k, data: data, maxIterations: maxIterations, validationType: validationType)
        }
        return clustering
      }
    queue.waitUntilAllOperationsAreFinished()
    guard let optimalClustering = getOptimalClustering(clusteringResults, validationType: validationType) else { return }
    let clusterResults = convertToClusteringResult(optimalClustering)
    DispatchQueue.main.async { [weak self] in
      self?.delegate?.didFinishClustering(with: clusterResults)
    }
  }
}

// MARK: - Private Methods
private extension Clustering {
  /// Optimal한 Clustering을 리턴합니다..
  func getOptimalClustering(_ results: [ClusteringAlgorithm<DataType>], validationType: ValidationMethodType) -> ClusteringAlgorithm<DataType>? {
    switch validationType {
      case .dbi:
        return results.min { $0.score < $1.score }
      case .silhouette:
        return results.max { $0.score < $1.score }
    }
  }
  
  func convertToClusteringResult(_ optimalClustering: ClusteringAlgorithm<DataType>) -> ClusteringResult<DataType> {
    let clusters = optimalClustering.clusters
      .filter { !$0.group.isEmpty }
      .map { ClusterResult(centriod: $0.centroid, group: $0.group) }
    
    return .init(score: optimalClustering.score, clusters: clusters)
  }
}
