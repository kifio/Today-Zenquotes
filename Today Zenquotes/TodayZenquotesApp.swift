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
    
    @StateObject var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

struct ContentView: View {
    
    @EnvironmentObject var appState: AppState
    
    @State private var eventType: EventType? = .events
    
    var events: [Event] {
        appState.dataFor(eventType: .events)
    }
    
    var body: some View {
        NavigationView {
            SidebarView(selection: $eventType)
            Text("\(events.count)")
        }.frame(
            minWidth: 700,
            idealWidth: 1000,
            maxWidth: .infinity,
            minHeight: 400,
            idealHeight: 800,
            maxHeight: .infinity
        )
    }
}

struct SidebarView: View {
    
    @Binding var selection: EventType?
    
    var body: some View {
        List(selection: $selection) {
            Section("TODAY") {
                ForEach(EventType.allCases, id: \.self) { type in
                    Text(type.rawValue)
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

extension Font {
    static let justCuriousity = Font.title
}
