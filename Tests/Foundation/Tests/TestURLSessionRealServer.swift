// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#if NS_FOUNDATION_ALLOWS_TESTABLE_IMPORT
    #if canImport(SwiftFoundation) && !DEPLOYMENT_RUNTIME_OBJC
        @testable import SwiftFoundation
    #else
        @testable import Foundation
    #endif
#endif

let loremIpsum = """
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud
exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla
pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
"""

let httpBinCredentails = URLCredential(user: "user", password: "passwd", persistence: URLCredential.Persistence.none)

class TestURLSessionRealServer: XCTestCase {
    static var allTests: [(String, (TestURLSessionRealServer) -> () throws -> Void)] {
        return [
            ("test_dataTaskWithHttpBody", test_dataTaskWithHttpBody),
            ("test_dataTaskWithHttpInputStream", test_dataTaskWithHttpInputStream), // HTTPBin doesn't support chunked transfer encoding
            ("test_dataTaskWithBasicAuth", test_dataTaskWithBasicAuth),
            ("test_dataTaskWithBasicAuth_InputStream", test_dataTaskWithBasicAuth_InputStream),
            ("test_dataTaskWithDigestAuth", test_dataTaskWithDigestAuth),
            ("test_dataTaskWithDigestAuth_InputStream", test_dataTaskWithDigestAuth_InputStream),
            ("test_dataTaskWithDigestAuth_CredentialOnce", test_dataTaskWithDigestAuth_CredentialOnce),
            ("test_dataTaskWithDigestAuth_AuthChallenges", test_dataTaskWithDigestAuth_AuthChallenges),
//            ("test_badCertificate", test_badCertificate)
        ]
    }

    override func setUp() {
        #if os(Windows)
        _putenv("URLSessionDebugLibcurl=TRUE")
        #else
        setenv("URLSessionDebugLibcurl", "TRUE", 1)
        #endif
    }

    func test_dataTaskWithHttpBody() {
        let delegate = HTTPBinResponseDelegateJSON<HTTPBinResponse>()

        let urlString = "http://httpbin.org/post"
        let url = URL(string: urlString)!
        let urlSession = URLSession(configuration: URLSessionConfiguration.default, delegate: delegate, delegateQueue: nil)

        let data = loremIpsum.data(using: .utf8)

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = data
        urlRequest.setValue("en-us", forHTTPHeaderField: "Accept-Language")
        urlRequest.setValue("text/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")

        let urlTask = urlSession.dataTask(with: urlRequest)
        urlTask.resume()

        delegate.semaphore.wait()

        XCTAssertTrue(urlTask.response != nil)
        XCTAssertTrue(delegate.response != nil)
        XCTAssertTrue(delegate.response?.data == loremIpsum)
    }

    /*
    func test_badCertificate() {
        let delegate = HTTPBinResponseDelegateAuthOwnCert<HTTPBinAuthResponse>()

        let certificateFailures = ["self-signed", "expired", "wrong.host", "untrusted-root", "revoked", "pinning-test"]

        for certFailure in certificateFailures {
            let url = URL(string: "https://\(certFailure).badssl.com/")!
            let urlSession = URLSession(configuration: URLSessionConfiguration.default, delegate: delegate, delegateQueue: nil)

            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "GET"
            urlRequest.setValue("en-us", forHTTPHeaderField: "Accept-Language")
            urlRequest.setValue("text/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")

            let urlTask = urlSession.dataTask(with: urlRequest)
            urlTask.resume()

            delegate.semaphore.wait()
            XCTAssertTrue(urlTask.response != nil)
            if (urlTask.response != nil) {
                XCTAssertTrue(urlTask.response is HTTPURLResponse)
                XCTAssertTrue((urlTask.response as! HTTPURLResponse).statusCode == 200)
            }
        }
    }
    */
    
