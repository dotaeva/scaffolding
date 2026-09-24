import SwiftUI
import Scaffolding

struct HomeScreen: View {
    @Environment(HomeCoordinator.self) private var coordinator

    let store: TodosStore

    var body: some View {
        DetailForm {
            Section {
                ShellRows()
            } header: {
                Text("Running")
            } footer: {
                Text("Tapping a favourite asks the shell to open the task — a "
                     + "tab switch and two typed hops on iPhone, two column "
                     + "swaps on iPad and Mac. Home never learns which.")
            }

            Section("Favourites") {
                if store.favorites.isEmpty {
                    Text("Star a task in Todos and it shows up here.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.favorites) { todo in
                        // A plain Button, never a NavigationLink — the row
                        // must not know how the app navigates.
                        Button {
                            coordinator.openInTodos(todo)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                                    .frame(width: 18)
                                Text(todo.name).foregroundStyle(Color.primary)
                                Spacer(minLength: 0)
                            }
                        }
                    }
                }
            }

            Section {
                DeepLinkRow(store: store)
            } header: {
                Text("Deep link")
            } footer: {
                Text("Open it from anywhere — Safari, Terminal, the Help menu. "
                     + "MainCoordinator.handle(_:) resolves it and hands it to "
                     + "whichever shell is live.")
            }
        }
        .navigationTitle("Home")
    }
}
