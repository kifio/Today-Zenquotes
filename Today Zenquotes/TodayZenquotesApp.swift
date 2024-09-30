//
//  TodayZenquotesApp.swift
//  Today Zenquotes
//
//  Created by Иван Мурашов on 23.09.2024.
//

import SwiftUI

// MARK: View
@main
struct TodayZenquotesApp: App {
    
    @AppStorage("displayMode") var displayMode: DisplayMode = .auto
    @StateObject var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear {
                    DisplayMode.changeDispalayMode(to: displayMode)
                }
                .onChange(of: displayMode) { _, new in
                    DisplayMode.changeDispalayMode(to: new)
                }
        }.commands { Menus() }
    }
}

struct ContentView: View {
    
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    @State private var eventType: EventType? = .events
    
    var events: [Event] {
        appState.dataFor(eventType: eventType, searchText: searchText)
    }
    
    var windowTitle: String {
        if let eventType {
            return "On This Day - \(eventType.rawValue)"
        }
        
        return "On This Day"
    }
    
    var body: some View {
        NavigationView {
            SidebarView(selection: $eventType)
            GridView(gridData: events)
        }
        .frame(
            minWidth: 700,
            idealWidth: 1000,
            maxWidth: .infinity,
            minHeight: 400,
            idealHeight: 800,
            maxHeight: .infinity
        )
        .navigationTitle(windowTitle)
        .toolbar(id: "mainToolbar") { Toolbar() }
        .searchable(text: $searchText)
    }
}

struct SidebarView: View {
    
    @Binding var selection: EventType?
    @EnvironmentObject var appState: AppState
    @AppStorage("showTotals") var showTotals = true

    var body: some View {
        List(selection: $selection) {
            Section("TODAY") {
                ForEach(EventType.allCases, id: \.self) { type in
                    Text(type.rawValue)
                        .badge(showTotals ? appState.countFor(eventType: type) : 0)
                }
            }
        }.listStyle(.sidebar)
    }
}

struct EventView: View {
    
    var event: Event
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 30) {
                Text(event.year)
                    .font(Font.justCuriousity)
                
                Text(event.text)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Related links:")
                        .font(.title2)
                    
                    ForEach(event.links) { link in
                        Link(link.title, destination: link.url)
                            .onHover { inside in
                                if inside {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                    }
                }
                
                Spacer()
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 250)
    }
}

struct GridView: View {
    
    @AppStorage("showTotals") var showTotals = true
    
    var gridData: [Event]
    
    var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 250, maximum: 250), spacing: 20)]
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 15) {
                ForEach(gridData) {
                    EventView(event: $0)
                        .frame(height: 350, alignment: .topLeading)
                        .background()
                        .clipped()
                        .border(.secondary, width: 1)
                        .padding(.bottom, 5)
                        .shadow(color: .primary.opacity(0.3), radius: 3, x: 3, y: 3)
                }
            }
            
            if showTotals {
                Text("\(gridData.count)")
                    .font(.title3)
                    .padding(.all, 8)
            }
        }
        .padding(.vertical)
    }
}

struct Menus: Commands {
    
    @AppStorage("showTotals") var showTotals = true
    @AppStorage("displayMode") var displayMode: DisplayMode = .auto

    var body: some Commands {
        SidebarCommands()
        ToolbarCommands()
        CommandGroup(before: .help) {
            Button("ZenQuotes.io web site") {
                NSWorkspace.shared.open(URL(string: "https://today.zenquotes.io")!)
            }
        }
        CommandMenu("Display") {
            Toggle(isOn: $showTotals) {
                Text("Show Totals")
            }
            .keyboardShortcut("t", modifiers: .command)
            
            Divider()
            
            Picker("Appearance", selection: $displayMode) {
                ForEach(DisplayMode.allCases, id: \.self) {
                    Text($0.rawValue)
                        .tag($0)
                }
            }
        }
    }
}

struct Toolbar: CustomizableToolbarContent {
    var body: some CustomizableToolbarContent {
        ToolbarItem(
            id: "toggleSidebar",
            placement: .navigation,
            showsByDefault: true
        ) {
            Button {
                toggleSidebar()
            } label: {
                Label("Toggle Sidebar", systemImage: "sidebar.left")
            }
            .help("Toggle Sidebar")
        }
    }
    
    func toggleSidebar() {
        NSApp.keyWindow?
            .contentViewController?
            .tryToPerform(
                #selector(NSSplitViewController.toggleSidebar(_:)),
                with: nil
            )
    }
}

extension Font {
    static let justCuriousity = Font.title
}
