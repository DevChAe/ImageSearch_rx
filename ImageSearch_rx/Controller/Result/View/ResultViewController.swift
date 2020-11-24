//
//  ResultViewController.swift
//  ImageSearch
//
//  Created by ChAe on 13/11/2018.
//  Copyright © 2018 ChAe. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

// 결과 페이지 ViewController (키보드 감지 ViewController 상속)
class ResultViewController: KeyboardObserveViewController {
    @IBOutlet weak var tableView: UITableView!              // 결과 테이블뷰
    @IBOutlet weak var indicator: UIActivityIndicatorView!  // 로딩 인디케이터

    var viewModel = ResultViewModel()       // 결과 뷰모델
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        initUI()
        initTableView()
    }
    
    // MARK: - Init
    
    private func initUI() {
        
        // 뷰모델의 isShowIndicator 값 구독 및 처리
        viewModel.isShowIndicator
            .asDriver()
            // Driver는 UI layer에서 좀 더 직관적으로 사용하도록 제공하는 unit.
            // Observable는 상황에 따라 MainScheduler와 BackgroundScheduler를 지정해줘야 하지만 Driver는 MainScheduler에서 사용.
            .drive(indicator.rx.isAnimating)
            .disposed(by: disposeBag)
        
    }
    
    private func initTableView() {
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = self.tableView.bounds.width
        self.setTableViewInset(keyboardHeight: 0)
        
        // 뷰모델 rowViewModels와 테이블 뷰 바인딩 (셀 구성) (rx)
        viewModel.rowViewModels
            .subscribeOn(MainScheduler.instance)    // MainScheduler에서 동작
            .bind(to: tableView.rx.items) { tableView, index, element in
                let identifier: String
                switch element {
                case is DocumentInfo:
                    identifier = "imageCell"
                default:
                    identifier = "descCell"
                }
                
                guard let cell = tableView.dequeueReusableCell(withIdentifier: identifier) else { return UITableViewCell() }
                
                cell.selectionStyle = .none
                
                if let cell = cell as? CellConfig {
                    cell.setup(rowViewModel: element)
                }
                
                return cell
            }
            .disposed(by: disposeBag)
        
        // 테이블 뷰 셀 display 이벤트 처리 (rx)
        tableView.rx
            .willDisplayCell
            .subscribe { cell, indexPath in
                self.viewModel.nextRequestImage(indexPath: indexPath)
            }
            .disposed(by: disposeBag)
        
        // 테이블뷰 스크롤 드래그 시작 이벤트 처리 (rx)
        tableView.rx
            .willBeginDragging
            .subscribe(onNext: {
                if self.viewModel.isShowKeyboard == true {
                    // ResultViewController는 SearchViewController 내 Container 구조이므로 직접 SearchBar 접근이 안됨 (다음 방법중 선택)
                    // 1. Delegate 구현
                    // 2. Notification Observer 등록 후 Post 호출
                    // 3. SearchViewController 객체를 weak 변수 (순환참조 문제 해소)로 연결하여 직접 호출
                    
                    // 키보드를 내릴수 있도록 Notification 통지
                    NotificationCenter.default.post(name: NSNotification.Name("searchBarResignFirstResponder"),
                                                    object: nil)
                    self.viewModel.isShowKeyboard = false
                }
            })
            .disposed(by: disposeBag)
        
        // 테이블뷰 row 선택 이벤트 처리 (rx)
        tableView.rx
            .modelSelected(DocumentInfo.self)
            .subscribe(onNext: { documentInfo in
                if let url = URL(string: documentInfo.doc_url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Kyeboard Show/Hide Methods
    override func keyboardWillShow(keyboardAtts: KeyboardObserveViewController.KeyboardAttributes) {
        UIView.animate(withDuration: keyboardAtts.duration,
                       delay: 0,
                       options: keyboardAtts.curve,
                       animations: {
                        self.setTableViewInset(keyboardHeight: keyboardAtts.height)
                       },
                       completion: nil)
        viewModel.isShowKeyboard = true
    }
    
    override func keyboardWillHide(keyboardAtts: KeyboardObserveViewController.KeyboardAttributes) {
        UIView.animate(withDuration: keyboardAtts.duration,
                       delay: 0,
                       options: keyboardAtts.curve,
                       animations: {
                        self.setTableViewInset(keyboardHeight: 0)
                       },
                       completion: nil)
        
        viewModel.isShowKeyboard = false
    }
    
    // 테이블뷰 스크롤 Inset, 컨텐츠 Inset 설정 (iPhone X, XR, XS, XS Max, iPad Pro 3rd 하단 영역 계산 포함)
    private func setTableViewInset(keyboardHeight: CGFloat) {
        var bottomSafeArea: CGFloat
        
        if #available(iOS 11.0, *) {
            bottomSafeArea = view.safeAreaInsets.bottom
        } else {
            bottomSafeArea = bottomLayoutGuide.length
        }
        
        let insets = UIEdgeInsets(top: 0,
                                  left: 0,
                                  bottom: keyboardHeight - (keyboardHeight > 0 ? bottomSafeArea : 0),
                                  right: 0)
        self.tableView.scrollIndicatorInsets = insets
        self.tableView.contentInset = insets
    }
}
