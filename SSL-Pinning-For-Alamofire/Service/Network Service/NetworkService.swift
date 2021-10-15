//
//  NetworkService.swift
//  Network-Call-Practice
//
//  Created by ADMIN on 19/06/21.
//  Copyright © 2021 Success Resource Pte Ltd. All rights reserved.
//

import Foundation
import CommonCrypto
import Alamofire

final class NetworkService {
    static let shared = NetworkService()
    private lazy var manager: Session = {
        let configuration: URLSessionConfiguration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        let pinningUrl = URL(string: Route.baseURL)?.host ?? ""
        let evaluators: [String: ServerTrustEvaluating] = [
            // pinningUrl: PinnedCertificatesTrustEvaluator(),
            pinningUrl: PublicKeysTrustEvaluator(),
            // pinningUrl: DefaultTrustEvaluator(),
            // pinningUrl: RevocationTrustEvaluator(),
        ]
        let serverTrustManager = ServerTrustManager(allHostsMustBeEvaluated: true, evaluators: evaluators)
        return Session(configuration: configuration, serverTrustManager: serverTrustManager)
    }()
    
    private init() {}
    
    // MARK:- Get User List
    func makeRequestForUserList(completion: @escaping (Result<[User], Error>) -> Void) {
        request(route: .user, type: [User].self,completion: completion)
    }
    
    // MARK:- Get User's Blog Post Details
    func makeRequestForUserBlogPost(parameter: [String: Any]?, completion: @escaping (Result<PostDetail, Error>) -> Void) {
        request(route: .posts, method: .post, parameter: parameter, type: PostDetail.self,completion: completion)
    }
    
    private func request<T: Codable>(route: Route,
                                     method: HTTPMethod = .get,
                                     parameter: [String: Any]? = nil,
                                     type: T.Type,
                                     completion: @escaping (Result<T, Error>) -> Void) {
        guard let request = createRequest(route: route, method: method, parameter: parameter) else {
            completion(.failure(ValidationError.unknownError))
            return
        }
        request.responseJSON { response in
            switch response.result {
            case .success(_):
                guard let data = response.data else {completion(.failure(ValidationError.unknownError)); return }
                guard let result = try? JSONDecoder().decode(type.self, from: data) else { return }
                completion(.success(result))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    /// This function helps to create DataRequest
    /// - Parameters:
    ///   - route: Backend resource path
    ///   - method: Type of HTTP Request
    ///   - parameter: Need to pass to backend
    /// - Returns: It returns DataRequest
    private func createRequest(route: Route,
                               method: HTTPMethod = .get,
                               parameter: [String: Any]? = nil) -> DataRequest? {
        let urlString = Route.baseURL + route.description
        guard let url = try? URL(string: urlString)?.asURL() else { return nil }
        let headers: HTTPHeaders = [ "Content-Type": "application/json" ]
        let request = manager.request( url, method: method, parameters: parameter, encoding: JSONEncoding.default, headers: headers)
        return request
    }
}
