//
//  OAuthManager.swift
//  OAuthDemo
//
//  Created by Admin on 28/06/2017.
//  Copyright © 2017 Admin. All rights reserved.
//

import Foundation

protocol OAuthManagerDelegate: AnyObject {
    
    func firstRequestSucceeded()
    func firstRequestFailed()
    func secondRequestSucceeded()
    func secondRequestFailed()
}


enum OAuthStatus {
    
    case none,
    performingFirstRequest,
    firstRequestSucceeded,
    firstRequestFailed,
    performingSecondRequest,
    secondRequestSucceeded,
    secondRequestFailed
}


class OAuthManager {
    // MARK: internal variables
    weak var delegate:  OAuthManagerDelegate?
    var status: OAuthStatus
    
    var consumerKey: String?
    var consumerSecret: String?
    
    var requestURL: String?
    var authorizationURL: String?
    var accessURL: String?
    
    private(set) var tokenizedAuthorizationURL: String?
    private(set) var accessToken: String = ""
    private(set) var accessTokenSecret: String = ""
    
    // MARK: initializer
    init() {
        status = OAuthStatus.none
    }
    
    // MARK: internal methods
    func requestFirstPair() {
        reset()
        status = .performingFirstRequest
        requestWithAuthorizationHeader(urlString: requestURL)
    }
    
    func requestAccessPair() {
        status = .performingSecondRequest;
        requestWithAuthorizationHeader(urlString: accessURL)
    }
    
    func requestAccessPair(verifier: String) {
        self.verifier = verifier
        requestAccessPair()
    }
    
    // MARK: private variables
    private var token: String = ""
    private var tokenSecret: String = ""
    private var verifier: String = ""
    private var connectionInProcess: Bool?
    
    // MARK: state handling
    private func reset() {
        token = ""
        tokenSecret = ""
        accessToken = ""
        accessTokenSecret = ""
        verifier = ""
    }
    
    // MARK: passing OAuth protocol params via Authorization header
    private func requestWithAuthorizationHeader(urlString: String?) {
        if (urlString ?? "").isEmpty {
            return
        }
        guard let url = URL(string: urlString!) else {
            handleError()
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(signedHeader(urlString: urlString!), forHTTPHeaderField: "Authorization")
        
        connectionInProcess = true
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request, completionHandler: {
            [weak self](data, response, error) -> Void in
            guard let strongSelf = self else {
                return
            }
            strongSelf.connectionInProcess = false
            let httpResponse = response as! HTTPURLResponse
            if (error == nil) && (httpResponse.statusCode == 200) {
                strongSelf.handleResponseData(data!)
            }
            else {
                strongSelf.handleError()
            }
        })
        dataTask.resume()
    }
    
    private func signedHeader(urlString: String!) -> String! {
        let params: Dictionary<String, String>! = oauthParametersWithoutSignature()
        var csvParamsString: String! = csvParametersStringWithoutSignature(params: params)
        let urlEncodedParamsString: String! = urlEncodedParametersStringWithoutSignature(params: params)
        let baseString: String! = self.baseString(urlString: urlString, paramsString:urlEncodedParamsString)
        let signature: String! = self.signature(baseString: baseString)
        let escapedSignature: String! = escapeEncode(signature)

        let lastPair: String! = ", oauth_signature=\"" + escapedSignature + "\""
        csvParamsString = csvParamsString + lastPair
        let header: String! = "OAuth " + csvParamsString
    
        return header
    }
    
    // MARK: nonce and timestamp
    private func nonce() -> String! {
        let uuid = UUID().uuidString
        let index = uuid.index(uuid.startIndex, offsetBy: 5)
        return uuid.substring(to: index).replacingOccurrences(of: "-", with: "").lowercased()
    }
    
    private func timestamp() -> String! {
        let date = Date()
        let timeInterval = date.timeIntervalSince1970
        return "\(timeInterval)"
    }
    
    //MARK: request parameters handling
    private func oauthParametersWithoutSignature() -> Dictionary<String, String>! {
        let oauthTimestamp: String = timestamp()
        let oauthNonce: String = nonce()
        let oauthConsumerKey : String = consumerKey!
        let oauthSignatureMethod: String = "HMAC-SHA1"
        let oauthVersion: String = "1.0a"
        let requestToken: String = token
        
        var params = ["oauth_consumer_key": oauthConsumerKey,
                      "oauth_nonce": oauthNonce,
                      "oauth_signature_method": oauthSignatureMethod,
                      "oauth_timestamp": oauthTimestamp,
                      "oauth_version": oauthVersion,
                      "oauth_token": requestToken]
        
        if (status == .performingSecondRequest && !verifier.isEmpty) {
            params["oauth_verifier"] = verifier
        }
        return params
    }
    
    private func csvParametersStringWithoutSignature(params: Dictionary<String, String>) -> String! {
        var parameterPairs = Array<String>()
        for (key, value)  in params {
            let encodedValue = escapeEncode(value)
            let aPair = key + "=\"" + encodedValue! + "\""
            parameterPairs.append(aPair)
        }
        let string = parameterPairs.joined(separator: ", ")
        
        return string;
    }
    
