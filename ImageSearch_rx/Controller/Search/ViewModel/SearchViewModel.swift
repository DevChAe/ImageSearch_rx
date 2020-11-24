//
//  SearchViewModel.swift
//  ImageSearch_rx
//
//  Created by ChAe on 2020/11/16.
//

import Foundation
import RxSwift
import RxCocoa

class SearchViewModel {
    var recentKeywordInfos = BehaviorRelay<[RecentKeywordInfo]>(value: [])
    var isShowResultView = BehaviorRelay<Bool>(value: false)
    
    weak var resultViewModel: ResultViewModel?
    
    init() {
        if let recentKeywordInfos = RecentKeywordInfo.loadRecentKeywords() {
            self.recentKeywordInfos.accept(recentKeywordInfos)
        }
    }
}

extension SearchViewModel {
    func searchImage(keyword: String) {
        if keyword.isEmpty == true {
            clearResultView()
        } else {
            isShowResultView.accept(true)
            resultViewModel?.requestImageSearch(keyword: keyword)
        }
    }
    
    func clearResultView() {
        guard isShowResultView.value == true else { return }
        // 결과창 초기화
        resultViewModel?.clear()
        // 결과창 숨기기
        isShowResultView.accept(false)
    }
}

// MARK: - Recent Keyword Methods
extension SearchViewModel {
    
    // 최근 검색어 추가 (키워드가 있는경우 현재 시간으로 업데이트후 정렬 시킴)
    func insertKeywords(keyword: String) {
        var values = recentKeywordInfos.value
        if let index = values.enumerated().filter({ $0.element.keyword == keyword }).map({ $0.offset }).first {
            values[index].date = Date()
            recentKeywordInfos.accept(values.sorted { $0.date > $1.date })
        } else {
            values.insert(RecentKeywordInfo(keyword: keyword, date: Date()), at: 0)
            recentKeywordInfos.accept(values)
        }
        
        RecentKeywordInfo.saveRecentKeywords(recentKeywordInfos.value)
    }
    
    func removeKeyword(index: Int) {
        var values = recentKeywordInfos.value
        values.remove(at: index)
        recentKeywordInfos.accept(values)
        RecentKeywordInfo.saveRecentKeywords(recentKeywordInfos.value)
    }
    
    func removeAllKeywords() {
        recentKeywordInfos.accept([])
    }
    
    func trimKeyword(_ keyword: String) -> String {
        return keyword.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
