// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#if DEPLOYMENT_ENABLE_LIBDISPATCH
import Dispatch
import CoreFoundation

open class Operation : NSObject {
    let lock = NSLock()
    internal weak var _queue: OperationQueue?
    internal var _cancelled = false
    internal var _executing = false
    internal var _finished = false
    internal var _ready = true {
        willSet {
            if _ready == true && newValue == false {
                _depGroup.notify(queue: DispatchQueue.global(), execute: { [weak self] in
                    if let op = self {
                        op.lock.synchronized {
                            op._ready = true
                        }
                        op._queue?._runOperations()
                    }
                })
            }
        }
    }
    internal var _dependencies = Set<Operation>()
    internal var _group = DispatchGroup()
    internal var _depGroup = DispatchGroup()
    internal var _groups = [DispatchGroup]()
    
    public override init() {
        super.init()
        _group.enter()
    }
    
    internal func _leaveGroups() {
        // assumes lock is taken
        _groups.forEach() { $0.leave() }
        _groups.removeAll()
        _group.leave()
    }
    
    open func start() {
        if !isCancelled {
            lock.synchronized {
                _executing = true
            }
            main()
            lock.synchronized {
                _executing = false
            }
        }
        finish()
    }
    
    internal func finish() {
        lock.synchronized {
            _finished = true
            _leaveGroups()
        }
        if let queue = _queue {
            queue._operationFinished(self)
        }
        // The completion block property is a bit cagey and can not be executed locally on the queue due to thread exhaust potentials.
        // This sets up for some strange behavior of finishing operations since the handler will be executed on a different queue
        if let completion = completionBlock {
            DispatchQueue.global(qos: .background).async { () -> Void in
                completion()
            }
        }
    }
    
    open func main() { }
    
    open var isCancelled: Bool {
        return lock.synchronized { _cancelled }
    }
    
    open func cancel() {
        // Note that calling cancel() is advisory. It is up to the main() function to
        // call isCancelled at appropriate points in its execution flow and to do the
        // actual canceling work. Eventually main() will invoke finish() and this is
        // where we then leave the groups and unblock other operations that might
        // depend on us.
        lock.synchronized {
            _cancelled = true
        }
    }
    
    open var isExecuting: Bool {
        return lock.synchronized { _executing }
    }
    
    open var isFinished: Bool {
        return lock.synchronized { _finished }
    }
    
    // - Note: This property is NEVER used in the objective-c implementation!
    open var isAsynchronous: Bool {
        return false
    }
    
    open var isReady: Bool {
        return lock.synchronized { _ready }
    }
    
    open func addDependency(_ op: Operation) {
        op.lock.synchronized {
            if op._finished {
                return
            }
            lock.synchronized {
                _depGroup.enter()
                _ready = false
                _dependencies.insert(op)
                op._groups.append(_depGroup)
            }
        }
    }
    
    open func removeDependency(_ op: Operation) {
        lock.synchronized {
            _dependencies.remove(op)
            op.lock.synchronized {
                let groupIndex = op._groups.index(where: { $0 === self._depGroup })
                if let idx = groupIndex {
                    let group = op._groups.remove(at: idx)
                    group.leave()
                }
            }
        }
    }
    
    open var dependencies: [Operation] {
        return lock.synchronized {
            _dependencies.map() { $0 }
        }
    }
    
    open var queuePriority: QueuePriority = .normal
    public var completionBlock: (() -> Void)?
    open func waitUntilFinished() {
        _group.wait()
    }
    
    open var threadPriority: Double = 0.5
    
    /// - Note: Quality of service is not directly supported here since there are not qos class promotions available outside of darwin targets.
    open var qualityOfService: QualityOfService = .default
    
    open var name: String?
    
    internal func _waitUntilReady() {
        _depGroup.wait()
        _ready = true
    }
}

/// The following two methods are added to provide support for Operations which
/// are asynchronous from the execution of the operation queue itself.  On Darwin,
/// this is supported via KVO notifications.  In the absence of KVO on non-Darwin
/// platforms, these two methods (which are defined in NSObject on Darwin) are
/// temporarily added here.  They should be removed once a permanent solution is
/// found.
extension Operation {
    public func willChangeValue(forKey key: String) {
        // do nothing
    }

    public func didChangeValue(forKey key: String) {
        if key == "isFinished" && isFinished {
            finish()
        }
    }
}

extension Operation {
    public enum QueuePriority : Int {
        case veryLow
        case low
        case normal
        case high
        case veryHigh
    }
}

