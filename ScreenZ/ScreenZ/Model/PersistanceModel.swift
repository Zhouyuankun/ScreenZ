//
//  PersistanceModel.swift
//  ScreenZ
//
//  Created by 周源坤 on 12/19/24.
//

import Foundation
import SwiftData

///
/// Store Video entity
/// Use id as folder name in documents to save photo.png and video.mp4
///
@Model
public final class Video {
    @Attribute(.unique) public var id: String = UUID().uuidString
    public var name: String
    
    init(name: String) {
        self.name = name
    }
}

//Get the picture url and video url
public func getResourcesURL(videoID: String?) -> (URL, URL) {
    guard let videoID = videoID else {
        return (Bundle.main.url(forResource: "demo", withExtension: "png")!, Bundle.main.url(forResource: "demo", withExtension: "mp4")!)
    }
    let folderURL = FileManager.default.folderInDocument(folderName: videoID)
    let picURL = folderURL.appendingPathComponent("picture.png")
    let vidURL = folderURL.appendingPathComponent("video.mp4")
    return (picURL, vidURL)
}



