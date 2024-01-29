//
//  SearchContext.swift
//
//
//  Created by Imen Ksouri on 12/01/2024.
//

import Foundation

struct SearchContext: Encodable {
    let title: String
    let articles: [Article]?
    let userLoggedIn: Bool
}