    func test_dataTaskWithHttpInputStream() {
        let delegate = HTTPBinResponseDelegateJSON<HTTPBinResponse>()

        let urlString = "http://httpbin.org/post"
        let url = URL(string: urlString)!
        let urlSession = URLSession(configuration: URLSessionConfiguration.default, delegate: delegate, delegateQueue: nil)

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"

        guard let data = loremIpsum.data(using: .utf8) else {
            XCTFail()
            return
        }

        let inputStream = InputStream(data: data)

        urlRequest.httpBodyStream = inputStream

        urlRequest.setValue("en-us", forHTTPHeaderField: "Accept-Language")
        urlRequest.setValue("text/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("chunked", forHTTPHeaderField: "Transfer-Encoding")

        let urlTask = urlSession.dataTask(with: urlRequest)
        urlTask.resume()

        delegate.semaphore.wait()

        XCTAssertTrue(urlTask.response != nil)
        XCTAssertTrue(delegate.response != nil)
        XCTAssertTrue(delegate.response?.data == loremIpsum)
    }

    func test_dataTaskWithBasicAuth() {
        let delegate = HTTPBinResponseDelegateAuth<HTTPBinAuthResponse>()

        let urlString = "http://httpbin.org/basic-auth/user/passwd"
        let url = URL(string: urlString)!
        let urlSession = URLSession(configuration: URLSessionConfiguration.default, delegate: delegate, delegateQueue: nil)

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("en-us", forHTTPHeaderField: "Accept-Language")
        urlRequest.setValue("text/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")

        let urlTask = urlSession.dataTask(with: urlRequest)
        urlTask.resume()


        delegate.semaphore.wait()

        XCTAssertTrue(urlTask.response != nil)
        XCTAssertTrue(delegate.response != nil)
        XCTAssertTrue(delegate.response?.authenticated ?? false)
        XCTAssertTrue(delegate.response?.user == httpBinCredentails.user)
    }
    
    func test_dataTaskWithBasicAuth_InputStream() {
        let delegate = HTTPBinResponseDelegateAuth<HTTPBinResponse>()

        let urlString = "https://rdauthtest.000webhostapp.com/basic_post.php"
        // To view source code open - https://rdauthtest.000webhostapp.com/basic_post.txt

        let url = URL(string: urlString)!
        let urlSession = URLSession(configuration: URLSessionConfiguration.default, delegate: delegate, delegateQueue: nil)

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"

        guard let data = loremIpsum.data(using: .utf8) else {
            XCTFail()
            return
        }

        let inputStream = InputStream(data: data)

        urlRequest.httpBodyStream = inputStream

        urlRequest.setValue("en-us", forHTTPHeaderField: "Accept-Language")
        urlRequest.setValue("text/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("chunked", forHTTPHeaderField: "Transfer-Encoding")

        let urlTask = urlSession.dataTask(with: urlRequest)
        urlTask.resume()

        delegate.semaphore.wait()

        XCTAssertTrue(urlTask.response != nil)
        XCTAssertEqual(delegate.lastAuthenticationMethod, NSURLAuthenticationMethodHTTPBasic)
        XCTAssertTrue(delegate.response != nil)
        XCTAssertTrue(delegate.response?.data == loremIpsum)
    }

    func test_dataTaskWithDigestAuth() {
        let delegate = HTTPBinResponseDelegateAuth<HTTPBinAuthResponse>()
        let urlTask = buildDigestAuthURLTaskForHTTPBin(delegate)

        urlTask.resume()

        delegate.semaphore.wait()

        XCTAssertTrue(urlTask.response != nil)
        XCTAssertTrue(delegate.response != nil)
        XCTAssertTrue(delegate.response?.authenticated ?? false)
        XCTAssertTrue(delegate.response?.user == httpBinCredentails.user)
    }
    
    func test_dataTaskWithDigestAuth_InputStream() {
        let delegate = HTTPBinResponseDelegateAuth<HTTPBinResponse>()

        let urlString = "https://rdauthtest.000webhostapp.com/digest_post.php"
        // To view source code open - https://rdauthtest.000webhostapp.com/digest_post.txt

        let url = URL(string: urlString)!
        let urlSession = URLSession(configuration: URLSessionConfiguration.default, delegate: delegate, delegateQueue: nil)

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"

        guard let data = loremIpsum.data(using: .utf8) else {
            XCTFail()
            return
        }

        let inputStream = InputStream(data: data)

        urlRequest.httpBodyStream = inputStream

        urlRequest.setValue("en-us", forHTTPHeaderField: "Accept-Language")
        urlRequest.setValue("text/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("chunked", forHTTPHeaderField: "Transfer-Encoding")

        let urlTask = urlSession.dataTask(with: urlRequest)
        urlTask.resume()

        delegate.semaphore.wait()

        XCTAssertTrue(urlTask.response != nil)
        XCTAssertEqual(delegate.lastAuthenticationMethod, NSURLAuthenticationMethodHTTPDigest)
        XCTAssertTrue(delegate.response != nil)
        XCTAssertTrue(delegate.response?.data == loremIpsum)
    }

    func test_dataTaskWithDigestAuth_CredentialOnce() {
        let delegate = HTTPBinResponseDelegateAuth_CredentialsOnce()
        let urlTask = buildDigestAuthURLTaskForHTTPBin(delegate)

        urlTask.resume()

        delegate.semaphore.wait()

        XCTAssertTrue(urlTask.response != nil)
        XCTAssertTrue(delegate.response != nil)
        XCTAssertTrue(delegate.response?.authenticated ?? false)
        XCTAssertTrue(delegate.response?.user == httpBinCredentails.user)
    }

    func test_dataTaskWithDigestAuth_AuthChallenges() {
        // Cancel
        var delegate = HTTPBinResponseDelegateAuth_AuthChallenges_Counter(.cancelAuthenticationChallenge)
        var urlTask = buildDigestAuthURLTaskForHTTPBin(delegate)
        urlTask.resume()
        delegate.semaphore.wait()
        XCTAssertTrue(delegate.count == 1)

        // Reject
        delegate = HTTPBinResponseDelegateAuth_AuthChallenges_Counter(.rejectProtectionSpace)
        urlTask = buildDigestAuthURLTaskForHTTPBin(delegate)
        urlTask.resume()
        delegate.semaphore.wait()
        XCTAssertTrue(delegate.count == 1) // asked for more than 1 protection space
        XCTAssertEqual(urlTask.state, URLSessionTask.State.completed)

        // Default
        delegate = HTTPBinResponseDelegateAuth_AuthChallenges_Counter(.performDefaultHandling)
        urlTask = buildDigestAuthURLTaskForHTTPBin(delegate)
        urlTask.resume()
        delegate.semaphore.wait()
        XCTAssertTrue(delegate.count == 1)
    }

    func buildDigestAuthURLTaskForHTTPBin(_ delegate: HTTPBinResponseDelegate<HTTPBinAuthResponse>) -> URLSessionTask {
        let urlString = "http://httpbin.org/digest-auth/auth/user/passwd/MD5/never"
        let url = URL(string: urlString)!
        let urlSession = URLSession(configuration: URLSessionConfiguration.default, delegate: delegate, delegateQueue: nil)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("en-us", forHTTPHeaderField: "Accept-Language")
        urlRequest.setValue("text/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")

        let urlTask = urlSession.dataTask(with: urlRequest)

        return urlTask
    }

    class HTTPBinResponseDelegateAuth<T: Codable>: HTTPBinResponseDelegateJSON<T> {
        override func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            print("didReceive challenge")
            resetOutput()
            lastAuthenticationMethod = challenge.protectionSpace.authenticationMethod
            completionHandler(.useCredential, httpBinCredentails)
        }
    }
    
    /*
    class HTTPBinResponseDelegateAuthOwnCert<T: Codable>: HTTPBinResponseDelegateJSON<T> {
        override func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            #if DARWIN_COMPATIBILITY_TESTS
            if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
                let credential = URLCredential.init(trust: challenge.protectionSpace.serverTrust!)
                completionHandler(URLSession.AuthChallengeDisposition.useCredential, credential)
            }
            else {
                completionHandler(.useCredential, httpBinCredentails)
            }
            #else
            if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
                completionHandler(.useCredential, URLCredential.init(trust: true))
            }
            else {
                completionHandler(.useCredential, httpBinCredentails)
            }
            #endif
        }
    }
    */

    class HTTPBinResponseDelegateAuth_AuthChallenges_Counter: HTTPBinResponseDelegateJSON<HTTPBinAuthResponse> {
        let challenge: URLSession.AuthChallengeDisposition
        public var count = 0

        init(_ challenge: URLSession.AuthChallengeDisposition) {
            self.challenge = challenge
        }

        override func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            print("didReceive challenge")
            resetOutput()
            lastAuthenticationMethod = challenge.protectionSpace.authenticationMethod
            count += 1
            completionHandler(self.challenge, httpBinCredentails)
        }
    }

    class HTTPBinResponseDelegateAuth_CredentialsOnce: HTTPBinResponseDelegateJSON<HTTPBinAuthResponse> {
        var tryCount = 0

        override func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            print("didReceive challenge")
            resetOutput()
            lastAuthenticationMethod = challenge.protectionSpace.authenticationMethod
            
            if tryCount > 0 {
                completionHandler(.useCredential, nil)
            } else {
                completionHandler(.useCredential, httpBinCredentails)
            }
            tryCount += 1
        }
    }

