//
//  Today_ZenquotesApp.swift
//  Today Zenquotes
//
//  Created by Иван Мурашов on 23.09.2024.
//

import SwiftUI

@main
struct Today_ZenquotesApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
//            Text(appState.days[])
        }
        .padding()
    }
    
    var appState = AppState()
    
    func date() async {
        
//        Task {
//            do {
//                let day = try await getDataForDay(month: 9, day: 25)
//                appState.days[day.displayDate] = day
//            }
//        }
       
    }
}

class AppState: ObservableObject {
    @Published
    var days: [String: Day] = [:]
    
    func getDartaFor(month: Int, day: Int) -> Day? {
        let monthName = Calendar.current.monthSymbols[month - 1]
        let dateStrong = "\(monthName) \(day)"
        return days[dateStrong]
    }
}

// Model
enum FetchError: Error {
  case badURL
  case badResponse
  case badJSON
}

func getDataForDay(month: Int, day: Int) async throws -> Day {
    
    let address = "https://today.zenquotes.io/api/\(month)/\(day)"
    guard let url = URL(string: address) else {
      throw FetchError.badURL
    }
    let request = URLRequest(url: url)

    let (data, response) = try await URLSession.shared.data(for: request)
    guard
      let response = response as? HTTPURLResponse,
      response.statusCode < 400 else {
        throw FetchError.badResponse
      }

    do {
        return try JSONDecoder().decode(Day.self, from: data)
    } catch {
        throw FetchError.badJSON
    }
    
}

struct Day: Decodable {
    let date: String
    let data: [String: [Event]]
    
    var events: [Event] { data[EventType.events.rawValue] ?? [] }
    var births: [Event] { data[EventType.births.rawValue] ?? [] }
    var deaths: [Event] { data[EventType.deaths.rawValue] ?? [] }
    
    var displayDate: String {
        date.replacingOccurrences(of: "_", with: " ")
    }
}

enum EventType: String {
    case events = "Events"
    case births = "Births"
    case deaths = "Deaths"
}

struct Event: Decodable, Identifiable {
    let id = UUID()
    let text: String
    let links: [EventLink]
    let year: String
    
    enum CodingKeys: String, CodingKey {
        case text
        case links
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawText = try container.decode(String.self, forKey: .text)
        let textParts = rawText.components(separatedBy: " &#8211; ")
        
        if textParts.count == 2 {
            year = textParts[0]
            text = textParts[1]
        } else {
            year = "?"
            text = rawText
        }
        
        let links = try container.decode([String: [String: String]].self, forKey: .links)
        
        self.links = links.compactMap { (_, link) in
            guard
                let title = link["2"],
                let address = link["1"],
                let url = URL(string: address)
            else {
                return nil
            }
            
            return EventLink(id: UUID(), title: title, url: url)
        }
    }
}

struct EventLink: Decodable, Identifiable {
    let id: UUID
    let title: String
    let url: URL
}
