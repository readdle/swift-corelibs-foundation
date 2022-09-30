//
// FavIcon
// Copyright © 2018 Leon Breedt
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

/// Enumerates errors that could occur while scanning or downloading.
enum IconError: Error {
    /// Invalid URL specified.
    case invalidBaseURL
    /// An invalid response was received while attempting to download an icon.
    case invalidDownloadResponse
    /// No icons were detected at the supplied URL.
    case noIconsDetected
    /// The icon image was corrupt, or is not of a supported file format.
    case corruptImage
}

public final class FavIcon {
    /// Scans a base URL, attempting to determine all of the supported icons that can
    /// be used for favicon purposes.
    ///
    /// It will do the following to determine possible icons that can be used:
    ///
    /// - Check whether or not `/favicon.ico` exists.
    /// - If the base URL returns an HTML page, parse the `<head>` section and check for `<link>`
    ///   and `<meta>` tags that reference icons using Apple, Microsoft and Google
    ///   conventions.
    /// - If _Web Application Manifest JSON_ (`manifest.json`) files are referenced, or
    ///   _Microsoft browser configuration XML_ (`browserconfig.xml`) files
    ///   are referenced, download and parse them to check if they reference icons.
    ///
    ///  All of this work is performed in a background queue.
    ///
    /// - parameter url: The base URL to scan.
    /// - parameter completion: A closure to call when the scan has completed. The closure will be call
    ///                         on the main queue.
    public static func scan(_ url: URL,
                            completion: @escaping () -> Void) {
        let htmlURL = url
        let favIconURL = URL(string: "/favicon.ico", relativeTo: url as URL)!.absoluteURL

        let group = DispatchGroup()

        group.enter()
        downloadURL(favIconURL, method: "HEAD") { result in
            defer { group.leave() }
        }

        group.enter()
        downloadURL(htmlURL) { result in
            defer { group.leave() }
        }

        group.notify(queue: DispatchQueue.global()) {
            completion()
        }
    }

}

