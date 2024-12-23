//
//  SettingsView.swift
//  ScreenZ
//
//  Created by 周源坤 on 2022/6/1.
//

import SwiftUI
import ServiceManagement
import SwiftData

struct SettingsView: View {
    @AppStorage(UserSettingsKey.enableBlackMenuBar.rawValue) private var enableBlackMenuBar: Bool = false
    @AppStorage(UserSettingsKey.enableAutoSetUp.rawValue) private var enableAutoSetUp: Bool = false
    @Environment(\.modelContext) private var context
    
    var body: some View {
        
        VStack {
            HStack {
                Image("diamond")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                VStack {
                    HStack {
                        Text("Enable black menu bar")
                        Spacer()
                    
                        Toggle("", isOn: $enableBlackMenuBar)
                            .onChange(of: enableBlackMenuBar, initial: false) {
                                NotificationCenter.default.post(name: Notification.Name("MenuBarSettingChanged"), object: nil)
                            }
                    }
                    HStack {
                        Text("Enable app launch at login")
                        Spacer()
                        Toggle("", isOn: $enableAutoSetUp)
                            .onChange(of: enableAutoSetUp, initial: false) {
                            do {
                                if enableAutoSetUp {
                                    try SMAppService.mainApp.register()
                                } else {
                                    try SMAppService.mainApp.unregister()
                                }
                            } catch {
                                Swift.print(error.localizedDescription)
                            }
                        }
                    }
                    HStack {
                        Text("Clean trash videos on this app's folder.")
                        Spacer()
                        Button {
                            let descriptor = FetchDescriptor<Video>()
                            let results: [Video] = try! context.fetch(descriptor)
                            let videoIDs = results.map {$0.id}
                            let documentURL = FileManager.default.appDocumentFolder
                            let fileURLs = try! FileManager.default.contentsOfDirectory(at: documentURL, includingPropertiesForKeys: [.isDirectoryKey],options: [.skipsHiddenFiles])
                            let trashs = fileURLs.filter {videoIDs.contains($0.lastPathComponent) == false}
                            for trash in trashs {
                                try! FileManager.default.removeItem(at: trash)
                            }
                            doneResponse()
                        } label: {
                            Text("Clean video storage")
                        }
                    }
                    HStack {
                        Text("Remove all your videos stored in this app.")
                        Spacer()
                        Button {
                            let descriptor = FetchDescriptor<Video>()
                            let results: [Video] = try! context.fetch(descriptor)
                            for result in results {
                                context.delete(result)
                                let folderURL = FileManager.default.folderInDocument(folderName: result.id)
                                if FileManager.default.fileExists(atPath: folderURL.absoluteString) {
                                    try! FileManager.default.removeItem(at: folderURL)
                                }
                            }
                            doneResponse()
                        } label: {
                            Text("Delete all themes")
                        }
                    }
                }
                .frame(width: 500)
            }

            
            Spacer()

            VStack {
                Spacer()
                Image("Z_icon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                Text("Designed by")
                Text("Celeglow")
                    .bold()
                Text("All rights reserved to Celeglow")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
        }
        .padding(.vertical, 100)
    }
    
    func doneResponse() {
        let alert2 = NSAlert()
        alert2.messageText = NSLocalizedString("Operation success", comment: "")
        alert2.addButton(withTitle: NSLocalizedString("OK", comment: ""))
        alert2.runModal()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
