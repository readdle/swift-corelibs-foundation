//
// Created by Andriy Druk on 04.12.2019.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public final class FavIconAddressAvatarsClient {
    
    public func requestImageFor(email: String, with completion: @escaping () -> Void) {
        func extractDomain(_ email: String) -> String {
            let index = email.range(of: "@", options: .backwards)!.lowerBound
            let next = email.index(after: index)
            return String(email.suffix(from: next))
        }

        let domain = extractDomain(email)
        
        var domains = ["https://www.\(domain)", 
                       "https://\(domain)", 
                       "http://www.\(domain)", 
                       "http://www.\(domain)"]
        downloadForDomain(domains, completion: completion)
    }
    
    private func downloadForDomain(_ domains: [String], completion: @escaping () -> Void) {
        guard let domain = domains.first else {
            completion()
            return
        }

        let url = URL(string: domain)!

        print("-- CLIENT: Start checking \(url)")
        let nextDomain = domains.dropFirst()
        FavIcon.scan(url) {
            print("-- CLIENT: Done checking \(url)")
            self.downloadForDomain(Array(nextDomain), completion: completion)
        }
    }

    private func checkIcons(domain: String, icons: [Icon], completion: @escaping () -> Void) {
        completion()
    }

}
