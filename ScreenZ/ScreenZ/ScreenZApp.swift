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
    var isActive = true
    var mainWindow: NSWindow?
    

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        constructMenu()
        constructWallpaper()
        constructPlayer(Bundle.main.url(forResource: "demo", withExtension: "mp4")!)
        constructFirstTime()
        //constructAutoStart()
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
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.contentView = playerView
        window.center()
        
        let windowController = NSWindowController(window: window)
        windowController.showWindow(self)
    }
    
    func constructPlayer(_ url: URL) {
        playVideo(url)
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) {[weak self] noti in
            guard let strongSelf = self else { return }
            strongSelf.player.seek(to: CMTime.zero)
            strongSelf.player.play()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(changeVideo), name: Notification.Name("videourl"), object: nil)
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
    
    func constructFirstTime() {
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest = Preference.fetchRequest()
        let result = try! context.fetch(fetchRequest).first
        if result == nil {
            let pref = Preference(context: context)
            pref.enableAutoSetup = false
            pref.enableMenuBar = false
        }
    }
    
//    func constructAutoStart() {
//        let launcherAppId = "com.celeglow.Launch"
//        let runningApps = NSWorkspace.shared.runningApplications
//        let isRunning = !runningApps.filter { $0.bundleIdentifier == launcherAppId }.isEmpty
//
//        SMLoginItemSetEnabled(launcherAppId as CFString, true)
//
//        if isRunning {
//            DistributedNotificationCenter.default().post(name: .killLauncher, object: Bundle.main.bundleIdentifier!)
//        }
//    }
    
    func playVideo(_ url: URL) {
        let url = url

        let filepath = (url.getFileName()!+".png").foundFile(in: .documentDirectory)
        if FileManager.default.fileExists(atPath: filepath.path) {
            refreshDesktop(filepath)
        } else {
            if url == Bundle.main.url(forResource: "demo", withExtension: "mp4")! {
                refreshDesktop(Bundle.main.url(forResource: "demo", withExtension: "png")!)
            } else {
                refreshDesktop(("tmp.png").foundFile(in: .documentDirectory))
            }
            
        }
            
        player = AVPlayer(url: url)
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
            let transparentImage = URL(fileURLWithPath: "/System/Library/PreferencePanes/DesktopScreenEffectsPref.prefPane/Contents/Resources/DesktopPictures.prefPane/Contents/Resources/Transparent.tiff")
            try? NSWorkspace.shared.setDesktopImageURL(transparentImage, for: NSScreen.main!, options: [.fillColor:NSColor.black])
        }
    }
    
    func getPreference() -> Preference {
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest = Preference.fetchRequest()
        let result = try! context.fetch(fetchRequest).first!
        return result
    }
    
    @objc func changeVideo(notification: NSNotification) {
        if let url = notification.object as? URL {
            playVideo(url)
        }
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
        if isActive {
            player.pause()
            print("pause")
        } else {
            player.play()
            print("play")
        }
        isActive.toggle()
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
