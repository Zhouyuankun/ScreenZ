//
//  AllThemeView.swift
//  ScreenZ
//
//  Created by 周源坤 on 2022/6/1.
//

import SwiftUI

struct AllThemeView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Video.name, ascending: true)],
        animation: .default
        )
    private var videos: FetchedResults<Video>
    
    @State var targetVideoName: String = ""
    
    var body: some View {
        List {
            ForEach(videos) { video in
                HStack {
                    Text(video.name!)
                        .font(.title)
                        .frame(width: 200)
                    
                    Image(nsImage: NSImage(contentsOf: video.photo!)!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 192 * 2, height: 108 * 2)
                }
                .shadow(color: Color(nsColor: .labelColor), radius: targetVideoName == video.name ? 10: 0, x: 0, y: targetVideoName == video.name ? 10: 0)
                .background {
                    ZStack {
                        Image(nsImage: NSImage(contentsOf: video.photo!)!)
                        Rectangle()
                            .fill(.ultraThinMaterial)
                    }
                    .ignoresSafeArea()
                }
                .onTapGesture {
                    guard let url = video.url else {
                        return
                    }
                    NotificationCenter.default.post(name: Notification.Name("videourl"), object: url)
                }
                .onHover { _ in
                    targetVideoName = video.name!
                }
                .onLongPressGesture {
                    let alert = NSAlert()
                    alert.messageText = "Are you sure to delete ?"
                    alert.addButton(withTitle: "Sure")
                    alert.addButton(withTitle: "Cancel")
                    if alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn {
                        let context = PersistenceController.shared.container.viewContext
                        context.delete(video)
                        try! context.save()
                    }
                }
            }
        }
    }
}

