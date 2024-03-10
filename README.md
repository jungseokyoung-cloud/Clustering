# Clustering
Swift KMeans Clustering

|클러스터링 이전|클러스터링 이후|영상|
|:---:|:---:|:---:|
|<img src="https://github.com/jungseokyoung-cloud/Clustering/assets/81402827/313923a5-c026-47c5-aec7-19cd4eba38d9" width="200"/>|<img src="https://github.com/jungseokyoung-cloud/Clustering/assets/81402827/eef60c27-a7a9-48aa-9554-5c494593c8e0" width="200"/>|<img src="https://github.com/WalkingDogWithFriends/GaeManDa/assets/81402827/27f8c028-e1bf-4654-8484-2bdae93c96b6" width="200"/>|

- 시간 복잡도: $O(KN)$
- K 값 검증: Silhoutte Coefficient
- 비동기 처리: `Operation Queue`를 통해 이전의 클러스터링 cancel후 클러스터링 진행

## Contents 
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Reference](#reference)

## Requirements
- iOS 13.0+

## Installation
- Swift Package Manager
``` swift
dependencies: [
    .package(url: "https://github.com/jungseokyoung-cloud/Clustering.git", .upToNextMajor(from: "1.0.0"))
]
```

## Usage
### Setting
Clustering할 데이터모델에 `ClusterData`를 채택해준 후, `Location`변수를 구현해줍니다. 

```Swift 
struct Person: ClusterData {
	let id: Int
	let name: String
	let location: Location
}
```

Clustering을 결과를 받아볼 객체에 `ClusteringDelegate`를 채택합니다.

이후 Clustering할 데이터의 타입을 명시해주고, Clustering의 `delegate`를 `self`로 지정합니다.
``` Swift
import Clustering

final class ViewModel: ClusteringDelegate {
	typealias DataType = Person

	let clustering = Clustering<Person>()
	
	...
	
	init() {
		...
		
		clustering.delegate = self
	}
}
```

### Run 
클러스터링은 `Clustering`객체의 `run(data:maxIterations:kRange:)`메서드를 호출해주면 됩니다. 

`run(data:maxIterations:kRange:)`메서드는 `OperationQueue`를 통해 이전에 수행하고 있던 클러스터링 취소하고, 클러스터링은 진행합니다.
```Swift
public func run(
	data: [DataType],
	maxIterations: Int = 20,
	kRange: Range<Int> = (2..<9)
)
```
```Swift
// ViewModel.swift
clustering.run(data: persons)
```

### Result
비동기적으로 수행된 클러스터링의 결과물은 `ClusteringDelegate`내의 `didFinishClustering(with:)`메서드를 통해 받을 수 있습니다. 

``` Swift
func didFinishClustering(with results: [ClusterResult<Person>]) {
	 presenter.drawClustering(results)
}
```

Clustering의 결과물은 다음과 같이 전달 됩니다. 
``` Swift 
public struct ClusterResult<T: ClusterData> {
	/// 클러스터의 Centroid 좌표
	public let centroid: Location
	
	/// 클러스터 내의 데이터
	public let group: [T]
}
```


## Reference
https://github.com/boostcamp-2020/Project17-B-Map
