//
// Created by Andriy Druk on 29.11.2019.
//

import Foundation

/**
 A ImageInfo is type that describe one particular image in stored cache
*/
public struct ImageInfo: Hashable, Codable, CustomStringConvertible {

    /// File URL on disk cache
    public let url: URL?
    /// Mime type of image
    public let mime: String?
    /// Width of image in pixels
    public let width: Int
    /// Height of image in pixels
    public let height: Int
    /// Last fetch date
    public let fetchDate: Date

    public init(url: URL? = nil, mime: String? = nil, width: Int = 0, height: Int = 0, fetchDate: Date = Date()) {
        self.url = url
        self.mime = mime
        self.width = width
        self.height = height
        self.fetchDate = fetchDate
    }

    public var description: String {
        return "url: \(url?.description ?? "<no>"), mime: \(mime ?? "<no>"), width: \(width), height: \(height), fetchDate: \(fetchDate)"
    }

    func isImageFit(to size: CGSize) -> Bool {
        return checkAspectRatio() && self.width >= Int(size.width) && self.height >= Int(size.height)
    }

    func checkAspectRatio() -> Bool {
        let aspect = Float(width) / Float(height)
        if aspect < 0.8 || aspect > 1.2 { // Avatar is not square
            // ignore
            return false
        }
        return true
    }
}

/**
 A AvatarInfo is type that describe avatar
*/
public struct AvatarInfo: Hashable, Codable, CustomStringConvertible {

    /// Avatar request key
    let key: String

    /// Best source name, if at least on exist. Nil if no images founded
    let source: String?

    /// Map of imagesInfo by source name
    let imagesInfo: [String: ImageInfo]

    /// Image info of best source if exist
    public var sourceImageInfo: ImageInfo? {
        guard let source = self.source else {
            return nil
        }
        return imagesInfo[source]
    }

    public var description: String {
        return "key: \(key), source: \(source ?? "<no source>"), sourceImageInfo: \(sourceImageInfo?.description ?? "<no image info>")" 
    }
}
