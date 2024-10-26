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
    @State private var maxPoints: Int = 0
    
    var body: some View {
        ZStack {
            // Dynamic background
            LinearGradient(
                gradient: Gradient(colors: [
                    .blue,
                    .white,
                    .yellow
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("🏆")
                            .font(.system(size: 48))
                        Text("New Competition")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding(.top, 20)
                    
                    // Main content card
                    VStack(spacing: 24) {
                        // Competition Details Section
                        VStack(alignment: .leading, spacing: 20) {
                            sectionHeader("Competition Details", icon: "trophy.fill")
                            
                            CompCustomTextField(
                                icon: "pencil",
                                placeholder: "Competition Name",
                                text: $competitionName
                            )
                            
                            CustomDatePicker(
                                date: $competitionDate,
                                icon: "calendar"
                            )
                            
                            CompCustomTextField(
                                icon: "star.fill",
                                placeholder: "Max Points per Day",
                                value: $maxPoints
                            )
                            
                            Text("💡 Set this to: number of participants - 1")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.2))
                        
                        // Groups Section
                        VStack(alignment: .leading, spacing: 20) {
                            sectionHeader("Select Groups", icon: "person.3.fill")
                            
                            ForEach(viewModel.groups, id: \.id) { group in
                                GroupSelectionCard(
                                    group: group,
                                    isSelected: selectedGroups.contains(group.id),
                                    action: { toggleGroupSelection(group.id) }
                                )
                            }
                        }
                        
                        // Buttons
                        VStack(spacing: 16) {
                            Button(action: createCompetition) {
                                HStack {
                                    Image(systemName: "flag.fill")
                                    Text("Create Competition")
                                }
                                .frame(maxWidth: .infinity)
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    competitionName.isEmpty || selectedGroups.isEmpty ?
                                    LinearGradient(
                                        colors: [.gray],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ):
                                    LinearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(15)
                                .shadow(radius: 5)
                            }
                            .disabled(competitionName.isEmpty || selectedGroups.isEmpty)
                            
                            Button(action: dismiss.callAsFunction) {
                                Text("Cancel")
                                    .frame(maxWidth: .infinity)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(15)
                            }
                        }
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.gray.opacity(0.45))
                    )
                    .padding(.horizontal)
                }
                .padding(.bottom, 24)
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Competition Created"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    if !isCreatingCompetition {
                        dismiss()
                    }
                }
            )
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
                    points: maxPoints,
                    groupIds: Array(selectedGroups)
                )
                alertMessage = "Competition '\(competition.competition_name)' created with max points \(competition.max_points ?? 0)"
                showAlert = true
                isCreatingCompetition = false
                competitionName = ""
                selectedGroups = []
                maxPoints = 0
            } catch {
                alertMessage = "Failed to create competition: \(error.localizedDescription)"
                showAlert = true
                isCreatingCompetition = false
            }
        }
    }
    
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white)
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
        }
        .padding(.horizontal)
    }
}

// MARK: - Supporting Views

struct CompCustomTextField: View {
    let icon: String
    let placeholder: String
    var text: Binding<String>? = nil
    var value: Binding<Int>? = nil
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 24)
            
            if let text = text {
                TextField(placeholder, text: text)
            } else if let value = value {
                TextField(placeholder, value: value, format: .number)
                    .keyboardType(.numberPad)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}

struct CustomDatePicker: View {
    let date: Binding<Date>
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 24)
            
            DatePicker(
                "Competition Date",
                selection: date,
                displayedComponents: .date
            )
            .accentColor(.white)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}

struct GroupSelectionCard: View {
    let group: Group // Assuming Group is your model
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(group.name)
                    .foregroundColor(.white)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.cyan)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.cyan : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .padding(.horizontal)
    }
}

struct CompetitionManagerView_Previews: PreviewProvider {
    static var previews: some View {
        CompetitionManagerView()
    }
}
