//
//  RecentKeywordInfo.swift
//  ImageSearch_rx
//
//  Created by ChAe on 2020/11/16.
//

import Foundation

// 최근 검색어 데이터 모델
struct RecentKeywordInfo: Codable {
    var keyword: String
    var date: Date
    
    init(keyword: String, date: Date) {
        self.keyword = keyword
        self.date = date
    }
    
    private enum CodingKeys: String, CodingKey {
        case keyword, date
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.keyword = try values.decode(String.self, forKey: .keyword)
        
        let dateString = try values.decode(String.self, forKey: .date)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let datetime = dateFormatter.date(from: dateString) {
            self.date = datetime
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [CodingKeys.date],
                                                                    debugDescription: "시간 데이터 포맷이 맞지 않습니다."))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.keyword, forKey: .keyword)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let dateString = dateFormatter.string(from: self.date)
        
        try container.encode(dateString, forKey: .date)
    }
    
    // 최근 검색어 저장 (UserDefault)
    static func saveRecentKeywords(_ keywords: [RecentKeywordInfo]) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try! encoder.encode(keywords)
        
        let userDefaults = UserDefaults.standard
        userDefaults.set(data, forKey: "RecentKeywords")
        userDefaults.synchronize()
    }
    
    // 최근 검색어 로드 (UserDefault)
    static func loadRecentKeywords() -> [RecentKeywordInfo]? {
        let userDefaults = UserDefaults.standard
        
        if let data = userDefaults.object(forKey: "RecentKeywords") as? Data {
            do {
                let recentKeywords = try JSONDecoder().decode([RecentKeywordInfo].self, from: data)
                return recentKeywords
            } catch {
                print(error)
                return nil
            }
        } else {
            return nil
        }
    }
}
