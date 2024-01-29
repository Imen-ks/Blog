//
//  SessionDataVariable.swift
//
//
//  Created by Imen Ksouri on 08/01/2024.
//

import Foundation
import Redis

struct SessionDataVariable {
    static let userId = "USER-ID"
}

struct Caching {
    static let userId = RedisKey("userId")
}
