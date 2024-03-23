//
//  AddThemeView.swift
//  ScreenZ
//
//  Created by 周源坤 on 2022/5/31.
//

import SwiftUI
import AVKit

struct AddThemeView: View {
    @State var displayedVideoURL: URL?
    @State var bkgImg: NSImage?
    @State var showSaveView: Bool = false
    @State var showOpenPanel: Bool = false
    @State var showStatusAlert: Bool = false
    @State var statusInfo: AddThemeStatus?
    @State var inputName: String = ""
    var alert2: NSAlert = NSAlert()
    var avplayer: AVPlayer = AVPlayer(url:Bundle.main.url(forResource: "demo", withExtension: "mp4")!)
    
    init() {
        avplayer.isMuted = true
    }
    
    var body: some View {
        VStack {
            VideoPlayer(player: avplayer)
            .frame(width: 192 * 4, height: 108 * 4)
            .onChange(of: displayedVideoURL) { oldValue, newValue in
                if newValue != nil {
                    oldValue?.stopAccessingSecurityScopedResource()
                    avplayer.replaceCurrentItem(with: AVPlayerItem(url: newValue!))
                    avplayer.play()
                }
            }
            HStack {
                Button {
                    showOpenPanel = true
                } label: {
                    SectionView(color: .green, txt: NSLocalizedString("Choose video", comment: ""), imageName: "magnifyingglass", size: CGSize(width: 250, height: 200))
                }
                .buttonStyle(.plain)
                .fileImporter(isPresented: $showOpenPanel, allowedContentTypes: [UTType.mpeg4Movie], onCompletion: fileImporterAction)
                

                Spacer()
                
                Button {
                    applyPaper()
                } label: {
                    SectionView(color: .purple, txt: NSLocalizedString("Apply video", comment: ""), imageName: "paintbrush.fill", size: CGSize(width: 250, height: 200))
                        
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button {
                    //saveTheme()
                    if displayedVideoURL == nil {
                        statusInfo = AddThemeStatus(type: .Tip, description: "Choose a video first")
                        showStatusAlert = true
                        return
                    }
                    showSaveView = true
                } label: {
                    SectionView(color: .orange, txt: NSLocalizedString("Save video", comment: ""), imageName: "square.and.arrow.down", size: CGSize(width: 250, height: 200))
                        
                }
                .buttonStyle(.plain)
                .alert("Wallpaper Name", isPresented: $showSaveView) {
                    TextField("Enter name here", text: $inputName)
                    Button("Save") {
                        saveTheme(url: displayedVideoURL!)
                    }
                    Button("Cancel") {
                        //do nothing
                    }
                }
                
            }
            .padding()
            
            
        }
        .background {
            ZStack {
                Image(nsImage: bkgImg ?? NSImage(contentsOf: Bundle.main.url(forResource: "demo", withExtension: "png")!)!)
                
                Rectangle()
                    .fill(.ultraThinMaterial)
            }
            .ignoresSafeArea()
        }
        .alert("Status", isPresented: $showStatusAlert, presenting: statusInfo) { detail in
            Button("OK") {
                //do nothing
            }
        } message: { detail in
            Text(detail.type.rawValue + ": ").bold() + Text(detail.description)
        }
        
        
    }
    
    func fileImporterAction(result: Result<URL, any Error>) {
        switch result {
        case .success(let monoURL):
            Task {
                do {
                    let bigImage = try await getThumbnailImageFromVideoUrl(url: monoURL)
                    try bigImage.saveTo(("tmp.png").foundFile(in: .documentDirectory))
                    displayedVideoURL = monoURL
                    bkgImg = bigImage
                    statusInfo = AddThemeStatus(type: .Success, description: "Chosed a video")
                    showStatusAlert = true
                } catch(let error) {
                    statusInfo = AddThemeStatus(type: .Error, description: error.localizedDescription)
                    showStatusAlert = true
                }
            }
        case .failure(let error):
            statusInfo = AddThemeStatus(type: .Error, description: error.localizedDescription)
            showStatusAlert = true
        }
    }
    
    func applyPaper() {
        if let url = displayedVideoURL {
            NotificationCenter.default.post(name: Notification.Name("videourlChanged"), object: url)
        } else {
            statusInfo = AddThemeStatus(type: .Error, description: "Bad URL")
            showStatusAlert = true
        }
    }
    
    func storeResources(monoName: String, srcURL: URL) async -> AddThemeStatus {
        let dstURL = (monoName+".mp4").foundFile(in: .documentDirectory)
        do {
            try FileManager.default.copyItem(at: srcURL, to: dstURL)
            let bigImage = try await getThumbnailImageFromVideoUrl(url: srcURL)
            try bigImage.saveTo((monoName+".png").foundFile(in: .documentDirectory))
            
            let video = Video(context: PersistenceController.shared.container.viewContext)
            video.name = monoName
            video.url = dstURL
            video.photo = (monoName+".png").foundFile(in: .documentDirectory)
            try PersistenceController.shared.container.viewContext.save()
            return AddThemeStatus(type: .Success, description: "Saved Wallpaper")
        } catch(let error as NSError) {
            return AddThemeStatus(type: .Error, description: error.localizedDescription)
        }
    }
    
    func saveTheme(url: URL) {
        if inputName == "" || PersistenceController.shared.fileExists(inputName) {
            statusInfo = AddThemeStatus(type: .Error, description: "Name invalid (null or duplicate)")
            showStatusAlert = true
            return
        }
        //save
        Task {
            let resStatus = await storeResources(monoName: inputName, srcURL: url)
            statusInfo = resStatus
            showStatusAlert = true
        }
    }
    
    func getThumbnailImageFromVideoUrl(url: URL) async throws -> NSImage {
        let gotAccess = url.startAccessingSecurityScopedResource()
        if !gotAccess {
            throw AddThemeError.AccessToURLError
        }
        let asset = AVAsset(url: url)
        let avAssetImageGenerator = AVAssetImageGenerator(asset: asset)
        avAssetImageGenerator.appliesPreferredTrackTransform = true
        let (cgThumbImage, _) = try await avAssetImageGenerator.image(at: .zero)
        let bigImage = NSImage(cgImage: cgThumbImage, size: NSSize(width: NSScreen.main!.frame.width, height: NSScreen.main!.frame.height))
        return bigImage
    }
}

struct AddThemeView_Previews: PreviewProvider {
    static var previews: some View {
        AddThemeView()
    }
}

struct SectionView: View {
    let color: Color
    let txt: String
    let imageName: String
    let size: CGSize
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size.height / 10, style: .continuous)
                .fill(LinearGradient(colors: [color.opacity(0.2), color], startPoint: .top, endPoint: .bottom))
                .frame(width: size.width, height: size.height)
                
            
            VStack {
                Image(systemName: imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size.height / 2, height: size.height / 2)
                Text(txt)
                    .font(.title)
                    .fontWeight(.bold)
                    
            }
            .foregroundColor(.white)
        }
        
            
    }
    
}

extension NSImage {
    func saveTo (_ dstURL: URL) throws {
        if FileManager.default.fileExists(atPath: dstURL.path) {
            try FileManager.default.removeItem(at: dstURL)
        }
        let bMImg = NSBitmapImageRep(data: self.tiffRepresentation!)
        let dataToSave = bMImg?.representation(using: .png, properties: [NSBitmapImageRep.PropertyKey.compressionFactor : 1])
        try dataToSave?.write(to: dstURL)
    }
}

enum AddThemeError : Error {
    case AccessToURLError
}

extension AddThemeError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .AccessToURLError:
            NSLocalizedString("No Access to this resource", comment: "")
        }
    }
}

struct AddThemeStatus {
    
    enum StatusType: String {
        case Tip
        case Success
        case Error
    }
    
    let type: StatusType
    let description: String
}

