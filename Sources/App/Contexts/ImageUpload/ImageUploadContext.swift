//
//  ImageUploadContext.swift
//
//
//  Created by Imen Ksouri on 18/01/2024.
//

import Foundation
import Vapor

enum PictureType: String {
    case profile
    case article
}

struct ImageUploadContext: Encodable {
    let title: String
    let pictureType: String
    let reference: String
    let currentImage: String?
    let userLoggedIn: Bool
    let articleId: String?
}

struct ImageUploadData: Content {
    let picture: Data
}
