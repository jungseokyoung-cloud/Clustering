//
//  ClusterResult.swift
//
//
//  Created by jung on 11/6/23.
//

import Foundation

public struct ClusterResult<T: ClusterData> {
	public let centriod: Location
	public let group: [T]
}
