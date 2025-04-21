# Clustering
Swift 환경에서 `KMeans`, `kMedoids` 클러스터링 알고리즘을 구현한 SPM 라이브러리입니다.<br>
클러스터링 알고리즘 선택, 최적 K 자동 탐색, 다양한 클러스터 평가 지표 제공 등 다양한 기능을 지원합니다.


|클러스터링 이전|클러스터링 이후|영상|
|:---:|:---:|:---:|
|<img src="https://github.com/jungseokyoung-cloud/Clustering/assets/81402827/313923a5-c026-47c5-aec7-19cd4eba38d9" width="200"/>|<img src="https://github.com/jungseokyoung-cloud/Clustering/assets/81402827/eef60c27-a7a9-48aa-9554-5c494593c8e0" width="200"/>|<img src="https://github.com/WalkingDogWithFriends/GaeManDa/assets/81402827/27f8c028-e1bf-4654-8484-2bdae93c96b6" width="200"/>|
> 영상에서는 KMeans로 진행

## 📋 Contents 
- [🔧 Features](#-features)
- [📦 Requirements](#-requirements)
- [📲 Installation](#-installation)
- [🚀 Usage](#-usage)
- [📚 Reference](#-reference)

## 🔧 Features
### 다양한 클러스터링 알고리즘 제공 
- KMeans: 평균 기반의, **빠른 연산** 
  - 시간복잡도: $O(ikn)$
- KMedoids: 대표값 기반으로 **이상치에 강함**. 
  - 시간복잡도: $O(i(n-k)^2)$
  - 기존 PAM에 비해 *"Fast and Eager k-Medoids Clustering"* 논문의 FasterPAM 적용으로 $O(k)$배 성능 향상
> *k = 클러스터 수, n = 데이터 수, i = 반복 횟수*

### 다양한 클러스터링 평가 지표 제공 
- Silhouette Coefficient: 군집 응집도/분리도  $O(kn^2)$
- Davies-Bouldin Index: 클러스터 간 유사도  $O(k^2)$

### 자동 K 탐색 지원
- `run`메서드의 파라미터인 `kRange`에 범위를 입력하면, 해당 범위 내 최적의 K값을 자동으로 탐색

### 비동기 처리 기반
- `OperationQueue` 기반으로 각 K 값에 대해 클러스터링 동시 처리  
- 새 요청이 들어올 경우, 이전 연산 자동 취소 

## 📦 Requirements
- iOS 13.0+

## 📲 Installation
### Swift Package Manager
``` swift
dependencies: [
    .package(url: "https://github.com/jungseokyoung-cloud/Clustering.git", .upToNextMajor(from: "2.0.0"))
]
```

## 🚀 Usage
### 클러스터링 데이터 모델 정의
Clustering할 데이터모델에 `ClusterData` 프로토콜을 채택하고 `location`변수를 정의해줍니다. 

```Swift 
struct Person: ClusterData {
	let id: Int
	let name: String
	let location: Location
}
```

### 클러스터링 준비
`Clustering<DataType>` 객체를 생성합니다. 
만약, 결과를 받아보고 싶을 경우 `ClusteringDelegate`를 채택합니다.
``` Swift
import Clustering

final class ViewModel: ClusteringDelegate {
  // Clustering할 데이터의 타입을 명시
	typealias DataType = Person

	let clustering = Clustering<Person>()
	
	...
	
	init() {
		...
		
		clustering.delegate = self
	}
}
```

### 클러스터링 실행 
```Swift
clustering.run(
  data: persons,           // 클러스터링 대상 데이터
  mode: .kMeans,           // 클러스터링 알고리즘
  validationType: .dbi,    // 평가 지표
  maxIterations: 20,       // 최대 반복 횟수
  kRange: 2..<9            // 탐색한 K 범위
)
```

### 클러스터링 결과 처리 
클러스터링이 완료되면, `ClusteringDelegate`의 `didFinishClustering`을 통해 결과가 전달됩니다.<br>
해당 메서드는 Main Thread에서 호출됨을 보장되므로, UI업데이트에 안전하게 사용할 수 있습니다.
```swift 
func didFinishClustering(with result: ClusterResults<Person>) {
  presenter.drawClustering(result.clusters)
}
```

### 결과 구조
``` swift 
/// optimal한 클러스터링의 결과물
public struct ClusteringResult<T: ClusterData> {
  /// `run`메서드에서 지정한 validationMethodType의 점수
  public let score: Double
  /// 클러스터링 결과물
  public let clusters: [ClusterResult<T>]
}

public struct ClusterResult<T: ClusterData> {
  /// 클러스터의 Centroid 좌표
  public let centroid: Location
  
  /// 클러스터 내의 데이터
  public let group: [T]
}
```


## 📚 Reference
- [Faster k-Medoids Clustering - Schubert & Rousseeuw (2020)](https://arxiv.org/abs/2008.05171)
