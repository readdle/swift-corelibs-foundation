// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//



#if DEPLOYMENT_RUNTIME_OBJC || os(Linux)
import Foundation
import XCTest
#else
import SwiftFoundation
import SwiftXCTest
#endif
import Dispatch

class TestOperationQueue : XCTestCase {
    static var allTests: [(String, (TestOperationQueue) -> () throws -> Void)] {
        return [
            ("test_OperationPriorities", test_OperationPriorities),
            ("test_OperationCount", test_OperationCount),
            ("test_AsyncOperation", test_AsyncOperation),
            ("test_isExecutingWorks", test_isExecutingWorks),
            ("test_MainQueueGetter", test_MainQueueGetter),
            ("test_CurrentQueueOnMainQueue", test_CurrentQueueOnMainQueue),
            ("test_CurrentQueueOnBackgroundQueue", test_CurrentQueueOnBackgroundQueue),
            ("test_CurrentQueueOnBackgroundQueueWithSelfCancel", test_CurrentQueueOnBackgroundQueueWithSelfCancel),
            ("test_CurrentQueueWithCustomUnderlyingQueue", test_CurrentQueueWithCustomUnderlyingQueue),
            ("test_CurrentQueueWithUnderlyingQueueResetToNil", test_CurrentQueueWithUnderlyingQueueResetToNil),
            ("test_cancelDependency", test_cancelDependency),
            ("test_deadlock", test_deadlock),
            ("test_cancel_out_of_queue", test_cancel_out_of_queue),
            ("test_cross_queues_dependency", test_cross_queues_dependency),
            ("test_suspended", test_suspended),
            ("test_suspended2", test_suspended2),
            ("test_operations_order", test_operations_order),
            ("test_operations_order2", test_operations_order2),
            ("test_wait_until_finished", test_wait_until_finished),
            ("test_wait_until_finished_operation", test_wait_until_finished_operation),
            ("test_custom_ready_operation", test_custom_ready_operation),
            ("test_mac_os_10_6_cancel_behavour", test_mac_os_10_6_cancel_behavour),
        ]
    }
    
    func test_OperationCount() {
        let queue = OperationQueue()
        let op1 = BlockOperation(block: { sleep(2) })
        queue.addOperation(op1)
        XCTAssertTrue(queue.operationCount == 1)
        queue.waitUntilAllOperationsAreFinished()
        XCTAssertTrue(queue.operationCount == 0)
    }

    func test_OperationPriorities() {
        var msgOperations = [String]()
        let operation1 : BlockOperation = BlockOperation(block: {
            msgOperations.append("Operation1 executed")
        })
        let operation2 : BlockOperation = BlockOperation(block: {
            msgOperations.append("Operation2 executed")
        })
        let operation3 : BlockOperation = BlockOperation(block: {
            msgOperations.append("Operation3 executed")
        })
        let operation4: BlockOperation = BlockOperation(block: {
            msgOperations.append("Operation4 executed")
        })
        operation4.queuePriority = .veryLow
        operation3.queuePriority = .veryHigh
        operation2.queuePriority = .low
        operation1.queuePriority = .normal
        var operations = [Operation]()
        operations.append(operation1)
        operations.append(operation2)
        operations.append(operation3)
        operations.append(operation4)
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.addOperations(operations, waitUntilFinished: true)
        XCTAssertEqual(msgOperations[0], "Operation3 executed")
        XCTAssertEqual(msgOperations[1], "Operation1 executed")
        XCTAssertEqual(msgOperations[2], "Operation2 executed")
        XCTAssertEqual(msgOperations[3], "Operation4 executed")
    }

