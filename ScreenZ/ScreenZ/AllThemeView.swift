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
    @State var showDeleteAlert: Bool = false
    @State var showRenameAlert: Bool = false
    @State var inputName: String = ""
    @State var statusInfo: AddThemeStatus?
    @State var showStatusAlert: Bool = false
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
                    
                    HStack {
                        CircleButton(color: .green, systemName: "paintbrush") {
                            guard let url = video.url else {
                                return
                            }
                            NotificationCenter.default.post(name: Notification.Name("videourlChanged"), object: url)
                            targetVideoName = video.name!
                        }
                        
                        CircleButton(color: .yellow, systemName: "pencil") {
                            showRenameAlert = true
                        }
                        .alert("Coming Soon", isPresented: $showRenameAlert) {
//                            TextField("Enter name here", text: $inputName)
//                            Button("Rename") {
//                                if inputName == "" || PersistenceController.shared.fileExists(inputName) {
//                                    statusInfo = AddThemeStatus(type: .Error, description: "Name invalid (null or duplicate)")
//                                    showStatusAlert = true
//                                    return
//                                }
//                                
//                                PersistenceController.shared.renameVideo(src: video.name!, dst: inputName)
//                                
//                            }
                            Button("Cancel") {
                                
                            }
                        }
                        
                        CircleButton(color: .red, systemName: "trash") {
                            showDeleteAlert = true
                        }
                        .alert("Delete this theme ?", isPresented: $showDeleteAlert) {
                            Button("Delete", role: .destructive) {
                                let viewContext = PersistenceController.shared.container.viewContext
                                viewContext.delete(video)
                                try! viewContext.save()
                            }
                        }
                    }
                    .frame(width: 200)
                }
                .background {
                    ZStack {
                        Image(nsImage: NSImage(contentsOf: video.photo!)!)
                        Rectangle()
                            .fill(.ultraThinMaterial)
                    }
                    .ignoresSafeArea()
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