    class HTTPBinResponseDelegate<T>: NSObject, URLSessionDataDelegate, URLSessionTaskDelegate {
        let semaphore = DispatchSemaphore(value: 0)
        var outputStream = OutputStream.toMemory()
        var response: T?

        override init() {
            outputStream.open()
        }

        deinit {
            outputStream.close()
        }
        
        func resetOutput() {
            outputStream.close()
            outputStream = OutputStream.toMemory()
            outputStream.open()
        }

        func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        }

        public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
            _ = data.withUnsafeBytes({ (bytes: UnsafePointer<UInt8>) in
                outputStream.write(bytes, maxLength: data.count)
            })
        }

        public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            if let data = outputStream.property(forKey: .dataWrittenToMemoryStreamKey) as? Data {
                response = parseResposne(data: data)
            }
            semaphore.signal()
        }


        // Used only for httpBodyStream
        public func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
            guard let data = loremIpsum.data(using: .utf8) else {
                XCTFail()
                return
            }
            let inputStream = InputStream(data: data)
            completionHandler(inputStream)
        }

        public func parseResposne(data: Data) -> T? {
            fatalError("")
        }


        func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
            // We've got an error
            if let err = error {
                print("Error: \(err.localizedDescription)")
            } else {
                print("Error. Giving up")
            }
            //PlaygroundPage.current.finishExecution()
        }
    }

    class HTTPBinResponseDelegateString: HTTPBinResponseDelegate<String> {
        override func parseResposne(data: Data) -> String? {
            return String(data: data, encoding: .utf8)
        }
    }

    class HTTPBinResponseDelegateJSON<T: Codable>: HTTPBinResponseDelegate<T> {
        var lastAuthenticationMethod: String?
        
        override func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        }

        override func parseResposne(data: Data) -> T? {
            let str = String(data: data, encoding: .utf8) ?? " --- "
            print("Response data: \(str)")
            return try? JSONDecoder().decode(T.self, from: data)
        }
    }

    struct HTTPBinResponse: Codable {
        let data: String
        let headers: [String: String]
        let origin: String
        let url: String
    }

    struct HTTPBinAuthResponse: Codable {
        let authenticated: Bool
        let user: String
    }
}

