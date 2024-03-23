//
//  SettingsView.swift
//  ScreenZ
//
//  Created by 周源坤 on 2022/6/1.
//

import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @State var enableMenuBar = true
    @State var enableLaunchAtLogin = true
    
    func updateEnableMenuBar() {
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest = Preference.fetchRequest()
        let result = try! context.fetch(fetchRequest).first!
        result.enableMenuBar = enableMenuBar
        try! context.save()
        
        NotificationCenter.default.post(name: Notification.Name("MenuBarSettingChanged"), object: nil)
    }
    
    var body: some View {
        
        VStack {
            HStack {
                Image("diamond")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                VStack {
                    HStack {
                        Text("Enable wallpaper extends to menu bar")
                        Spacer()
                        Toggle("", isOn: $enableMenuBar)
                        .onChange(of: enableMenuBar, updateEnableMenuBar)
                    }
                    HStack {
                        Text("Enable app launch at login")
                        Spacer()
                        Toggle("", isOn: $enableLaunchAtLogin)
                        .onChange(of: enableLaunchAtLogin) {
                            do {
                                if enableLaunchAtLogin {
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
                            PersistenceController.shared.cleanFolder()
                            doneResponse()
                        } label: {
                            Text("Clean video storage")
                        }
                    }
                    HStack {
                        Text("Remove all your videos stored in this app.")
                        Spacer()
                        Button {
                            PersistenceController.shared.deleteAllThemes()
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
        .onAppear {
            let context = PersistenceController.shared.container.viewContext
            let fetchRequest = Preference.fetchRequest()
            let result = try! context.fetch(fetchRequest).first!
            enableMenuBar = result.enableMenuBar
            enableLaunchAtLogin = result.enableAutoSetup
        }
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