    func test_isExecutingWorks() {
        class _OperationBox {
            var operation: Operation?
            init() {
                self.operation = nil
            }
        }
        let queue = OperationQueue()
        let opBox = _OperationBox()
        let op = BlockOperation(block: { XCTAssertEqual(true, opBox.operation?.isExecuting) })
        opBox.operation = op
        XCTAssertFalse(op.isExecuting)

        queue.addOperation(op)
        queue.waitUntilAllOperationsAreFinished()
        XCTAssertFalse(op.isExecuting)

        opBox.operation = nil /* break the reference cycle op -> <closure> -> opBox -> op */
    }

    func test_AsyncOperation() {
        let operation = AsyncOperation()
        XCTAssertFalse(operation.isExecuting)
        XCTAssertFalse(operation.isFinished)

        operation.start()

        while !operation.isFinished {
            // do nothing
        }

        XCTAssertFalse(operation.isExecuting)
        XCTAssertTrue(operation.isFinished)
    }
    
    func test_MainQueueGetter() {
        XCTAssertTrue(OperationQueue.main === OperationQueue.main)
        
        /*
         This call is only to check if OperationQueue.main returns a living instance.
         There used to be a bug where subsequent OperationQueue.main call would return a "dangling pointer".
         */
        XCTAssertFalse(OperationQueue.main.isSuspended)
    }
    
    func test_CurrentQueueOnMainQueue() {
        XCTAssertTrue(OperationQueue.main === OperationQueue.current)
    }
    
