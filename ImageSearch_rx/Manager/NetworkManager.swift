//
//  NetworkManager.swift
//  ImageSearch
//
//  Created by ChAe on 12/11/2018.
//  Copyright © 2018 ChAe. All rights reserved.
//

import UIKit
import Alamofire
import RxAlamofire
import RxSwift

// 네트워크 에러 정보
enum NetworkError: LocalizedError {
    case alreadyRequest
    case nonData
    case nonKakaoApiKey
    case ignore
    
    var localizedDescription: String {
        switch self {
        case .alreadyRequest:
            return "이미 요청중입니다."
        case .nonData:
            return "데이터가 존재하지 않습니다."
        case .nonKakaoApiKey:
            return "카카오 API 키를 입력하세요."
        case .ignore:
            return "요청 무시"
        }
    }
    
    var errorDescription: String? { return localizedDescription }
}

// 이미지 검색 요청 정보
struct ImageSearchRequestInfo {
    enum SortType: String {
        case accuracy = "accuracy"
        case recency = "recency"
    }
    
    var keyword: String
    var sort: SortType = .accuracy
    var page: Int = 1
    var size: Int = 10
    
    init(keyword: String) {
        self.keyword = keyword
    }
    
    init(keyword: String, page: Int) {
        self.keyword = keyword
        self.page = page
    }
}

class NetworkManager {
    static let shared = NetworkManager()
    
    private let kakaoImageSearchUrl = "https://dapi.kakao.com/v2/search/image"  // 카카오 이미지 검색 API URL
    private let kakaoRestApiKey = ""            // 카카오 API Key
    
    // API 통신 SessionManager 타임아웃 설정
    private lazy var manager: Session = {
        let configuration = URLSessionConfiguration.default
        configuration.headers = .default
        configuration.timeoutIntervalForRequest = 5     // 데이터 수신 간격 5초
        configuration.timeoutIntervalForResource = 10   // 전체 10초
        return Session(configuration: configuration)
    }()
    
    private init() { }
    
    // MARK: - Cancel Methods
    // 카카오 이미지 검색 중단
    func cancelKakaoImageSearch() {
        self.manager.session.getTasksWithCompletionHandler { (dataTask, uploadTask, downloadTask) in
            dataTask.forEach { $0.cancel() }
            uploadTask.forEach { $0.cancel() }
            downloadTask.forEach { $0.cancel() }
        }
    }
    
    // MARK: - Request Methods
    
    func requestKakaoImageSearchAPI(_ info: ImageSearchRequestInfo) -> Observable<(ImageSearchInfo, ImageSearchRequestInfo)> {
        guard !self.kakaoRestApiKey.isEmpty else {
            return Observable.error(NetworkError.nonKakaoApiKey)
        }
        
        print("query = \(info.keyword), page = \(info.page)")
        
        return manager.rx
            .responseDecodable(.get,
                               self.kakaoImageSearchUrl,
                               parameters: ["query": info.keyword,
                                            "sort": info.sort,
                                            "page": info.page,
                                            "size": info.size],
                               encoding: URLEncoding.default,
                               headers: ["Authorization": "KakaoAK \(self.kakaoRestApiKey)"])
            .map { (response, imageSearchInfo) in
                return (imageSearchInfo, info)
            }
    }
}