open class BlockOperation: Operation {
    typealias ExecutionBlock = () -> Void
    internal var _block: () -> Void
    internal var _executionBlocks = [ExecutionBlock]()
    
    public init(block: @escaping () -> Void) {
        _block = block
    }
    
    override open func main() {
        let block = lock.synchronized { _block }
        let executionBlocks = lock.synchronized { _executionBlocks }
        block()
        executionBlocks.forEach { $0() }
    }
    
    open func addExecutionBlock(_ block: @escaping () -> Void) {
        lock.synchronized {
            _executionBlocks.append(block)
        }
    }
    
    open var executionBlocks: [() -> Void] {
        return lock.synchronized { _executionBlocks }
    }
}

public extension OperationQueue {
    public static let defaultMaxConcurrentOperationCount: Int = Int.max
}

internal struct _OperationList {
    var veryLow = [Operation]()
    var low = [Operation]()
    var normal = [Operation]()
    var high = [Operation]()
    var veryHigh = [Operation]()
    var all = [Operation]()
    
    mutating func insert(_ operation: Operation) {
        all.append(operation)
        switch operation.queuePriority {
        case .veryLow:
            veryLow.append(operation)
        case .low:
            low.append(operation)
        case .normal:
            normal.append(operation)
        case .high:
            high.append(operation)
        case .veryHigh:
            veryHigh.append(operation)
        }
    }
    
    mutating func remove(_ operation: Operation) {
        if let idx = all.index(of: operation) {
            all.remove(at: idx)
        }
        switch operation.queuePriority {
        case .veryLow:
            if let idx = veryLow.index(of: operation) {
                veryLow.remove(at: idx)
            }
        case .low:
            if let idx = low.index(of: operation) {
                low.remove(at: idx)
            }
        case .normal:
            if let idx = normal.index(of: operation) {
                normal.remove(at: idx)
            }
        case .high:
            if let idx = high.index(of: operation) {
                high.remove(at: idx)
            }
        case .veryHigh:
            if let idx = veryHigh.index(of: operation) {
                veryHigh.remove(at: idx)
            }
        }
    }

    func dequeueIfReady(from operations: inout [Operation]) -> Operation? {
        if operations.isEmpty {
            return nil
        }

        for (i, operation) in operations.enumerated() {
            if operation.lock.synchronized({ operation._ready }) {
                operations.remove(at: i)
                return operation
            }
        }

        return nil
    }

    mutating func dequeueIfReady() -> Operation? {
        if let operation = dequeueIfReady(from: &veryHigh) {
            return operation
        }
        if let operation = dequeueIfReady(from: &high) {
            return operation
        }
        if let operation = dequeueIfReady(from: &normal) {
            return operation
        }
        if let operation = dequeueIfReady(from: &low) {
            return operation
        }
        if let operation = dequeueIfReady(from: &veryLow) {
            return operation
        }
        return nil
    }
    
    var count: Int {
        return all.count
    }
    
    func map<T>(_ transform: (Operation) throws -> T) rethrows -> [T] {
        return try all.map(transform)
    }
}

open class OperationQueue: NSObject {
    let lock = NSLock()
    var __underlyingQueue: DispatchQueue? {
        didSet {
            let key = OperationQueue.OperationQueueKey
            oldValue?.setSpecific(key: key, value: nil)
            __underlyingQueue?.setSpecific(key: key, value: Unmanaged.passUnretained(self))
        }
    }
    let queueGroup = DispatchGroup()
    
    var _operations = _OperationList()

    // This is NOT the behavior of the objective-c variant; it will never re-use a queue and instead for every operation it will create a new one.
    // However this is considerably faster and probably more effecient.
    fileprivate var _underlyingQueue: DispatchQueue {
        if let queue = __underlyingQueue {
            return queue
        } else {
            let effectiveName: String
            if let requestedName = _name {
                effectiveName = requestedName
            } else {
                effectiveName = "NSOperationQueue::\(Unmanaged.passUnretained(self).toOpaque())"
            }
            let qos: DispatchQoS
            switch qualityOfService {
            case .background: qos = DispatchQoS(qosClass: .background, relativePriority: 0)
            case .`default`: qos = DispatchQoS(qosClass: .`default`, relativePriority: 0)
            case .userInitiated: qos = DispatchQoS(qosClass: .userInitiated, relativePriority: 0)
            case .userInteractive: qos = DispatchQoS(qosClass: .userInteractive, relativePriority: 0)
            case .utility: qos = DispatchQoS(qosClass: .utility, relativePriority: 0)
            }
            // Always .concurrent because maxConcurrentOperationCount is immutable
            let queue = DispatchQueue(label: effectiveName, qos: qos, attributes: .concurrent)
            if _suspended {
                queue.suspend()
            }
            __underlyingQueue = queue
            return queue
        }
    }

