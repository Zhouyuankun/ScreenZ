//
//  ScreenZApp.swift
//  ScreenZ
//
//  Created by 周源坤 on 2022/5/31.
//

import SwiftUI
import AVKit
import SwiftData
import Combine

@main
struct ScreenZApp: App {
    // inject into SwiftUI life-cycle via adaptor !!!
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @Environment(\.openWindow) private var openWindow
    
    var body: some Scene {
        //Menu first, the window group will not show
        MenuBarExtra("ScreenZ", image: "StatusBarButtonImage") {
            Button("Show panel") {
                openWindow(id: "mainPan")
            }
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        
        WindowGroup(id: "mainPan") {
            ContentView()
                .frame(width: 1000, height: 800)
                .modelContainer(for: [Video.self])
        }
    }
}

extension Notification.Name {
    static let killLauncher = Notification.Name("killLauncher")
}


class AppDelegate: NSObject, NSApplicationDelegate {
    
    var container: ModelContainer? = {
        try? ModelContainer(for: Video.self)
    }()
    
    private lazy var videoPlayer: AVPlayer = {
        var player = AVPlayer()
        player.isMuted = true
        return player
    }()
    
    private lazy var videoView: AVPlayerView = {
        var view = AVPlayerView()
        view.controlsStyle = AVPlayerViewControlsStyle.none
        view.videoGravity = .resizeAspectFill
        view.updatesNowPlayingInfoCenter = false
        view.player = videoPlayer
        return view
    }()
    
    private lazy var videoWindow: NSWindow = {
        let rect = NSRect(x: 0, y: 0, width: NSScreen.main!.frame.width, height: NSScreen.main!.frame.height)
        var window = NSWindow(contentRect: rect, styleMask: .borderless, backing: .buffered, defer: false)
        window.backgroundColor = NSColor.clear
        window.hasShadow = false
        window.isMovableByWindowBackground = false
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.stationary]
        window.contentView = videoView
        window.center()
        return window
    }()
    
    private var cancellables = Set<AnyCancellable>()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if !UserDefaults.standard.isInitialized {
            constructFirstTime()
        }
        loadVideoWindow()
        loadVideoSource()
        constructObservers()
    }
    
    func loadVideoWindow() {
        NSWindowController(window: videoWindow).showWindow(nil)
    }
    
    func constructObservers() {
        NotificationCenter.default.publisher(for: AVPlayerItem.didPlayToEndTimeNotification).sink {[weak self] _ in
            self?.videoPlayer.seek(to: CMTime.zero)
            self?.videoPlayer.play()
        }.store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: Notification.Name("videourlChanged")).sink {[weak self] noti in
            guard let url = noti.object as? URL else {return}
            self?.playTempVideo(videoURL: url)
        }.store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: Notification.Name("videoChanged")).sink {[weak self] noti in
            let videoID = noti.object as? String
            self?.playVideo(id: videoID)
        }.store(in: &cancellables)
        
        
        NotificationCenter.default.publisher(for: Notification.Name("MenuBarSettingChanged")).sink {[weak self] _ in
            self?.playVideo(id: UserDefaults.standard.currentVideoID)
        }.store(in: &cancellables)
        
        //The folllowing noti are from NSWorkspace.shared.notificationCenter
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.activeSpaceDidChangeNotification).sink {[weak self] _ in
            guard let strongSelf = self else { return }
            if strongSelf.testWallpaperWindowVisibility() {
                strongSelf.videoPlayer.play()
                print("play")
            } else {
                strongSelf.videoPlayer.pause()
                print("pause")
            }
        }.store(in: &cancellables)
        
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didWakeNotification).sink {[weak self] _ in
            print("On wake up")
            self?.videoPlayer.seek(to: CMTime.zero)
            self?.videoPlayer.play()
        }.store(in: &cancellables)
        
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.willSleepNotification).sink {[weak self] _ in
            print("On sleep")
            self?.videoPlayer.pause()
        }.store(in: &cancellables)

    }
    
    func loadVideoSource() {
        playVideo(id: UserDefaults.standard.currentVideoID)
    }
    
    func playVideo(id: String?) {
        let (picURL, vidURL) = getResourcesURL(videoID: id)
        if id != nil {UserDefaults.standard.set(currentVideoID: id!)}
        refreshDesktop(picURL)
        videoPlayer.replaceCurrentItem(with: AVPlayerItem(url: vidURL))
        videoPlayer.play()
    }
    
    func playTempVideo(videoURL: URL) {
        var picURL: URL
        if videoURL == Bundle.main.url(forResource: "demo", withExtension: "mp4")! {
            picURL = Bundle.main.url(forResource: "demo", withExtension: "png")!
        } else {
            (picURL, _) = getResourcesURL(videoID: "tmp")
        }
        refreshDesktop(picURL)
        videoPlayer.replaceCurrentItem(with: AVPlayerItem(url: videoURL))
        videoPlayer.play()
    }
    
    func constructFirstTime() {
        UserDefaults.standard.initialize(status: true)
        //TODO: something only do at first launch
    }
    
    func refreshDesktop(_ dstURL: URL) {
        if UserDefaults.standard.blackMenuBar {
            try? NSWorkspace.shared.setDesktopImageURL(Bundle.main.url(forResource: "black", withExtension: "jpg")!, for: NSScreen.main!, options: [:])
        } else {
            try? NSWorkspace.shared.setDesktopImageURL(URL(fileURLWithPath: ""), for: NSScreen.main!, options: [:])
            usleep(useconds_t(0.4 * Double(USEC_PER_SEC)))
            try? NSWorkspace.shared.setDesktopImageURL(dstURL, for: NSScreen.main!, options: [:])
        }
    }
    
    func testWallpaperWindowVisibility() -> Bool {
        let options = CGWindowListOption(arrayLiteral: CGWindowListOption.optionOnScreenOnly)
        let windowListInfo = CGWindowListCopyWindowInfo(options, CGWindowID(0))
        guard let infoList = windowListInfo as NSArray? as? [[String: AnyObject]] else { return true }
        let targetN = infoList.filter { item in
            let wBounds = item["kCGWindowNumber"]
            let winid = wBounds as? Int
            if let nonnilid = winid, nonnilid == videoWindow.windowNumber {
                return true
            }
            return false
        }
        return targetN.isEmpty == false
    }
}

//extension String {
//    func foundPath(in dir: FileManager.SearchPathDirectory) -> URL{
//        return FileManager.default.urls(for: dir, in: .userDomainMask)[0].appendingPathComponent(self)
//    }
//}

extension FileManager {
    var appDocumentFolder: URL {
        return self.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func folderInDocument(folderName: String) -> URL {
        return appDocumentFolder.appendingPathComponent(folderName)
    }
}
