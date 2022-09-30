//
// Created by Andriy Druk on 04.12.2019.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public final class FavIconAddressAvatarsClient: AvatarsClient<AddressAvatarsRequest> {
     
    override public var name: String {
        return "FavIcon"
    }

    override public var ttl: TimeInterval {
        return 7 * 86_400
    }

    override public func requestImageFor(request: AddressAvatarsRequest, with completion: @escaping AvatarFetchCompletion) {
        func extractDomain(_ email: String) -> String {
            let index = email.range(of: "@", options: .backwards)!.lowerBound
            let next = email.index(after: index)
            return String(email.suffix(from: next))
        }

        let domain = extractDomain(request.email)
        
        var domains = ["https://www.\(domain)", 
                       "https://\(domain)", 
                       "http://www.\(domain)", 
                       "http://www.\(domain)"]
        if domain.contains("mail") {
            // If domain contains word `mail` add options without `mail`
            let domainWithoutMail = domain.replacingOccurrences(of: "mail", with: "")
            domains += ["https://www.\(domainWithoutMail)", 
                        "https://\(domainWithoutMail)", 
                        "http://www.\(domainWithoutMail)", 
                        "http://www.\(domainWithoutMail)"]
        }
        downloadForDomain(domains, completion: completion)
    }
    
    private func downloadForDomain(_ domains: [String], completion: @escaping AvatarFetchCompletion) {
        guard let domain = domains.first else {
            completion(.failure(AvatarClientError.invalidArgument))
            return
        }

        guard let url = URL(string: domain) else {
            print("-- CLIENT: requestImageForContact - bad email \(domain)")
            completion(.failure(AvatarClientError.invalidArgument))
            return
        }

        print("-- CLIENT: Start checking \(url)")
        let nextDomain = domains.dropFirst()
        FavIcon.scan(url) { icons in
            print("-- CLIENT: Result of checking \(url): \(icons.count) icons")
            guard icons.count > 0 else {
                self.downloadForDomain(Array(nextDomain), completion: completion)
                return
            }
        }
    }

    private func checkIcons(domain: String, icons: [Icon], completion: @escaping AvatarFetchCompletion) {
        completion(.success(nil))
    }

}

extension IconType {

    var isNotIconImage: Bool {
        return self == .microsoftPinnedSite || self == .openGraphImage
    }

}
