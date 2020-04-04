// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#if NS_FOUNDATION_ALLOWS_TESTABLE_IMPORT
    #if canImport(SwiftFoundationNetworking) && !DEPLOYMENT_RUNTIME_OBJC
    @testable import SwiftFoundationNetworking
    #else
        #if canImport(FoundationNetworking)
        @testable import FoundationNetworking
        #endif
    #endif
#endif

class TestURLProtectionSpace : XCTestCase {

    static var allTests: [(String, (TestURLProtectionSpace) -> () throws -> Void)] {
        var tests: [(String, (TestURLProtectionSpace) -> () throws -> ())] = [
            ("test_description", test_description),
        ]
        
        #if NS_FOUNDATION_ALLOWS_TESTABLE_IMPORT
        tests.append(contentsOf: [
            ("test_createWithHTTPURLresponse", test_createWithHTTPURLresponse),
        ])
        #endif
        
        return tests
    }

    func test_description() {
        var space = URLProtectionSpace(
            host: "apple.com",
            port: 80,
            protocol: "http",
            realm: nil,
            authenticationMethod: "basic"
        )
        XCTAssert(space.description.hasPrefix("<\(type(of: space))"))
        XCTAssert(space.description.hasSuffix(": Host:apple.com, Server:http, Auth-Scheme:NSURLAuthenticationMethodDefault, Realm:(null), Port:80, Proxy:NO, Proxy-Type:(null)"))

        space = URLProtectionSpace(
            host: "apple.com",
            port: 80,
            protocol: "http",
            realm: nil,
            authenticationMethod: "NSURLAuthenticationMethodHTMLForm"
        )
        XCTAssert(space.description.hasPrefix("<\(type(of: space))"))
        XCTAssert(space.description.hasSuffix(": Host:apple.com, Server:http, Auth-Scheme:NSURLAuthenticationMethodHTMLForm, Realm:(null), Port:80, Proxy:NO, Proxy-Type:(null)"))
    }

