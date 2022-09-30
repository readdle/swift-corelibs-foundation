//
// Created by Andriy Druk on 27.11.2019.
//

import Foundation

public typealias FetchProgress = (_: URL?) -> Void

private typealias DedublicatorCompletion = () -> Void
private typealias DedublicatorTask = (@escaping DedublicatorCompletion) -> Void

public final class AvatarsFetcher<Request: AvatarRequest> {

    private let client: AvatarsClient<Request>
    private let requestLimiter: DispatchSemaphore?
    
    private let taskDeduplicator = TaskDeduplicator<AvatarInfo>()

    public init(client: AvatarsClient<Request>) {
        self.client = client
        self.requestLimiter = DispatchSemaphore(value: 7)
    }

    // MARK: - Fetch logic
    public func scheduleFetch(request: Request, progress: @escaping FetchProgress) {
        let requestKey = request.key
        
        print("-- FETCHR: Start check avatar for key: \(requestKey)")
        self.fetchAvatar(request: request, client: self.client) {
            print("-- FETCHR: Finish check avatar for key: \(requestKey)")
            progress(nil)
        }

    }
    
    // MARK: - Private
    
    private func fetchAvatar(request: Request,
                             client: AvatarsClient<Request>,
                             completion: @escaping () -> Void ) {

        requestLimiter?.wait()
        print("-- FETCHR: Start checking client \(client.name) fetch avatar for key: \(request.key)")
        client.requestImageFor(request: request, with: { result in
            self.requestLimiter?.signal()
            if case .success(let url) = result {
                print("-- FETCHR: Finish checking client \(client.name) fetch avatar for key: \(request.key)")
                completion()
            }
            else {
                print("-- FETCHR: Finish checking client \(client.name) fetch avatar for key: \(request.key), request failed")
                completion()
            }
        })
    
    }

}