    func test_CurrentQueueOnBackgroundQueue() {
        let expectation = self.expectation(description: "Background execution")
        
        let operationQueue = OperationQueue()
        operationQueue.addOperation {
            XCTAssertEqual(operationQueue, OperationQueue.current)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func test_CurrentQueueOnBackgroundQueueWithSelfCancel() {
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        let expectation = self.expectation(description: "Background execution")
        operationQueue.addOperation {
            XCTAssertEqual(operationQueue, OperationQueue.current)
            expectation.fulfill()
            // Canceling operation X from inside operation X should not cause the app to a crash
            operationQueue.cancelAllOperations()
        }
        
        waitForExpectations(timeout: 1)
    }

    func test_CurrentQueueWithCustomUnderlyingQueue() {
        let expectation = self.expectation(description: "Background execution")
        
        let operationQueue = OperationQueue()
        operationQueue.underlyingQueue = DispatchQueue(label: "underlying_queue")
        
        operationQueue.addOperation {
            XCTAssertEqual(operationQueue, OperationQueue.current)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func test_CurrentQueueWithUnderlyingQueueResetToNil() {
        let expectation = self.expectation(description: "Background execution")
        
        let operationQueue = OperationQueue()
        operationQueue.underlyingQueue = DispatchQueue(label: "underlying_queue")
        operationQueue.underlyingQueue = nil
        
        operationQueue.addOperation {
            XCTAssertEqual(operationQueue, OperationQueue.current)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }

    func test_cancelDependency() {
        let expectation = self.expectation(description: "Operation should finish")

        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1

        let op1 = BlockOperation() {
            XCTAssert(false, "Should not run")
        }
        let op2 = BlockOperation() {
            expectation.fulfill()
        }

        op2.addDependency(op1)
        op1.cancel()

        queue.addOperation(op1)
        queue.addOperation(op2)

        waitForExpectations(timeout: 1)
    }

    func test_deadlock() {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1

        let expectation1 = self.expectation(description: "Operation should finish")
        let expectation2 = self.expectation(description: "Operation should finish")

        let op1 = BlockOperation {
            expectation1.fulfill()
        }
        op1.name = "op1"

        let op2 = BlockOperation {
            expectation2.fulfill()
        }
        op2.name = "op2"

        op1.addDependency(op2)

        queue.addOperation(op1)
        queue.addOperation(op2)

        waitForExpectations(timeout: 1)
    }
    
    public func test_cancel_out_of_queue() {
        let op = Operation()
        op.cancel()
        
        XCTAssert(op.isCancelled)
        XCTAssertFalse(op.isExecuting)
        XCTAssertFalse(op.isFinished)
    }
    
    public func test_cross_queues_dependency() {
        let queue = OperationQueue()
        let queue2 = OperationQueue()
        
        let expectation1 = self.expectation(description: "Operation should finish")
        let expectation2 = self.expectation(description: "Operation should finish")
        
        let op1 = BlockOperation {
            expectation1.fulfill()
        }
        op1.name = "op1"
        
        let op2 = BlockOperation {
            expectation2.fulfill()
        }
        op2.name = "op2"
        
        op1.addDependency(op2)
        
        queue.addOperation(op1)
        queue2.addOperation(op2)
        
        waitForExpectations(timeout: 1)
    }
    
    public func test_suspended() {
        let queue = OperationQueue()
        queue.isSuspended = true
        
        let expectation1 = self.expectation(description: "Operation should finish")
        let expectation2 = self.expectation(description: "Operation should finish")
        
        let op1 = BlockOperation {
            expectation1.fulfill()
        }
        op1.name = "op1"
        
        let op2 = BlockOperation {
            expectation2.fulfill()
        }
        op2.name = "op2"
        
        queue.addOperation(op1)
        queue.addOperation(op2)
        
        DispatchQueue.global().async {
            queue.isSuspended = false
        }
        
        waitForExpectations(timeout: 1)
    }
    
    public func test_suspended2() {
        let queue = OperationQueue()
        queue.isSuspended = true
        
        let op1 = BlockOperation {}
        op1.name = "op1"
        
        let op2 = BlockOperation {}
        op2.name = "op2"
        
        queue.addOperation(op1)
        queue.addOperation(op2)
        
        op1.cancel()
        op2.cancel()
        
        queue.isSuspended = false
        queue.waitUntilAllOperationsAreFinished()
        
        XCTAssert(op1.isCancelled)
        XCTAssertFalse(op1.isExecuting)
        XCTAssert(op1.isFinished)
        XCTAssert(op2.isCancelled)
        XCTAssertFalse(op2.isExecuting)
        XCTAssert(op2.isFinished)
    }
    
    public func test_operations_order() {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.isSuspended = true
        
        var array = [Int]()
        
        let op1 = BlockOperation {
            array.append(1)
        }
        op1.queuePriority = .normal
        op1.name = "op1"
        
        let op2 = BlockOperation {
            array.append(2)
        }
        op2.queuePriority = .normal
        op2.name = "op2"
        
        let op3 = BlockOperation {
            array.append(3)
        }
        op3.queuePriority = .normal
        op3.name = "op3"
        
        let op4 = BlockOperation {
            array.append(4)
        }
        op4.queuePriority = .normal
        op4.name = "op4"
        
        let op5 = BlockOperation {
            array.append(5)
        }
        op5.queuePriority = .normal
        op5.name = "op5"
        
        queue.addOperation(op1)
        queue.addOperation(op2)
        queue.addOperation(op3)
        queue.addOperation(op4)
        queue.addOperation(op5)
        
        queue.isSuspended = false
        queue.waitUntilAllOperationsAreFinished()
        
        XCTAssertEqual(array, [1, 2, 3, 4, 5])
    }
    
    public func test_operations_order2() {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.isSuspended = true
        
        var array = [Int]()
        
        let op1 = BlockOperation {
            array.append(1)
        }
        op1.queuePriority = .veryLow
        op1.name = "op1"
        
        let op2 = BlockOperation {
            array.append(2)
        }
        op2.queuePriority = .low
        op2.name = "op2"
        
        let op3 = BlockOperation {
            array.append(3)
        }
        op3.queuePriority = .normal
        op3.name = "op3"
        
        let op4 = BlockOperation {
            array.append(4)
        }
        op4.queuePriority = .high
        op4.name = "op4"
        
        let op5 = BlockOperation {
            array.append(5)
        }
        op5.queuePriority = .veryHigh
        op5.name = "op5"
        
        queue.addOperation(op1)
        queue.addOperation(op2)
        queue.addOperation(op3)
        queue.addOperation(op4)
        queue.addOperation(op5)
        
        queue.isSuspended = false
        queue.waitUntilAllOperationsAreFinished()
        
        XCTAssertEqual(array, [5, 4, 3, 2, 1])
    }
    
    func test_wait_until_finished() {
        let queue1 = OperationQueue()
        let queue2 = OperationQueue()
        
        let op1 = BlockOperation { sleep(1) }
        let op2 = BlockOperation { }
        
        op2.addDependency(op1)
        
        queue1.addOperation(op1)
        queue2.addOperation(op2)
        
        queue2.waitUntilAllOperationsAreFinished()
        XCTAssertEqual(queue2.operationCount, 0)
    }
    
    func test_wait_until_finished_operation() {
        let queue1 = OperationQueue()
        let op1 = BlockOperation { sleep(1) }
        queue1.addOperation(op1)
        op1.waitUntilFinished()
        XCTAssertEqual(queue1.operationCount, 0)
    }
    
    func test_custom_ready_operation() {
        class CustomOperation: Operation {
            
            private var _isReady = false
            
            override var isReady: Bool {
                return _isReady
            }
            
            func setIsReady() {
                willChangeValue(forKey: "isReady")
                _isReady = true
                didChangeValue(forKey: "isReady")
            }
            
        }
        
        let expectation = self.expectation(description: "Operation should finish")
        
        let queue1 = OperationQueue()
        let op1 = CustomOperation()
        let op2 = BlockOperation(block: {
            expectation.fulfill()
        })
        
        queue1.addOperation(op1)
        queue1.addOperation(op2)
        
        waitForExpectations(timeout: 1)
        
        XCTAssertEqual(queue1.operationCount, 1)
        op1.setIsReady()
        queue1.waitUntilAllOperationsAreFinished()
        XCTAssertEqual(queue1.operationCount, 0)
    }
    
    func test_mac_os_10_6_cancel_behavour() {
        
        let expectation1 = self.expectation(description: "Operation should finish")
        let expectation2 = self.expectation(description: "Operation should finish")
        
        let queue1 = OperationQueue()
        let op1 = BlockOperation(block: {
            expectation1.fulfill()
        })
        let op2 = BlockOperation(block: {
            expectation2.fulfill()
        })
        let op3 = BlockOperation(block: {
            // empty
        })
        
        op1.addDependency(op2)
        op2.addDependency(op3)
        op3.addDependency(op1)
        
        queue1.addOperation(op1)
        queue1.addOperation(op2)
        queue1.addOperation(op3)
        
        XCTAssertEqual(queue1.operationCount, 3)
        
        op3.cancel()
        
        waitForExpectations(timeout: 1)
    }
}

class AsyncOperation: Operation {

    private let queue = DispatchQueue(label: "async.operation.queue")
    private let lock = NSLock()

    private var _executing = false
    private var _finished = false

    override internal(set) var isExecuting: Bool {
        get {
            lock.lock()
            let wasExecuting = _executing
            lock.unlock()
            return wasExecuting
        }
        set {
            if isExecuting != newValue {
                willChangeValue(forKey: "isExecuting")
                lock.lock()
                _executing = newValue
                lock.unlock()
                didChangeValue(forKey: "isExecuting")
            }
        }
    }

    override internal(set) var isFinished: Bool {
        get {
            lock.lock()
            let wasFinished = _finished
            lock.unlock()
            return wasFinished
        }
        set {
            if isFinished != newValue {
                willChangeValue(forKey: "isFinished")
                lock.lock()
                _finished = newValue
                lock.unlock()
                didChangeValue(forKey: "isFinished")
            }
        }
    }

    override var isAsynchronous: Bool {
        return true
    }

    override func start() {
        if isCancelled {
            isFinished = true
            return
        }

        isExecuting = true

        queue.async {
            sleep(1)
            self.isExecuting = false
            self.isFinished = true
        }
    }

}
