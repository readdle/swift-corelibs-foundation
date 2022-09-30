//
// Created by Andriy Druk on 04.12.2019.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public final class FavIconAddressAvatarsClient: AvatarsClient<AddressAvatarsRequest> {
     
    private let iconComparator: (Icon, Icon) -> Bool = { l, r in
        if l.type.isNotIconImage {
            return false
        }
        if r.type.isNotIconImage {
            return true
        }
        let lImageInfo = ImageInfo(url: l.url, mime: "", width: l.width ?? 0, height: l.height ?? 0)
        let rImageInfo = ImageInfo(url: r.url, mime: "", width: r.width ?? 0, height: r.height ?? 0)
        let imagesInfo = [lImageInfo, rImageInfo]
        if let url = AvatarImageQualifier.chooseBestImage(imageInfos: imagesInfo)?.url, url == r.url {
            return false
        }
        return true
    }

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
            let sortedIcons = icons.sorted(by: self.iconComparator)
            sortedIcons.forEach { icon in
                print("-- CLIENT: Icon for \(domain) -> \(icon.url) with size: \(icon.width ?? 0)x\(icon.height ?? 0) and type: \(icon.type)")
            }
            self.checkIcons(domain: domain, icons: sortedIcons, completion: completion)
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
