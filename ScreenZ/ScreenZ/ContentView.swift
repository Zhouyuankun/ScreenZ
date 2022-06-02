//
//  ContentView.swift
//  ScreenZ
//
//  Created by 周源坤 on 2022/5/31.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) var viewContext
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: {AddThemeView()}) {
                    Label("Add themes", systemImage: "plus")
                }
                NavigationLink(destination: {AllThemeView()}) {
                    Label("All themes", systemImage: "star")
                }
                NavigationLink(destination: {SettingsView()}) {
                    Label("Settings", systemImage: "gear")
                }
            }
            .listStyle(.sidebar)
        }
        .background(VisualEffect())
    }
}


struct VisualEffect: NSViewRepresentable {
   func makeNSView(context: Self.Context) -> NSView { return NSVisualEffectView() }
   func updateNSView(_ nsView: NSView, context: Context) { }
}

class TransparentWindowView: NSView {
  override func viewDidMoveToWindow() {
    window?.backgroundColor = .clear
    super.viewDidMoveToWindow()
  }
}

struct TransparentWindow: NSViewRepresentable {
   func makeNSView(context: Self.Context) -> NSView { return TransparentWindowView() }
   func updateNSView(_ nsView: NSView, context: Context) { }
}
