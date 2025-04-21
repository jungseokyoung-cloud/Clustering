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
  /// 클러스터링을 실행하는 메서드입니다. KMeans 또는 KMedoids 알고리즘을 이용하여
  /// 주어진 데이터에 대해 최적의 클러스터링 결과를 찾습니다. 클러스터 개수 k의 범위를 지정하면,
  /// 각 k값에 대해 클러스터링을 수행한 뒤 평가 지표(Validation Method)를 기준으로 최적의 결과를 선택합니다.
  ///
  /// - Parameters:
  ///   - data: 클러스터링할 입력 데이터 배열입니다.
  ///   - mode: 사용할 클러스터링 알고리즘입니다.
  ///     - .kMeans: 평균 기반 클러스터링, O(IKN)
  ///     - .kMemoids: 대표값 기반 클러스터링, O(IKN²)
  ///   - validationType: 최적의 클러스터링 결과를 선택할 때 사용할 평가 지표입니다.
  ///     - .dbi: Davies-Bouldin Index (낮을수록 좋음) O(K²)
  ///     - .silhouette: Silhouette Score (높을수록 좋음) O(KN²)
  ///   - maxIterations: 클러스터링 알고리즘의 최대 반복 횟수입니다. (기본값: 20)
  ///   - kRange: 클러스터 개수 k의 탐색 범위입니다. (기본값: 2..<9)
  ///
  /// - Description:
  ///   1. 새로운 작업이 들어오면, 기존 작업(OperationQueue)을 모두 취소합니다.
  ///   2. 주어진 kRange에 대해 각각 KMeans 또는 KMedoids 인스턴스를 생성하고 클러스터링을 수행합니다.
  ///   3. 모든 결과 중 평가 지표(validationType)를 기준으로 가장 적합한 결과를 선택합니다.
  ///   4. 선택된 클러스터링 결과를 ClusteringResult 타입으로 변환한 후, 메인 스레드에서 delegate?.didFinishClustering(...) 콜백을 호출합니다.
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
