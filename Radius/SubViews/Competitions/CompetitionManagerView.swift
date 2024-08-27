import SwiftUI

struct CompetitionManagerView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = CompetitionManagerViewModel()
    @State private var competitionName: String = ""
    @State private var competitionDate: Date = Date()
    @State private var selectedGroups: Set<UUID> = []
    @State private var isCreatingCompetition = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack {
            Form {
                Section(header: Text("Competition Details")
                    .font(.headline)
                    .foregroundColor(.primary)
                ) {
                    TextField("Competition Name", text: $competitionName)
                        .padding()
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(10)
                    DatePicker("Competition Date", selection: $competitionDate, displayedComponents: .date)
                        .padding()
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(10)
                }
                .listRowBackground(Color.clear)

                Section(header: Text("Select Groups")
                    .font(.headline)
                    .foregroundColor(.primary)
                ) {
                    ForEach(viewModel.groups, id: \.id) { group in
                        HStack {
                            Text(group.name)
                            Spacer()
                            if selectedGroups.contains(group.id) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .padding()
                        .background(selectedGroups.contains(group.id) ? Color.blue.opacity(0.2) : Color.white.opacity(0.1))
                        .cornerRadius(10)
                        .onTapGesture {
                            toggleGroupSelection(group.id)
                        }
                    }
                }
                .listRowBackground(Color.clear)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.5), Color.yellow.opacity(0.5)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)
            )
            .cornerRadius(15)
            .padding()

            Button(action: createCompetition) {
                Text("Create Competition")
                    .foregroundColor(.white)
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }
            .padding(.horizontal)
            .disabled(competitionName.isEmpty || selectedGroups.isEmpty)

            Button(action: {
                dismiss()
            }) {
                Text("Cancel")
                    .foregroundColor(.red)
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }
            .padding(.horizontal)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.5), Color.yellow.opacity(0.5)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
        )
        .navigationTitle("Create Competition")
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Competition Created"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            viewModel.fetchGroups()
        }
    }

    private func toggleGroupSelection(_ groupId: UUID) {
        if selectedGroups.contains(groupId) {
            selectedGroups.remove(groupId)
        } else {
            selectedGroups.insert(groupId)
        }
    }

    private func createCompetition() {
        isCreatingCompetition = true
        Task {
            do {
                let competition = try await viewModel.createCompetition(
                    name: competitionName,
                    date: competitionDate,
                    groupIds: Array(selectedGroups)
                )
                alertMessage = "Competition '\(competition.competitionName)' created with max points \(competition.maxPoints ?? 0)"
                showAlert = true
                isCreatingCompetition = false
                competitionName = ""
                selectedGroups = []
            } catch {
                alertMessage = "Failed to create competition: \(error.localizedDescription)"
                showAlert = true
                isCreatingCompetition = false
            }
        }
    }
}

struct CompetitionManagerView_Previews: PreviewProvider {
    static var previews: some View {
        CompetitionManagerView()
    }
}
