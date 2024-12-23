//
//  AllThemeView.swift
//  ScreenZ
//
//  Created by 周源坤 on 2022/6/1.
//

import SwiftUI
import SwiftData

struct AllThemeView: View {
    @Query var videos: [Video]
    var body: some View {
        List {
            ForEach(videos) { video in
                VideoCell(video: video)
            }
        }
    }
}

struct VideoCell: View {
    @Environment(\.modelContext) private var context
    
    
    let video: Video
    @State var inputName: String = ""
    @State var statusInfo: AddThemeStatus?
    @State var showStatusAlert: Bool = false
    @State var showDeleteAlert: Bool = false
    @State var showRenameAlert: Bool = false
    var body: some View {
        let (picURL, _) = getResourcesURL(videoID: video.id)
        HStack {
            Text(video.name)
                .font(.title)
                .frame(width: 200)
            
            Image(nsImage: NSImage(contentsOf: picURL)!)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 192 * 2, height: 108 * 2)
            
            HStack {
                CircleButton(color: .green, systemName: "paintbrush") {
                    NotificationCenter.default.post(name: Notification.Name("videoChanged"), object: video.id)
                }
                
                CircleButton(color: .yellow, systemName: "pencil") {
                    showRenameAlert = true
                }
                
                CircleButton(color: .red, systemName: "trash") {
                    showDeleteAlert = true
                }

            }
            .frame(width: 200)
        }
        .background {
            ZStack {
                Image(nsImage: NSImage(contentsOf: picURL)!)
                Rectangle()
                    .fill(.ultraThinMaterial)
            }
            .ignoresSafeArea()
        }
        .alert("Coming Soon", isPresented: $showRenameAlert) {
            TextField("Enter name here", text: $inputName)
            Button("Rename") {
                if inputName == "" {
                    statusInfo = AddThemeStatus(type: .Error, description: "Name is required")
                    showStatusAlert = true
                    return
                }
                video.name = inputName
                do {
                    try context.save()
                } catch {
                    showStatusAlert = true
                    statusInfo = AddThemeStatus(type: .Error, description: error.localizedDescription)
                }
            }
            Button("Cancel") {
                
            }
        }
        .alert("Delete this theme ?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                context.delete(video)
                do {
                    try context.save()
                } catch {
                    showStatusAlert = true
                    statusInfo = AddThemeStatus(type: .Error, description: error.localizedDescription)
                }
            }
        }
    }
}

struct CircleButton : View {
    
    let color: Color
    let systemName: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action, label: {
            ZStack {
                Circle()
                    .fill(color)
                Image(systemName: systemName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()
            }
        })
        .buttonStyle(.plain)
    }
}
