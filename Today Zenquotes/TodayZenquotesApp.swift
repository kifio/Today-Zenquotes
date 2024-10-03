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

enum ViewMode: Int {
    case grid
    case table
}

struct ContentView: View {
    
    @EnvironmentObject var appState: AppState
    @SceneStorage("searchText") var searchText = ""
    @SceneStorage("eventType") var eventType: EventType?
    @SceneStorage("viewMode") var viewMode: ViewMode = .grid
    @SceneStorage("selectDate") var selectedDate: String?
    
    var events: [Event] {
        appState.dataFor(
            eventType: eventType,
            date: selectedDate,
            searchText: searchText
        )
    }
    
    var windowTitle: String {
        let dateTitle = selectedDate ?? "On This Day"
        
        if let eventType {
            return "\(dateTitle) - \(eventType.rawValue)"
        }
        
        return dateTitle
    }
    
    var body: some View {
        NavigationView {
            SidebarView(selection: $eventType)
            if viewMode == .grid {
                GridView(gridData: events)
            } else {
                TableView(tableData: events)
            }
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
        .toolbar(id: "mainToolbar") { Toolbar(viewMode: $viewMode) }
        .searchable(text: $searchText)
        .onAppear {
            if eventType == nil {
                eventType = .events
            }
        }
    }
}

struct SidebarView: View {
    
    @Binding var selection: EventType?
    @EnvironmentObject var appState: AppState
    @AppStorage("showTotals") var showTotals = true
    @SceneStorage("selectDate") var selectedDate: String?

    var body: some View {
        VStack {
            List(selection: $selection) {
                Section(selectedDate?.uppercased() ?? "TODAY") {
                    ForEach(EventType.allCases, id: \.self) { type in
                        Text(type.rawValue)
                            .badge(showTotals ? appState.countFor(eventType: type, date: selectedDate) : 0)
                    }
                }
                
                Section("AVAILABLE DATES") {
                    ForEach(appState.sortedDates, id: \.self) { date in
                        Button {
                            selectedDate = date
                        } label: {
                            HStack {
                                Text(date)
                                    .font(.title3)
                                
                                Spacer()
                            }
                        }
                        .modifier(DateButtonViewModifier(selected: date == selectedDate))
                    }
                }
            }.listStyle(.sidebar)
            
            Spacer()
            DayPicker()
        }.frame(minWidth: 220)
    }
}

struct DateButtonViewModifier: ViewModifier {
    var selected: Bool
    
    func body(content: Content) -> some View {
        if selected {
            content
                .buttonStyle(.borderedProminent)
        } else {
            content
        }
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
    
    @Binding var viewMode: ViewMode
    
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
        
        ToolbarItem(id: "viewMode") {
            Picker("View Mode", selection: $viewMode) {
                Label("Grid", systemImage: "square.grid.3x2")
                    .tag(ViewMode.grid)
                Label("Table", systemImage: "tablecells")
                    .tag(ViewMode.table)
            }
            .pickerStyle(.segmented)
            .help("Switch between Grid and Table")
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

struct TableView: View {
    
    var tableData: [Event]
    
    var sortedTableData: [Event] {
        tableData.sorted(using: sortOrder)
    }
    
    var selectedEvent: Event? {
        guard let selectedEventID else {
            return nil
        }
        
        let event = tableData.first {
            $0.id == selectedEventID
        }
        
        return event
    }
    
    @State private var selectedEventID: UUID?
    @State private var sortOrder = [KeyPathComparator(\Event.year)]
    
    var body: some View {
        HStack {
            Table(sortedTableData, selection: $selectedEventID, sortOrder: $sortOrder) {
                TableColumn("Year", value: \.year) {
                    Text($0.year)
                }
                .width(min: 50, ideal: 60, max: 100)
                
                TableColumn("Title", value: \.text) {
                    Text($0.text)
                }
            }
            .tableStyle(.inset)
            
            if let selectedEvent {
                EventView(event: selectedEvent)
                    .frame(width: 250)
            } else {
                Text("Select an event for more details...")
                    .font(.title3)
                    .padding()
                    .frame(width: 250)
            }
        }
        
        
    }
}

struct DayPicker: View {
    @EnvironmentObject var appState: AppState
    @SceneStorage("selectedDate") var selectedDate: String?
    
    @State private var month = "January"
    @State private var day = 1
    
    var maxDays: Int {
        switch month {
        case "February":
            return 29
        case "April", "June", "September", "November":
            return 30
        default:
            return 31
        }
    }
    
    var body: some View {
        VStack {
            Text("Select a Date")
            
            HStack {
                Picker("", selection: $month) {
                    ForEach(appState.englishMonthNames, id: \.self) {
                        Text($0)
                    }
                }.pickerStyle(.menu)
                
                Picker("", selection: $day) {
                    ForEach(1 ... maxDays, id: \.self) {
                        Text("\($0)")
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 60)
                .padding(.trailing, 10)
                
                if appState.isLoading {
                    ProgressView()
                        .frame(height: 28)
                } else {
                    Button("Get Events") {
                        Task {
                            await getNewEvents()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
        }.padding()
    }
    
    func getNewEvents() async {
        let monthIndex = appState.englishMonthNames
            .firstIndex(of: month) ?? 0
        
        await appState.getDataFor(month: monthIndex + 1, day: day)
        
        selectedDate = "\(month) \(day)"
    }
}

extension Font {
    static let justCuriousity = Font.title
}