    private func urlEncodedParametersStringWithoutSignature(params: Dictionary<String, String>) -> String! {
        var parameterPairs = Array<String>()
        
        for (name, value) in params {
            let encodedValue = escapeEncode(value)
            let aPair = name + "=" + encodedValue!
            parameterPairs.append(aPair)
        }
        let sortedArray = parameterPairs.sorted()
        let string = sortedArray.joined(separator: "&")

        return string;
    }
    
    private func baseString(urlString: String!, paramsString: String!) -> String! {
        let baseString = "POST&" + escapeEncode(urlString) + "&" + escapeEncode(paramsString)
        return baseString;
    }
    
    // MARK: encoding and signing
    private func signature(baseString: String!) -> String! {
        let consumerSecretPart = escapeEncode(consumerSecret!)
        let tokenSecretPart = escapeEncode(tokenSecret)
        let secretString = consumerSecretPart! + "&" + tokenSecretPart!
        var secretData = secretString.data(using: .utf8)
        let textData = baseString.data(using: .utf8)
        
        var result = [CUnsignedChar](repeating: 0, count: 20)
        var secretDataPtr: UnsafeMutablePointer<CUnsignedChar>? = nil
        secretData?.withUnsafeBytes { (ptr: UnsafePointer<CUnsignedChar>) in
            secretDataPtr = UnsafeMutablePointer(mutating: ptr)
        }
        
        hmac_sha1([CUnsignedChar](textData!),
                  textData!.count,
                  secretDataPtr,
                  secretData!.count,
                  &result);
        
        var base64Result = [CChar](repeating: 0, count: 32)
        var resultLength: Int = 32

        Base64EncodeData(result,
                         20,
                         &base64Result,
                         &resultLength);
        
        let data = Data(bytes: base64Result, count: resultLength)
        let string = String(data: data, encoding: String.Encoding.utf8)
        
        return string
    }
    
    private func escapeEncode(_ string: String) -> String! {
        var charSet = CharacterSet(charactersIn: "!*'\"();:@&=+$,/?%#[]% ")
        charSet = charSet.inverted
        let string = string.addingPercentEncoding(withAllowedCharacters: charSet)
        
        return string
    }
    
    //MARK: response handling
    private func handleError() {
        if status == OAuthStatus.performingFirstRequest {
            status = OAuthStatus.firstRequestFailed
            delegate?.firstRequestFailed()
        }
        else if status == OAuthStatus.performingSecondRequest {
            status = OAuthStatus.secondRequestFailed
            delegate?.secondRequestFailed()
        }
        reset()
    }
    
    private func handleResponseData(_ data: Data) {
        let responseString = String(data: data, encoding: String.Encoding.utf8)
        let responsePair = parse(responseString!)
        if status == OAuthStatus.performingFirstRequest {
            firstRequestCompeted(responsePair: responsePair)
        }
        else if status == OAuthStatus.performingSecondRequest {
            secondRequestCompleted(responsePair: responsePair)
        }
    }
    
    private func firstRequestCompeted(responsePair: Dictionary<String, String>) {
        token = responsePair["oauth_token"] ?? "";
        tokenSecret = responsePair["oauth_token_secret"] ?? "";

        if !token.isEmpty && !tokenSecret.isEmpty {
            status = OAuthStatus.firstRequestSucceeded
            tokenizedAuthorizationURL = authorizationURL! + "?oauth_token=" + token
            delegate?.firstRequestSucceeded()
        }
        else {
            status = OAuthStatus.firstRequestFailed
            delegate?.firstRequestFailed()
        }
    }
    
    private func secondRequestCompleted(responsePair: Dictionary<String, String>) {
        accessToken = responsePair["oauth_token"] ?? ""
        accessTokenSecret = responsePair["oauth_token_secret"] ?? ""
        
        if !accessToken.isEmpty && !accessTokenSecret.isEmpty {
            status = OAuthStatus.secondRequestSucceeded
            delegate?.secondRequestSucceeded()
        }
        else {
            status = OAuthStatus.secondRequestFailed
            delegate?.secondRequestFailed()
        }
    }
    
    // MARK: utility method
    private func parse(_ string: String) -> Dictionary<String, String> {
        var i: Int = 0
        var name = String()
        var value = String()
        var dictionary = Dictionary<String, String>()
        var writingName = true
        
        while i < string.characters.count {
            let index = string.index(string.startIndex, offsetBy: i)
            
            if string[index] == "=" {
                writingName = false
            }
            else if string[index] == "&" {
                dictionary[name] = value
                name = ""
                value = ""
                writingName = true
            }
            else if writingName {
                name.append(string[index])
            }
            else if !writingName {
                value.append(string[index])
            }
            i = i + 1
        }
        dictionary[name] = value
        
        return dictionary;
    }
}
