private class URLSessionDataDelegateWrapper: NSObject, URLSessionDataDelegate {

    var block: (() -> Void)? = nil

    // MARK: - URLSessionDelegate
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        block?()
    }

}

private let sessionDataDelegate = URLSessionDataDelegateWrapper()
private let urlSession = URLSession(configuration: URLSessionConfiguration.default, delegate: sessionDataDelegate, delegateQueue: nil)

private func performRequest(urlSession: URLSession, httpMethod: String = "POST", completion: @escaping () -> Void) {
    var urlRequest = URLRequest(url: URL(string: "https://example.com")!)
    urlRequest.httpMethod = httpMethod
    urlRequest.timeoutInterval = 10

    if (urlRequest.httpMethod == "POST") {
        let data = "{}".data(using: .utf8)!
        let contentType = "application/json"
        urlRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("\(data.count)", forHTTPHeaderField: "Content-Length")
        urlRequest.httpBody = data
    }

    let sessionTask = urlSession.dataTask(with: urlRequest)
    sessionDataDelegate.block = completion
    sessionTask.resume()
}

class RDURLSessionTest: XCTestCase {

    override func setUp() {
        setenv("URLSessionDebug", "true", 1)
        //setenv("URLSessionDebugLibcurl", "true", 1)
    } 

    func testDispatchCrash001() {
        let semaphore = DispatchSemaphore(value: 0)
        performRequest(urlSession: urlSession) {
            performRequest(urlSession: urlSession) {
                semaphore.signal()
            }
        }
        semaphore.wait()
        sleep(3)
    }

    static var allTests = [
        ("testDispatchCrash001", testDispatchCrash001),
    ]

}
