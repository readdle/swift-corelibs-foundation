// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

// Most imports now centraized in TestImports.swift

import XCTest
@testable import TestFoundation

#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#endif

// ignore SIGPIPE which is sent when writing to closed file descriptors.
_ = signal(SIGPIPE, SIG_IGN)

#if os(Android)
setenv("URLSessionCertificateAuthorityInfoFile", "/data/local/tmp/cacert.pem", 1)
setenv("TMPDIR", "/data/local/tmp", 1)
#endif

// For the Swift version of the Foundation tests, we must manually list all test cases here.
XCTMain([
    testCase(TestAffineTransform.allTests),
    testCase(TestNSArray.allTests),
    // testCase(TestBundle.allTests), // FAILED CRASH
    testCase(TestByteCountFormatter.allTests),
    testCase(TestNSCache.allTests),
    testCase(TestCalendar.allTests),
    // testCase(TestNSCalendar.allTests), // FAILED Executed 28 tests, with 34 failures - Tried to invoke .unwrapped()
    testCase(TestCharacterSet.allTests),
    testCase(TestNSCompoundPredicate.allTests),
    testCase(TestNSData.allTests),
    testCase(TestDate.allTests),
    testCase(TestDateComponents.allTests),
    testCase(TestNSDateComponents.allTests),
    // testCase(TestDateFormatter.allTests), // FAILED CRASH
    testCase(TestDateIntervalFormatter.allTests),
    testCase(TestDecimal.allTests),
    testCase(TestNSDictionary.allTests),
    testCase(TestNSError.allTests),
    testCase(TestEnergyFormatter.allTests),
    // testCase(TestFileManager.allTests), // NOT AVAILABLE ON ANDROID
    testCase(TestNSGeometry.allTests),
    testCase(TestHTTPCookie.allTests),
    testCase(TestHTTPCookieStorage.allTests),
    testCase(TestIndexPath.allTests),
    testCase(TestIndexSet.allTests),
    testCase(TestISO8601DateFormatter.allTests),
    testCase(TestJSONSerialization.allTests),
    testCase(TestNSKeyedArchiver.allTests),
    // testCase(TestNSKeyedUnarchiver.allTests), // FAILED Executed 9 tests, with 9 failures - Android doesnt support testBundle()
    testCase(TestLengthFormatter.allTests),
    // testCase(TestNSLocale.allTests), // FAILED Executed 6 tests, with 1 failure - Locale lookup unavailable on Android)
    testCase(TestNotificationCenter.allTests),
    testCase(TestNotificationQueue.allTests),
    testCase(TestNSNull.allTests),
    testCase(TestNSNumber.allTests),
    testCase(TestNSNumberBridging.allTests),
    testCase(TestNumberFormatter.allTests),
    testCase(TestOperationQueue.allTests),
    testCase(TestNSOrderedSet.allTests),
    testCase(TestPersonNameComponents.allTests),
    testCase(TestPipe.allTests),
    testCase(TestNSPredicate.allTests),
    // testCase(TestProcessInfo.allTests), // FAILED CRASH
    testCase(TestHost.allTests),
    // testCase(TestPropertyListSerialization.allTests), // FAILED CRASH - Android doesnt support testBundle()
    testCase(TestNSRange.allTests),
    testCase(TestNSRegularExpression.allTests),
    testCase(TestRunLoop.allTests),
    testCase(TestScanner.allTests),
    testCase(TestNSSet.allTests),
    testCase(TestStream.allTests),
    testCase(TestNSString.allTests),
    testCase(TestThread.allTests),
    // testCase(TestProcess.allTests), // NOT AVAILABLE ON ANDROID
    testCase(TestNSTextCheckingResult.allTests),
    testCase(TestTimer.allTests),
    // testCase(TestTimeZone.allTests), // FAILED CRASH - Named timezones not available on Android
    // testCase(TestURL.allTests), // FAILED CRASH
    testCase(TestURLComponents.allTests),
    testCase(TestURLCredential.allTests),
    testCase(TestURLProtectionSpace.allTests),
    testCase(TestURLProtocol.allTests),
    testCase(TestNSURLRequest.allTests),
    testCase(TestURLRequest.allTests),
    testCase(TestURLResponse.allTests),
    testCase(TestHTTPURLResponse.allTests),
    // testCase(TestURLSession.allTests), // FAILED CRASH
    testCase(TestNSUUID.allTests),
    testCase(TestUUID.allTests),
    testCase(TestNSValue.allTests),
    testCase(TestUserDefaults.allTests),
    testCase(TestXMLParser.allTests),
    // testCase(TestXMLDocument.allTests), // FAILED CRASH
    testCase(TestNSAttributedString.allTests),
    testCase(TestNSMutableAttributedString.allTests),
    testCase(TestFileHandle.allTests),
    testCase(TestUnitConverter.allTests),
    // testCase(TestProgressFraction.allTests), // NOT AVAILABLE ON ANDROID
    testCase(TestProgress.allTests),
    testCase(TestObjCRuntime.allTests),
    testCase(TestNotification.allTests),
    testCase(TestMassFormatter.allTests),
    testCase(TestJSONEncoder.allTests),
    testCase(TestCodable.allTests),
    testCase(TestUnit.allTests),
    testCase(TestDimension.allTests),
    testCase(TestNSLock.allTests),
    testCase(TestURLSessionRealServer.allTests),

    // RDTests
    testCase(RDURLSessionTest.allTests),
])

