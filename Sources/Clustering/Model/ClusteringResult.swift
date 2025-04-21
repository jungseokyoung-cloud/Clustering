//
//  ClusterResult.swift
//
//
//  Created by jung on 11/6/23.
//

/// optimal한 클러스터링의 결과물을 반환합니다.
public struct ClusteringResult<T: ClusterData> {
  /// `run`메서드에서 지정한 validationMethodType의 점수입니다.
  public let score: Double
  /// 클러스터링 결과물을 반환합니다.
  public let clusters: [ClusterResult<T>]
}

public struct ClusterResult<T: ClusterData> {
  public let centriod: Location
  public let group: [T]
}
