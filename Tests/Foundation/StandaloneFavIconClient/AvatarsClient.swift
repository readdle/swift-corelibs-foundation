//
// Created by Andriy Druk on 26.11.2019.
//

import Foundation

/// All errors are handled in same way in the Avatar Manager,
/// so there is no need in variety of errors cases.
public enum AvatarClientError: Error {
    case unknown
    case invalidArgument
}

/// The most important thing to know about fetch result is that
/// any `.success` (even without URL) gets cached (and is a subject
/// of TTL check), and `.failure` doesn't get cached. This allows
/// clients to control caching strategy in agile way.
public typealias AvatarFetchCompletion = (Result<URL?, Error>) -> Void

open class AvatarsClient<Request: AvatarRequest> {

    public init() {}

    /// Name of client
    open var name: String {
        return ""
    }

    /// TTL (Note: re-fetching of avatar started after TTL expiration)
    open var ttl: TimeInterval {
        return 0.0
    }

    open func requestImageFor(request: Request, with completion: @escaping AvatarFetchCompletion) {
        completion(.failure(AvatarClientError.unknown))
    }
    
}
