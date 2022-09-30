//
// Created by Andriy Druk on 06.12.2019.
//

import Foundation

/**
 Simple task de-duplicator that run completion for all started tasks, but run only one unique task at the moment.
 (Note: After task completion new task with the same key will start new task operation)
*/
public final class TaskDeduplicator<T> {

    public typealias Completion = (T?, Error?) -> Void
    public typealias Task = (@escaping Completion) -> Void

    private var currentTasks = [String: [Completion]]()
    private let lock = NSLock()

    /// Start task with key and completion
    public func startTask(key: String, task: Task, completion: @escaping Completion) {
        let alreadyStarted = addCompletion(for: key, completion: completion)
        if !alreadyStarted {
            task { result, error in
                let completions = self.removeCompletions(for: key)
                completions.forEach { completion in
                    completion(result, error)
                }
            }
        }
    }

    private func addCompletion(for key: String, completion: @escaping Completion) -> Bool {
        return lock.sync {
            var completions = currentTasks[key] ?? [Completion]()
            completions.append(completion)
            currentTasks[key] = completions
            return completions.count > 1
        }
    }

    private func removeCompletions(for key: String) -> [Completion] {
        return lock.sync {
            return currentTasks.removeValue(forKey: key) ?? [Completion]()
        }
    }

}
