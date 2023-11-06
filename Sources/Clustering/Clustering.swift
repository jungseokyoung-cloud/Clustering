// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

public protocol ClusteringDelegate<DataType>: AnyObject {
	associatedtype DataType: ClusterData
	
	func didFinishClustering(with results: [ClusterResult<DataType>])
}

public final class Clustering<DataType: ClusterData> {
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
extension Clustering {
	/// KMeans를 실행합니다. `maxIteration`을 통해 최대 실행횟수를 지정할 수 있으며,
	/// `kRange`를 통해 k값의 범위를 지정할 수 있습니다.
	/// default는 `maxIteration = 20`, `kRange = (2..<9)`입니다
	public func run(
		data: [DataType],
		maxIterations: Int = 20,
		kRange: Range<Int> = (2..<9)
	) {
		queue.cancelAllOperations()
		
		let kMeansResults = kRange.map { k -> KMeans in
			let kMeans = KMeans(k: k, data: data, maxIterations: maxIterations)
			queue.addOperation(kMeans)
			return kMeans
		}
		
		queue.addBarrierBlock { [weak self] in
			guard
				let self,
				let optimalKmeans = self.getOptimalClustering(kMeansResults)
			else {
				return
			}
			DispatchQueue.main.async {
				let clusterResults = self.convertToClusterResults(optimalKmeans.clusters)
				self.delegate?.didFinishClustering(with: clusterResults)
			}
		}
	}
	
	/// Optimal한 Clustering을 리턴합니다..
	private func getOptimalClustering(_ kMeansResults: [KMeans<DataType>]) -> KMeans<DataType>? {
		kMeansResults.min(by: { $0.dbi < $1.dbi })
	}
	
	private func convertToClusterResults(_ clusters: [Cluster<DataType>]) -> [ClusterResult<DataType>] {
		clusters
			.filter { !$0.group.isEmpty }
			.map { ClusterResult(centriod: $0.centriod, group: $0.group.allValues()) }
	}
}
