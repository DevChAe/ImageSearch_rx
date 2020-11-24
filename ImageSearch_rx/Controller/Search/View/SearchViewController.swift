//
//  SearchViewController.swift
//  ImageSearch
//
//  Created by ChAe on 12/11/2018.
//  Copyright © 2018 ChAe. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa
import RxAlamofire

// 검색 ViewController
class SearchViewController: KeyboardObserveViewController {
    @IBOutlet weak var resultContainerView: UIView!                 // 결과 컨테이너 뷰
    @IBOutlet weak var searchBar: UISearchBar!                      // 상단 서치 바
    @IBOutlet weak var tableView: UITableView!                      // 최근 검색어 테이블뷰
    private weak var resultViewController: ResultViewController!    // 결과 컨트롤러 객체 연결을 위한 변수
    
    private let viewModel = SearchViewModel()
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // SearchBar 키보드 닫힘을 위한 Notification Observer 등록
        NotificationCenter.default.rx
            .notification(Notification.Name("searchBarResignFirstResponder"))
            .subscribe(onNext: { _ in
                if self.searchBar.isFirstResponder {
                    self.searchBar.resignFirstResponder()
                }
            })
            .disposed(by: disposeBag)
        
        initUI()
        initSearchBar()
        initTableView()
    }
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "resultViewController" {
            // 결과 ViewController 객체 연결
            self.resultViewController = (segue.destination as! ResultViewController)
            viewModel.resultViewModel = resultViewController.viewModel
        }
    }
    
    // MARK: - Init
    
    private func initUI() {
        // 뷰모델의 isShowResultView 값 구독 및 처리
        viewModel.isShowResultView
            .subscribe(onNext: { isShow in
                self.resultContainerView.isHidden = !isShow
            })
            .disposed(by: disposeBag)
    }
    
    private func initSearchBar() {
        
        // 검색바 텍스트 입력 이벤트 처리 (rx)
        searchBar.rx.text.orEmpty
            .map({ text -> String in
                return self.viewModel.trimKeyword(text)
            })
            .filter({ text -> Bool in
                let isEmpty = text.isEmpty
                
                if isEmpty == true {
                    self.viewModel.clearResultView()
                }
                
                return true//!isEmpty
            })
            .debounce(.milliseconds(1000), scheduler: MainScheduler())
            .distinctUntilChanged({ (str1, str2) -> Bool in
                return str1 == str2 ? (str1 == "" ? false : true) : false
            })
            .subscribe(onNext: { keyword in
                self.viewModel.searchImage(keyword: keyword)
            })
            .disposed(by: disposeBag)
        
        // 검색바 검색 버튼 클릭 이벤트 처리 (rx)
        searchBar.rx.searchButtonClicked
            .subscribe(onNext: {
                if let keyword = self.searchBar.text {
                    let trimKeyword = self.viewModel.trimKeyword(keyword)
                    if trimKeyword.isEmpty == false {
                        self.viewModel.insertKeywords(keyword: trimKeyword)   // 최근 검색 키워드 등록
                    }
                }
                self.searchBar.resignFirstResponder()
            })
            .disposed(by: disposeBag)
    }
    
    private func initTableView() {
        self.tableView.tableFooterView = UIView()
        
        // 뷰모델의 recentKeywordInfos와 테이블 뷰 바인딩 (셀 구성) (rx)
        viewModel.recentKeywordInfos
            .subscribeOn(MainScheduler.instance)
            .bind(to: tableView.rx.items(cellIdentifier: "keywordCell")) { row, element, cell in
                let cell = cell as! KeywordTableViewCell
                cell.setup(keywordInfo: element, index: row)
                cell.delegate = self
            }
            .disposed(by: disposeBag)
        
        // 테이블 뷰 item 선택 이벤트 처리 (rx)
        tableView.rx.itemSelected
            .subscribe(onNext: { (indexPath) in
                self.tableView.deselectRow(at: indexPath, animated: true)
                let keyword = self.viewModel.recentKeywordInfos.value[indexPath.row].keyword
                self.viewModel.insertKeywords(keyword: keyword)   // 최근 검색 키워드 등록
                if self.searchBar.isFirstResponder == false {
                    self.viewModel.searchImage(keyword: keyword)
                }
                self.searchBar.text = keyword
                
                self.searchBar.resignFirstResponder()
            })
            .disposed(by: disposeBag)
        
        // 테이블뷰 스크롤 드래그 시작 이벤트 처리 (rx)
        tableView.rx
            .willBeginDragging
            .subscribe(onNext: {
                self.searchBar.resignFirstResponder()
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - UIButton Action Methods
    // 최근 검색어 모두 삭제 버튼 이벤트
    @IBAction func removeAllRecentKeywordsButtonAction(_ sender: Any) {
        viewModel.removeAllKeywords()
    }
}

extension SearchViewController: KeywordTableViewCellDelegate {
    // 최근 검색어 삭제 이벤트 (Cell Index)
    func keywordTableViewCell(_ cell: KeywordTableViewCell, removeButtonActionIndex: Int) {
        viewModel.removeKeyword(index: removeButtonActionIndex)
    }
}
