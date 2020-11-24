//
//  ResultViewModel.swift
//  ImageSearch_rx
//
//  Created by ChAe on 2020/11/16.
//

import Foundation
import RxSwift
import RxCocoa

class ResultViewModel {
    
    var rowViewModels = BehaviorRelay<[RowViewModel]>(value: [])
    
    private var imageSearchRequestInfo = BehaviorSubject<ImageSearchRequestInfo?>(value: nil)   // 이미지 요청 정보
    private var isExistMore: Bool = false   // 결과에 따른 추가 Page 존재 유무
    
    var isShowKeyboard: Bool = false    // 키보드 Show/Hide 여부
    
    var isShowIndicator = BehaviorRelay<Bool>(value: false)
    
    private var disposeBag = DisposeBag()
    
    init() {
        
        imageSearchRequestInfo
            .flatMapLatest { info -> Observable<(ImageSearchInfo, ImageSearchRequestInfo)> in
                if let info = info {
                    self.isShowIndicator.accept(true)
                    return NetworkManager.shared.requestKakaoImageSearchAPI(info)
                        // catchError : Error가 발생했을 때 Error를 무시하고 클로저의 반환값(Observable<E>)을 반환한다.
                        .catchError { error -> Observable<(ImageSearchInfo, ImageSearchRequestInfo)> in
                            let value = [DescriptionInfo(desc: "데이터 통신에 실패하였습니다.")]
                            self.rowViewModels.accept(value)
                            self.isShowIndicator.accept(false)
                            self.isExistMore = false
                            return Observable.empty()
                    }
                }
                
                // Observable.empty() : 아무런 아이템을 발행하지 않고, 완료를 발행하는 Observable을 생성한다.
                return Observable.empty()
            }
            .subscribe(onNext: { result, info in
                self.isExistMore = !result.meta.is_end
                
                if result.meta.total_count > 0 && result.documents.count > 0 {
                    if info.page > 1 {
                        var value = self.rowViewModels.value
                        value.append(contentsOf: result.documents)
                        self.rowViewModels.accept(value)
                    } else {
                        self.rowViewModels.accept(result.documents)
                    }
                    
                } else {
                    let value = [DescriptionInfo(keyword: info.keyword,
                                                 desc: "에 해당하는 이미지가 존재하지 않습니다.")]
                    self.rowViewModels.accept(value)
                }
                self.isShowIndicator.accept(false)
            })
            .disposed(by: disposeBag)
        
    }
}

extension ResultViewModel {
    
    // 테이블뷰 초기화 (SearchBar 텍스트가 비어 있을경우 호출)
    func clear() {
        rowViewModels.accept([])
    }
    
    // MARK: - Search Methods
    // 이미지 검색 요청
    func requestImageSearch(keyword: String, page: Int = 1) {
        let info = ImageSearchRequestInfo(keyword: keyword, page: page)
        imageSearchRequestInfo.onNext(info)
    }
    
    func nextRequestImage(indexPath: IndexPath) {
        if let info = try? imageSearchRequestInfo.value(),
           self.isExistMore == true && indexPath.row == rowViewModels.value.count - 1 {
            
            // 키워드는 같고 다음페이지를 요청
            let newInfo = ImageSearchRequestInfo(keyword: info.keyword, page: info.page + 1)
            imageSearchRequestInfo.onNext(newInfo)
        }
    }
}
