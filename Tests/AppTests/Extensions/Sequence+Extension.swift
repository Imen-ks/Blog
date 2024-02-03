//
//  Sequence+Extension.swift
//
//
//  Created by Imen Ksouri on 02/02/2024.
//

import Foundation

extension Sequence {
    func asyncForEach(
        _ operation: (Element) async throws -> Void
    ) async rethrows {
        for element in self {
            try await operation(element)
        }
    }
}