    public override init() {
        super.init()
    }

    internal init(_queue queue: DispatchQueue, maxConcurrentOperations: Int = OperationQueue.defaultMaxConcurrentOperationCount) {
        __underlyingQueue = queue
        super.init()
        maxConcurrentOperationCount = maxConcurrentOperations
        queue.setSpecific(key: OperationQueue.OperationQueueKey, value: Unmanaged.passUnretained(self))
    }
    
    open func addOperation(_ op: Operation) {
        addOperations([op], waitUntilFinished: false)
    }
    
    private var _operationCount = 0
    private var _operationMaxCount = Int.max
    
    fileprivate func _runOperations() {
        lock.synchronized {
            while !_suspended && _operationCount < _operationMaxCount, let op = _operations.dequeueIfReady() {
                let block = DispatchWorkItem(flags: .enforceQoS) {
                    op.start()
                }
                _operationCount += 1
                _underlyingQueue.async(group: queueGroup, execute: block)
            }
        }
    }
    
    open func addOperations(_ ops: [Operation], waitUntilFinished wait: Bool) {
        var waitGroup: DispatchGroup?
        if wait {
            waitGroup = DispatchGroup()
        }
        lock.synchronized {
            ops.forEach { (operation: Operation) -> Void in
                operation._queue = self
                _operations.insert(operation)
                if let waitGroup = waitGroup {
                    waitGroup.enter()
                    operation.lock.lock()
                    operation._groups.append(waitGroup)
                    operation.lock.unlock()
                }
            }
        }
        self._runOperations()
        if let group = waitGroup {
            group.wait()
        }
    }
    
    internal func _operationFinished(_ operation: Operation) {
        lock.synchronized {
            _operations.remove(operation)
            _operationCount -= 1
            operation._queue = nil
        }
        _runOperations()
    }
    
    open func addOperation(_ block: @escaping () -> Swift.Void) {
        let op = BlockOperation(block: block)
        op.qualityOfService = qualityOfService
        addOperation(op)
    }
    
    // WARNING: the return value of this property can never be used to reliably do anything sensible
    open var operations: [Operation] {
        return lock.synchronized {
            _operations.map() { $0 }
        }
    }
    
    // WARNING: the return value of this property can never be used to reliably do anything sensible
    open var operationCount: Int {
        return lock.synchronized { _operations.count }
    }
    
    open var maxConcurrentOperationCount: Int {
        get {
            return _operationMaxCount
        }
        set {
            lock.synchronized {
                _operationMaxCount = newValue
            }
        }
    }
    
    internal var _suspended = false
    open var isSuspended: Bool {
        get {
            return _suspended
        }
        set {
            lock.synchronized {
                if _suspended != newValue {
                    _suspended = newValue
                }
            }
            if newValue == false {
                _runOperations()
            }
        }
    }
    
    internal var _name: String?
    open var name: String? {
        get {
            return lock.synchronized { _name }
        }
        set {
            lock.synchronized {
                _name = newValue
                __underlyingQueue = nil
            }
        }
    }
    
    open var qualityOfService: QualityOfService = .default

    // Note: this will return non nil whereas the objective-c version will only return non nil when it has been set.
    // it uses a target queue assignment instead of returning the actual underlying queue.
    open var underlyingQueue: DispatchQueue? {
        get {
            return lock.synchronized { __underlyingQueue }
        }
        set {
            lock.synchronized {
                __underlyingQueue = newValue
            }
        }
    }
    
    open func cancelAllOperations() {
        let ops = lock.synchronized {
          _operations.map() { $0 }
        }
        ops.forEach() { $0.cancel() }
    }
    
    open func waitUntilAllOperationsAreFinished() {
        queueGroup.wait()
    }
    
    static let OperationQueueKey = DispatchSpecificKey<Unmanaged<OperationQueue>>()

    open class var current: OperationQueue? {
        guard let specific = DispatchQueue.getSpecific(key: OperationQueue.OperationQueueKey) else {
            if _CFIsMainThread() {
                return OperationQueue.main
            } else {
                return nil
            }
        }
        
        return specific.takeUnretainedValue()
    }
    
    private static let _main = OperationQueue(_queue: .main, maxConcurrentOperations: 1)
    
    open class var main: OperationQueue {
        return _main
    }
}
#endif
