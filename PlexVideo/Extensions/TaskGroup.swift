//
//  TaskGroup.swift
//  PlexVideo
//
//  Created by Tomas Harkema on 10/06/2021.
//

import Foundation

func whenAll<T>(tasks: [Task.Handle<T, Error>]) async throws -> [T] {
  try await withThrowingTaskGroup(of: [T].self, body: { group in
    for task in tasks {
      group.async {
        [try await task.get()]
      }
    }
    return try await group.reduce([], +)
  })
}

/*
 whenAll(tasks: sections.map { s in
   async {
   (try await Api.shared.all(key: s.key)).MediaContainer.Metadata
   }
 })
 */
