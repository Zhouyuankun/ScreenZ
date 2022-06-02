//
//  AddThemeView.swift
//  ScreenZ
//
//  Created by 周源坤 on 2022/5/31.
//

import SwiftUI
import AVKit

struct AddThemeView: View {
    @State var url: URL?
    var body: some View {
        VStack {
            
            VideoPlayer(player: AVPlayer(url: url ?? Bundle.main.url(forResource: "demo", withExtension: "mp4")!))
                    .frame(width: 192 * 4, height: 108 * 4)
            
            HStack {
                Button {
                    openDialog()
                } label: {
                    SectionView(color: .green, txt: NSLocalizedString("Choose video", comment: ""), imageName: "magnifyingglass", size: CGSize(width: 250, height: 200))
                }
                .buttonStyle(.plain)

                Spacer()
                
                Button {
                    applyPaper()
                } label: {
                    SectionView(color: .purple, txt: NSLocalizedString("Apply video", comment: ""), imageName: "paintbrush.fill", size: CGSize(width: 250, height: 200))
                        
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button {
                    saveTheme()
                } label: {
                    SectionView(color: .orange, txt: NSLocalizedString("Save video", comment: ""), imageName: "square.and.arrow.down", size: CGSize(width: 250, height: 200))
                        
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            
        }
        .background {
            ZStack {
                Image(nsImage: NSImage(contentsOf: Bundle.main.url(forResource: "demo", withExtension: "png")!)!)
                
                Rectangle()
                    .fill(.ultraThinMaterial)
            }
            .ignoresSafeArea()
        }
        
    }
    
    func openDialog() {
        let dialog = NSOpenPanel();

        dialog.title                   = "Choose an video";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.allowsMultipleSelection = false;
        dialog.canChooseDirectories = false;
        dialog.allowedContentTypes = [UTType.mpeg4Movie]

        if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
            guard let result = dialog.url else {
                return
            }
            let path: String = result.path
            getThumbnailImageFromVideoUrl(url: URL(fileURLWithPath: path), completion: { (smallImage, bigImage) in
                bigImage!.saveTo(("tmp.png").foundFile(in: .documentDirectory))
            })
            url = result
        } else {
            // User clicked on "Cancel"
            return
        }
    }
    
    func applyPaper() {
        guard let url = url else {
            return
        }
        NotificationCenter.default.post(name: Notification.Name("videourl"), object: url)
    }
    
    func saveTheme() {
        guard let url = url else {
            return
        }

        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Please enter a name for theme", comment: "")
        alert.addButton(withTitle: NSLocalizedString("Save", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))

        let inputTextField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        inputTextField.placeholderString = (NSLocalizedString("Enter your theme name", comment: ""))
        alert.accessoryView = inputTextField
        if alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn{
            if inputTextField.stringValue != "" && !fileExists(inputTextField.stringValue) {
                //save
                let newDire = (inputTextField.stringValue+".mp4").foundFile(in: .documentDirectory)
                do {
                    try FileManager.default.copyItem(at: url, to: newDire)
                    getThumbnailImageFromVideoUrl(url: url, completion: { (smallImage, bigImage) in
                        bigImage!.saveTo((inputTextField.stringValue+".png").foundFile(in: .documentDirectory))
                    })
                } catch(let error) {
                    print(error.localizedDescription)
                }
                
                let video = Video(context: PersistenceController.shared.container.viewContext)
                video.name = inputTextField.stringValue
                video.url = newDire
                video.photo = (inputTextField.stringValue+".png").foundFile(in: .documentDirectory)
                try! PersistenceController.shared.container.viewContext.save()
                
                let alert1 = NSAlert()
                alert1.messageText = NSLocalizedString("Save success", comment: "")
                alert1.addButton(withTitle: NSLocalizedString("OK", comment: ""))
                alert1.runModal()
            } else {
                let alert2 = NSAlert()
                alert2.messageText = NSLocalizedString("Name invalid (null or duplicate)", comment: "")
                alert2.addButton(withTitle: NSLocalizedString("OK", comment: ""))
                alert2.runModal()
            }
            
        }
    }
    
    func fileExists(_ name: String) -> Bool {
        let fetchRequest = Video.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)
        let result = try! PersistenceController.shared.container.viewContext.fetch(fetchRequest)
        return result.count == 1
    }
}

struct AddThemeView_Previews: PreviewProvider {
    static var previews: some View {
        AddThemeView()
    }
}


func getThumbnailImageFromVideoUrl(url: URL, completion: @escaping ((_ smallImage: NSImage?, _ bigImage: NSImage?)->Void)) {
    DispatchQueue.global().async { //1
        let asset = AVAsset(url: url) //2
        let avAssetImageGenerator = AVAssetImageGenerator(asset: asset) //3
        avAssetImageGenerator.appliesPreferredTrackTransform = true //4
        let thumnailTime = CMTimeMake(value: 2, timescale: 1) //5
        do {
            let cgThumbImage = try avAssetImageGenerator.copyCGImage(at: thumnailTime, actualTime: nil) //6
            let smallImage = NSImage(cgImage: cgThumbImage, size: NSSize(width: 1920, height: 1080)) //7
            let bigImage = NSImage(cgImage: cgThumbImage, size: NSSize(width: NSScreen.main!.frame.width, height: NSScreen.main!.frame.height))
            DispatchQueue.main.async { //8
                completion(smallImage, bigImage) //9
            }
        } catch {
            print(error.localizedDescription) //10
            DispatchQueue.main.async {
                completion(nil, nil) //11
            }
        }
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
    func saveTo(_ dstURL: URL) {
        if FileManager.default.fileExists(atPath: dstURL.path) {
            do {
                try FileManager.default.removeItem(at: dstURL)
            } catch (let error) {
                print(error)
            }
        }
        let bMImg = NSBitmapImageRep(data: self.tiffRepresentation!)
        let dataToSave = bMImg?.representation(using: .png, properties: [NSBitmapImageRep.PropertyKey.compressionFactor : 1])
        do {
            try dataToSave?.write(to: dstURL)
        } catch(let error) {
            print(error.localizedDescription)
        }
    }
}
