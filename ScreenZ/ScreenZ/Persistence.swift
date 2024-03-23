//
//  Persistence.swift
//  ScreenZ
//
//  Created by 周源坤 on 2022/5/31.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ScreenZ")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func getCurrentVideoURL() -> URL? {
        let context = self.container.viewContext
        let fetchRequest = Preference.fetchRequest()
        let result = try! context.fetch(fetchRequest).first!
        let url = result.currentVideoURL
        //Check if URL is valid
        if url != nil && FileManager.default.fileExists(atPath: url!.path()) {
            return url
        } else {
            return nil
        }
        
    }
    
    func storeURL(url: URL) {
        let context = self.container.viewContext
        let fetchRequest = Preference.fetchRequest()
        let result = try! context.fetch(fetchRequest).first!
        result.currentVideoURL = url
        try! self.container.viewContext.save()
    }
    
    func deleteAllEntryVideo() {
        let context = self.container.viewContext
        let fetchRequest = Video.fetchRequest()
        let result = try! context.fetch(fetchRequest)
        for v in result {
            context.delete(v)
        }
    }
    
    func deleteAllEntryPreference() {
        let context = self.container.viewContext
        let fetchRequest = Preference.fetchRequest()
        let result = try! context.fetch(fetchRequest)
        for v in result {
            context.delete(v)
        }
    }
    
    func fileExists(_ name: String) -> Bool {
        let fetchRequest = Video.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)
        let result = try! self.container.viewContext.fetch(fetchRequest)
        return result.count == 1
    }
    
    func renameVideo(src: String, dst: String) {
        let fetchRequest = Video.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", src)
        let result = try! self.container.viewContext.fetch(fetchRequest).first!
        result.name = dst
        try! container.viewContext.save()
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
    
    
}
