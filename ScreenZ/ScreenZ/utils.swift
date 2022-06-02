//
//  utils.swift
//  ScreenZ
//
//  Created by 周源坤 on 2022/5/31.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

//struct DocumentPicker: NSViewControllerRepresentable {
//    @Environment(\.presentationMode) private var presentationMode
//
//    var documentTypes: [UTType] // [kUTTypeFolder as String]
//    var onDocumentsPicked: (_: URL) -> ()
//
//    func makeUIViewController(context: NSViewControllerRepresentableContext<DocumentPicker>) -> NSDocumentPickerViewController {
//        let controller: NSDocumentPickerViewController
//        controller = NSDocumentPickerViewController(forOpeningContentTypes: documentTypes)
//        controller.allowsMultipleSelection = false
//        controller.delegate = context.coordinator
//        return controller
//    }
//
//    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: UIViewControllerRepresentableContext<DocumentPicker>) {
//
//    }
//
//    func makeCoordinator() -> DocumentPickerCoordinator {
//        DocumentPickerCoordinator(self)
//    }
//
//    class DocumentPickerCoordinator: NSObject, UIDocumentPickerDelegate, UINavigationControllerDelegate {
//        let control: DocumentPicker
//
//        init(_ control: DocumentPicker) {
//          self.control = control
//        }
//
//        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
//            let url = urls.first!
//            guard url.startAccessingSecurityScopedResource() else {
//                    // Handle the failure here.
//                    return
//                }
//
//                // Make sure you release the security-scoped resource when you finish.
//                defer { url.stopAccessingSecurityScopedResource() }
//
//            control.onDocumentsPicked(url)
//            control.presentationMode.wrappedValue.dismiss()
//        }
//
//
//    }
//}