    #if NS_FOUNDATION_ALLOWS_TESTABLE_IMPORT
    func test_createWithHTTPURLresponse() throws {
        // Real responce from outlook.office365.com
        let headerFields1 = [
            "Server": "Microsoft-IIS/10.0",
            "request-id": "c71c2202-4013-4d64-9319-d40aba6bbe5c",
            "WWW-Authenticate": "Basic Realm=\"\"",
            "X-Powered-By": "ASP.NET",
            "X-FEServer": "AM6PR0502CA0062",
            "Date": "Sat, 04 Apr 2020 16:19:39 GMT",
            "Content-Length": "0",
        ]
        let response1 = try XCTUnwrap(HTTPURLResponse(url: URL(string: "https://outlook.office365.com/Microsoft-Server-ActiveSync")!,
                                                      statusCode: 401,
                                                      httpVersion: "HTTP/1.1",
                                                      headerFields: headerFields1))
        let space1 = try XCTUnwrap(URLProtectionSpace.create(with: response1), "Failed to create protection space from valid response")

        XCTAssertEqual(space1.authenticationMethod, NSURLAuthenticationMethodHTTPBasic)
        XCTAssertEqual(space1.protocol, "https")
        XCTAssertEqual(space1.host, "outlook.office365.com")
        XCTAssertEqual(space1.port, 443)
        XCTAssertEqual(space1.realm, "")

        // Real response from jigsaw.w3.org
        let headerFields2 = [
            "date": "Sat, 04 Apr 2020 17:24:23 GMT",
            "content-length": "261",
            "content-type": "text/html;charset=ISO-8859-1",
            "server": "Jigsaw/2.3.0-beta3",
            "www-authenticate": "Basic realm=\"test\"",
            "strict-transport-security": "max-age=15552015; includeSubDomains; preload",
            "public-key-pins": "pin-sha256=\"cN0QSpPIkuwpT6iP2YjEo1bEwGpH/yiUn6yhdy+HNto=\"; pin-sha256=\"WGJkyYjx1QMdMe0UqlyOKXtydPDVrk7sl2fV+nNm1r4=\"; pin-sha256=\"LrKdTxZLRTvyHM4/atX2nquX9BeHRZMCxg3cf4rhc2I=\"; max-age=864000",
            "x-frame-options": "deny",
            "x-xss-protection": "1; mode=block",
        ]
        let response2 = try XCTUnwrap(HTTPURLResponse(url: URL(string: "https://jigsaw.w3.org/HTTP/Basic/")!,
                                                      statusCode: 401,
                                                      httpVersion: "HTTP/2",
                                                      headerFields: headerFields2))
        let space2 = try XCTUnwrap(URLProtectionSpace.create(with: response2), "Failed to create protection space from valid response")

        XCTAssertEqual(space2.authenticationMethod, NSURLAuthenticationMethodHTTPBasic)
        XCTAssertEqual(space2.protocol, "https")
        XCTAssertEqual(space2.host, "jigsaw.w3.org")
        XCTAssertEqual(space2.port, 443)
        XCTAssertEqual(space2.realm, "test")

        // More cases with partial response
        let authenticate3 = "Digest realm=\"test \\\"quoted\\\"\", domain=\"/HTTP/Digest\", nonce=\"be2e96ad8ab8acb7ccfb49bc7e162914\""
        let response3 = try XCTUnwrap(HTTPURLResponse(url: URL(string: "http://jigsaw.w3.org/HTTP/Basic/")!,
                                                      statusCode: 401,
                                                      httpVersion: "HTTP/1.1",
                                                      headerFields: ["www-authenticate" : authenticate3]))
        let space3 = try XCTUnwrap(URLProtectionSpace.create(with: response3), "Failed to create protection space from valid response")

        XCTAssertEqual(space3.authenticationMethod, NSURLAuthenticationMethodHTTPDigest)
        XCTAssertEqual(space3.protocol, "http")
        XCTAssertEqual(space3.host, "jigsaw.w3.org")
        XCTAssertEqual(space3.port, 80)
        XCTAssertEqual(space3.realm, "test \"quoted\"")

        let response4 = try XCTUnwrap(HTTPURLResponse(url: URL(string: "http://apple.com:333")!,
                                                      statusCode: 401,
                                                      httpVersion: "HTTP/1.1",
                                                      headerFields: ["www-authenTicate" : "NTLM realm=\"\\\"\""]))
        let space4 = try XCTUnwrap(URLProtectionSpace.create(with: response4), "Failed to create protection space from valid response")

        XCTAssertEqual(space4.authenticationMethod, NSURLAuthenticationMethodNTLM)
        XCTAssertEqual(space4.protocol, "http")
        XCTAssertEqual(space4.host, "apple.com")
        XCTAssertEqual(space4.port, 333)
        XCTAssertEqual(space4.realm, "\"")

        // Some broken headers
        let response5 = try XCTUnwrap(HTTPURLResponse(url: URL(string: "http://apple.com")!,
                                                      statusCode: 401,
                                                      httpVersion: "HTTP/1.1",
                                                      headerFields: ["www-authenicate" : "Basic"]))
        let space5 = URLProtectionSpace.create(with: response5)
        XCTAssertNil(space5, "Should not create protection space for response without valid header")

        let response6 = try XCTUnwrap(HTTPURLResponse(url: URL(string: "http://apple.com")!,
                                                      statusCode: 401,
                                                      httpVersion: "HTTP/1.1",
                                                      headerFields: ["www-authenticate" : "NT LM realm="]))
        let space6 = try XCTUnwrap(URLProtectionSpace.create(with: response6), "Failed to create protection space from valid response")

        XCTAssertEqual(space6.authenticationMethod, NSURLAuthenticationMethodDefault)
        XCTAssertEqual(space6.protocol, "http")
        XCTAssertEqual(space6.host, "apple.com")
        XCTAssertEqual(space6.port, 80)
        XCTAssertNil(space6.realm)
    }
    #endif
}
