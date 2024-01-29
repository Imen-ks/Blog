//
//  File.swift
//  
//
//  Created by Imen Ksouri on 02/01/2024.
//

import Foundation

struct AllUsersContext: Encodable {
  let title = WebsiteView.allUsers.title
  let users: [User.Public]
  let userLoggedIn: Bool
}
