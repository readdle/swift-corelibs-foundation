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
                            completion: @escaping ([Icon]) -> Void) {
        let htmlURL = url
        let favIconURL = URL(string: "/favicon.ico", relativeTo: url as URL)!.absoluteURL

        var icons = [Icon]()
        let group = DispatchGroup()

        group.enter()
        downloadURL(favIconURL, method: "HEAD") { result in
            defer { group.leave() }
            switch result {
            case .exists:
                icons.append(Icon(url: favIconURL, type: .classic))
            default:
                return
            }
        }

        group.enter()
        downloadURL(htmlURL) { result in
            defer { group.leave() }

            if case .text(let text, let mimeType, let downloadedURL) = result {
                guard mimeType == "text/html" else { return }
                guard let data = text.data(using: .utf8) else { return }

                let document = HTMLDocument(data: data)

                icons.append(contentsOf: detectHTMLHeadIcons(document, baseURL: downloadedURL))
                for manifestURL in extractWebAppManifestURLs(document, baseURL: downloadedURL) {
                    group.enter()
                    downloadURL(manifestURL) { result in
                        defer { group.leave() }
                        if case .text(let text, _, let downloadedURL) = result {
                            icons.append(contentsOf: detectWebAppManifestIcons(text, baseURL: downloadedURL))
                        }
                    }
                }

                let browserConfigResult = extractBrowserConfigURL(document, baseURL: url)
                if let browserConfigURL = browserConfigResult.url, !browserConfigResult.disabled {
                    group.enter()
                    downloadURL(browserConfigURL) { result in
                        defer { group.leave() }
                        if case .text(let text, _, let downloadedURL) = result {
                            let document = FavXMLDocument(string: text)
                            icons.append(contentsOf: detectBrowserConfigXMLIcons(document, baseURL: downloadedURL))
                        }
                    }
                }
            }
        }

        group.notify(queue: DispatchQueue.global()) {
            completion(icons)
        }
    }

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
    public static func scan(_ url: String, completion: @escaping ([Icon]) -> Void) throws {
        guard let url = URL(string: url) else { throw IconError.invalidBaseURL }
        scan(url, completion: completion)
    }
}

extension Icon {
    var area: Int? {
        if let width = width, let height = height {
            return width * height
        }
        return nil
    }
}
