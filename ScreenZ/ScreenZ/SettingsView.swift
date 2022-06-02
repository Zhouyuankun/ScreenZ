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
    //@State var enableAutoSetup = true
    
    var body: some View {
        
        VStack {
            HStack {
                Image("diamond")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                VStack {
                    HStack {
                        Text("Enable wallpaper extends to menu bar ")
                        Spacer()
                        Toggle("", isOn: $enableMenuBar)
                        .onChange(of: enableMenuBar) { _ in
                            let context = PersistenceController.shared.container.viewContext
                            let fetchRequest = Preference.fetchRequest()
                            let result = try! context.fetch(fetchRequest).first!
                            result.enableMenuBar = enableMenuBar
                            try! context.save()
                        }
                    }
        //            HStack {
        //                Text("Enable app auto start ")
        //                Toggle("", isOn: $enableAutoSetup)
        //                .onChange(of: enableAutoSetup) { _ in
        //                    SMLoginItemSetEnabled("com.celeglow.ScreenZ" as CFString,
        //                    enableAutoSetup)
        //                }
        //            }
                    HStack {
                        Text("Clean trash videos on this app's folder.")
                        Spacer()
                        Button {
                            cleanFolder()
                            doneResponse()
                        } label: {
                            Text("Clean video storage")
                        }
                    }
                    HStack {
                        Text("Remove all your videos stored in this app.")
                        Spacer()
                        Button {
                            deleteAllThemes()
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
            //enableAutoSetup = result.enableAutoSetup
        }
    }
    
    func cleanFolder() {
        let fetchRequest = Video.fetchRequest()
        let viewContext = PersistenceController.shared.container.viewContext
        let result = try! viewContext.fetch(fetchRequest)
        let names = result.map {$0.name!}
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURLs = try! FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil,options: .skipsHiddenFiles)
        let trashs = fileURLs.filter {!names.contains($0.getFileName()!)}
        for trash in trashs {
            try! FileManager.default.removeItem(at: trash)
        }
    }
    
    func deleteAllThemes() {
        let fetchRequest = Video.fetchRequest()
        let viewContext = PersistenceController.shared.container.viewContext
        let result = try! viewContext.fetch(fetchRequest)
        for res in result {
            viewContext.delete(res)
        }
        
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil,options: .skipsHiddenFiles)
            for fileURL in fileURLs {
                try FileManager.default.removeItem(at: fileURL)
            }
        } catch  { print(error) }
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
