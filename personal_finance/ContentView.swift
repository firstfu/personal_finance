//
//  ContentView.swift
//  personal_finance
//
//  Created by firstfu on 2026/2/17.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationSplitView {
            Text("Loading...")
        } detail: {
            Text("Select an item")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Transaction.self, Category.self], inMemory: true)
}
