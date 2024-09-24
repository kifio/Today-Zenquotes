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
            Text(date())
        }
        .padding()
    }
    
    func date() -> String {
        
        guard let data = sampleData() else { return "" }
        
        do {
            let day = try JSONDecoder().decode(Day.self, from: data)
            return "\(day.date)\n\(day.data["Births"]![0].links)"
        } catch {
            print(error)
            return ""
        }
    }
}

// Model
struct Day: Decodable {
    let date: String
    let data: [String: [Event]]
}

struct Event: Decodable {
    let text: String
    let links: [EventLink]
    
    enum CodingKeys: String, CodingKey {
        case text
        case links
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.text = try container.decode(String.self, forKey: .text)
        
        let links = try container.decode([String: [String: String]].self, forKey: .links)
        
        self.links = links.compactMap { (_, link) in
            guard
                let title = link["2"],
                let address = link["1"],
                let url = URL(string: address)
            else {
                return nil
            }
            
            return EventLink(title: title, url: url)
        }
    }
}

struct EventLink: Decodable {
    let title: String
    let url: URL
}
