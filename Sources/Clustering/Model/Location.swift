//
//  Location.swift
//  
//
//  Created by jung on 11/6/23.
//

import Foundation

public protocol ClusterData: Equatable {
	var location: Location { get }
}

public struct Location {
	// MARK: - Properties
	public let longitude: Double
	public let latitude: Double
	
	static let zero = Location(longitude: 0, latitude: 0)
	
	// MARK: - Initializers
	public init(longitude: Double, latitude: Double) {
		self.longitude = longitude
		self.latitude = latitude
	}
}

// MARK: - Methods
public extension Location {
	/// 유클리디안 거리를 구합니다.
	/// (x1 - x2)^2 + (y1 - y2)^2
	func euclideanDistance(with other: Location) -> Double {
		return Double(pow(self.latitude - other.latitude, 2)) + Double(pow(self.longitude - other.longitude, 2))
	}
	
	/// 거리를 구합니다.
	func distance(with other: Location) -> Double {
		return sqrt(euclideanDistance(with: other))
	}
}

// MARK: - Hashable
extension Location: Hashable {
	public static func == (lhs: Location, rhs: Location) -> Bool {
		return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
	}
	
	static func < (lhs: Location, rhs: Location) -> Bool {
		return (lhs.latitude, lhs.longitude) < (rhs.latitude, rhs.longitude)
	}
	
	static func + (lhs: Location, rhs: Location) -> Location {
		return Location(
			longitude: lhs.longitude + rhs.longitude,
			latitude: lhs.latitude + rhs.latitude
		)
	}
	
	static func - (lhs: Location, rhs: Location) -> Location {
		return Location(
			longitude: lhs.longitude - rhs.longitude,
			latitude: lhs.latitude - rhs.latitude
		)
	}
	
	static func += (lhs: inout Location, rhs: Location) {
		lhs = lhs + rhs
	}
	
	static func -= (lhs: inout Location, rhs: Location) {
		lhs = lhs - rhs
	}
	
	static func / (lhs: Location, count: Int) -> Location {
		return lhs / Double(count)
	}
	
	static func / (lhs: Location, count: Double) -> Location {
		return Location(
			longitude: lhs.longitude / count,
			latitude: lhs.latitude / count
		)
	}
}
