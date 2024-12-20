import SwiftUI

// MARK: - Color Extension

extension Color {
    // Define custom colors using hexadecimal values
    static let primaryBackground = Color(hex: "#F0F4F7")
    static let cardBackground = Color.white
    static let primaryText = Color(hex: "#2D3748")
    static let secondaryText = Color(hex: "#4A5568")
    static let actionBlue = Color(hex: "#3182CE")
    static let disabledBlue = Color(hex: "#A0AEC0")
    static let borderGray = Color(hex: "#CBD5E0")
    static let selectionBlue = Color(hex: "#2C5282")
    
    // Initializer to create Color from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255,
                            (int >> 8) * 17,
                            (int >> 4 & 0xF) * 17,
                            (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255,
                            int >> 16,
                            int >> 8 & 0xFF,
                            int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24,
                            int >> 16 & 0xFF,
                            int >> 8 & 0xFF,
                            int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Extension for Dismissing Keyboard

extension View {
    /// Dismisses the keyboard by resigning the first responder.
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Main View

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
        ZStack(alignment: .topTrailing) {
            // Primary Background with Tap Gesture to Dismiss Keyboard
            Color.primaryBackground
                .ignoresSafeArea()
                .onTapGesture {
                    self.hideKeyboard()
                }
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header with "X" Dismiss Button
                    header
                    
                    // Content Card
                    contentCard
                }
                .padding(.top, 60) // Extra padding to accommodate the "X" button
                .padding(.horizontal, 16) // Reduce horizontal padding to make view wider
            }
            
            // "X" Dismiss Button
            closeButton
                .padding([.top, .trailing], 16)
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Competition"),
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
    
    // MARK: - Subviews
    
    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "trophy.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(Color.actionBlue)
            
            Text("New Competition")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(Color.primaryText)
        }
    }
    
    private var contentCard: some View {
        VStack(spacing: 24) {
            // Competition Details
            competitionDetailsSection
            
            Divider()
                .background(Color.borderGray)
            
            // Groups Selection
            groupsSelectionSection
            
            // Action Buttons
            actionButtons
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 0) // Remove additional horizontal padding inside contentCard
    }
    
    private var competitionDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Competition Details", icon: "trophy.fill")
            
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
                .font(.footnote)
                .foregroundColor(Color.secondaryText)
        }
    }
    
    private var groupsSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Select Groups", icon: "person.3.fill")
            
            ForEach(viewModel.groups, id: \.id) { group in
                GroupSelectionCard(
                    group: group,
                    isSelected: selectedGroups.contains(group.id),
                    action: { toggleGroupSelection(group.id) }
                )
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            Button(action: createCompetition) {
                Text("Create Competition")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        competitionName.isEmpty || selectedGroups.isEmpty ?
                        Color.disabledBlue :
                        Color.actionBlue
                    )
                    .cornerRadius(12)
            }
            .disabled(competitionName.isEmpty || selectedGroups.isEmpty)
            
            Button(action: dismiss.callAsFunction) {
                Text("Cancel")
                    .fontWeight(.bold)
                    .foregroundColor(Color.actionBlue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.actionBlue, lineWidth: 2)
                    )
            }
        }
    }
    
    private var closeButton: some View {
        Button(action: {
            dismiss()
        }) {
            Image(systemName: "xmark.circle.fill")
                .resizable()
                .frame(width: 30, height: 30)
                .foregroundColor(Color.actionBlue)
                .shadow(radius: 2)
        }
    }
    
    // MARK: - Helper Methods
    
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color.actionBlue)
            Text(title)
                .font(.headline)
                .foregroundColor(Color.primaryText)
            Spacer()
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
}

// MARK: - Supporting Views

struct CompCustomTextField: View {
    let icon: String
    let placeholder: String
    var text: Binding<String>? = nil
    var value: Binding<Int>? = nil
    @FocusState var isInputActive: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color.actionBlue)
                .frame(width: 20)
            
            if let text = text {
                TextField(placeholder, text: text)
                    .foregroundColor(Color.primaryText)
                    .autocapitalization(.none)
            } else if let value = value {
                TextField(placeholder, value: value, format: .number)
                    .keyboardType(.numberPad)
                    .foregroundColor(Color.primaryText)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.borderGray, lineWidth: 1)
        )
    }
}

struct CustomDatePicker: View {
    let date: Binding<Date>
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color.actionBlue)
                .frame(width: 20)
            
            DatePicker(
                "",
                selection: date,
                displayedComponents: .date
            )
            .labelsHidden()
            .foregroundColor(Color.primaryText)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.borderGray, lineWidth: 1)
        )
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
                    .foregroundColor(Color.primaryText)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.selectionBlue)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(Color.borderGray)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.selectionBlue : Color.borderGray, lineWidth: 1)
            )
        }
    }
}

// MARK: - Preview
//
//struct CompetitionManagerView_Previews: PreviewProvider {
//    static var previews: some View {
//        CompetitionManagerView()
//            .preferredColorScheme(.light)
//            .previewDevice("iPhone 14")
//    }
//}
