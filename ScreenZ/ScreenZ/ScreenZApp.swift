//
//  ScreenZApp.swift
//  ScreenZ
//
//  Created by 周源坤 on 2022/5/31.
//

import SwiftUI
import AVKit


@main
struct ScreenZApp: App {
    // inject into SwiftUI life-cycle via adaptor !!!
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        Settings {
            
        }
    }
}

extension Notification.Name {
    static let killLauncher = Notification.Name("killLauncher")
}


class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var statusItem: NSStatusItem!
    private var window: NSWindow!
    var playerView: AVPlayerView!
    var player: AVPlayer!
    var mainWindow: NSWindow?
    var currentVideoURL: URL?
    

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let launchedBefore = UserDefaults.standard.bool(forKey: "launchedBefore")
        if !launchedBefore  {
            constructFirstTime()
            UserDefaults.standard.set(true, forKey: "launchedBefore")
        }
        constructMenu()
        constructWallpaper()
        constructPlayer()
        constructObervers()
        
        //PersistenceController.shared.deleteAllEntryVideo()
    }
    
    func constructMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(named: "StatusBarButtonImage")
        }
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: NSLocalizedString("Show panel", comment: ""), action: #selector(showPanel), keyEquivalent: "S"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: NSLocalizedString("Quit", comment: ""), action: #selector(NSApplication.terminate), keyEquivalent: "Q"))
        statusItem.menu = menu
    }
    
    func constructWallpaper() {
        let rect = NSRect(x: 0, y: 0, width: NSScreen.main!.frame.width, height: NSScreen.main!.frame.height)
        playerView = AVPlayerView()
        
        window = NSWindow(contentRect: rect, styleMask: .borderless, backing: .buffered, defer: false)
        window.backgroundColor = NSColor.clear
        window.hasShadow = false
        window.isMovableByWindowBackground = false
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.stationary]
        window.contentView = playerView
        window.center()
        
        let windowController = NSWindowController(window: window)
        windowController.showWindow(self)
    }
    
    func constructObervers() {
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) {[weak self] noti in
            self?.player.seek(to: CMTime.zero)
            self?.player.play()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(changeVideo), name: Notification.Name("videourlChanged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshVideo), name: Notification.Name("MenuBarSettingChanged"), object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(
                self,
                selector: #selector(spaceChanged),
                name: NSWorkspace.activeSpaceDidChangeNotification,
                object: nil
            )

        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(onWakeNote),
            name: NSWorkspace.didWakeNotification, object: nil)

        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(onSleepNote),
            name: NSWorkspace.willSleepNotification, object: nil)
    }
    
    func constructPlayer() {
        currentVideoURL = PersistenceController.shared.getCurrentVideoURL()
        playVideo(currentVideoURL)
    }
    
    func constructFirstTime() {
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest = Preference.fetchRequest()
        let result = try! context.fetch(fetchRequest).first
        if result == nil {
            let pref = Preference(context: context)
            pref.enableAutoSetup = false
            pref.enableMenuBar = false
            pref.currentVideoURL = nil
        }
        
    }
    
    func playVideo(_ videoURLOpt: URL?) {
        var videoURL: URL
        if videoURLOpt != nil {
            videoURL = videoURLOpt!
            currentVideoURL = videoURL
            PersistenceController.shared.storeURL(url: videoURL)
            refreshDesktop((videoURL.getFileName()!+".png").foundFile(in: .documentDirectory))
        } else {
            videoURL = Bundle.main.url(forResource: "demo", withExtension: "mp4")!
            refreshDesktop(Bundle.main.url(forResource: "demo", withExtension: "png")!)
        }
            
        player = AVPlayer(url: videoURL)
        player.isMuted = true
        playerView.player = player
        playerView.controlsStyle = AVPlayerViewControlsStyle.none
        playerView.videoGravity = .resizeAspectFill
        playerView.updatesNowPlayingInfoCenter = false
        player.play()
        
    }
    
    func refreshDesktop(_ dstURL: URL) {
        if getPreference().enableMenuBar {
            try? NSWorkspace.shared.setDesktopImageURL(URL(fileURLWithPath: ""), for: NSScreen.main!, options: [:])
            usleep(useconds_t(0.4 * Double(USEC_PER_SEC)))
            try? NSWorkspace.shared.setDesktopImageURL(dstURL, for: NSScreen.main!, options: [:])
        } else {
            try? NSWorkspace.shared.setDesktopImageURL(Bundle.main.url(forResource: "black", withExtension: "jpg")!, for: NSScreen.main!, options: [:])
        }
    }
    
    func getPreference() -> Preference {
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest = Preference.fetchRequest()
        let result = try! context.fetch(fetchRequest).first!
        return result
    }
    
    func testWallpaperWindowVisibility() -> Bool {
        let options = CGWindowListOption(arrayLiteral: CGWindowListOption.optionOnScreenOnly)
        let windowListInfo = CGWindowListCopyWindowInfo(options, CGWindowID(0))
        guard let infoList = windowListInfo as NSArray? as? [[String: AnyObject]] else { return true }
        let targetN = infoList.filter { item in
            let wBounds = item["kCGWindowNumber"]
            let winid = wBounds as? Int
            if let nonnilid = winid, nonnilid == window.windowNumber {
                return true
            }
            return false
        }
        return targetN.isEmpty == false
    }
    
    @objc func changeVideo(notification: NSNotification) {
        let url = notification.object as? URL
        playVideo(url)
    }
    
    @objc func refreshVideo(notification: NSNotification) {
        playVideo(currentVideoURL)
    }
    
    @objc func onWakeNote(note: NSNotification) {
       
        player.seek(to: CMTime.zero)
        player.play()
    }

    @objc func onSleepNote(note: NSNotification) {
        
        player.pause()
    }
    
    @objc func showPanel() {
        if let mainWindow = mainWindow {
            let controller = NSWindowController(window: mainWindow)
            controller.showWindow(nil)
        } else {
            let contentView = NSHostingController(rootView: ContentView().environment(\.managedObjectContext, PersistenceController.shared.container.viewContext))
            let window = NSWindow(contentViewController: contentView)
            mainWindow = window
            window.setContentSize(NSSize(width: 1000, height: 800))
            window.center()
            window.title = "ScreenZ"
            let controller = NSWindowController(window: window)
            controller.showWindow(nil)
        }
        
        
    }
    
    @objc func spaceChanged() {
        if testWallpaperWindowVisibility() {
            player.play()
            print("play")
        } else {
            player.pause()
            print("pause")
        }
    }
}

extension String {
    func foundFile(in dir: FileManager.SearchPathDirectory) -> URL{
        return FileManager.default.urls(for: dir, in: .userDomainMask)[0].appendingPathComponent(self)
    }
}

extension URL {
    func getFileName() -> String?{
        if self.isFileURL {
            return self.deletingPathExtension().lastPathComponent
        }
        return nil
    }
}
