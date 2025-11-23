import SwiftUI

/// First-time user onboarding for instance selection
struct OnboardingView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var selectedInstance: AuthCredentials.InstanceType = .cloud
    
    var body: some View {
        NavigationView {
            VStack(spacing: Constants.UI.Spacing.large) {
                Spacer()
                
                // App Logo and Welcome
                VStack(spacing: Constants.UI.Spacing.medium) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.monicaBlue)
                    
                    Text("Welcome to Monica Client")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Your personal CRM companion")
                        .font(.title2)
                        .foregroundColor(.secondaryText)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // Instance Selection
                VStack(spacing: Constants.UI.Spacing.medium) {
                    Text("Choose your Monica instance")
                        .font(.headline)
                        .foregroundColor(.primaryText)
                    
                    VStack(spacing: Constants.UI.Spacing.small) {
                        ForEach(AuthCredentials.InstanceType.allCases, id: \.self) { instanceType in
                            InstanceSelectionCard(
                                instanceType: instanceType,
                                isSelected: selectedInstance == instanceType
                            ) {
                                selectedInstance = instanceType
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Continue Button
                Button(action: continueToLogin) {
                    HStack {
                        Text("Continue")
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.monicaBlue)
                    .foregroundColor(.white)
                    .cornerRadius(Constants.UI.CornerRadius.medium)
                }
                .padding(.horizontal)
                
                // Legal Links
                HStack(spacing: Constants.UI.Spacing.medium) {
                    Link("Privacy Policy", destination: URL(string: Constants.URLs.privacyPolicy)!)
                    Text("•")
                        .foregroundColor(.tertiaryText)
                    Link("Terms of Service", destination: URL(string: Constants.URLs.termsOfService)!)
                }
                .font(.caption)
                .foregroundColor(.secondaryText)
                .padding(.bottom)
            }
            .padding(Constants.UI.Spacing.large)
            .navigationBarHidden(true)
        }
    }
    
    private func continueToLogin() {
        authViewModel.selectedInstanceType = selectedInstance
        authViewModel.showLogin = true
    }
}

/// Instance selection card component
struct InstanceSelectionCard: View {
    let instanceType: AuthCredentials.InstanceType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Constants.UI.Spacing.medium) {
                VStack(alignment: .leading, spacing: Constants.UI.Spacing.small) {
                    Text(instanceType.displayName)
                        .font(.headline)
                        .foregroundColor(.primaryText)
                    
                    Text(instanceType.description)
                        .font(.subheadline)
                        .foregroundColor(.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .monicaBlue : .tertiaryText)
                    .font(.title2)
            }
            .padding(Constants.UI.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: Constants.UI.CornerRadius.medium)
                    .fill(Color.secondaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: Constants.UI.CornerRadius.medium)
                            .stroke(isSelected ? Color.monicaBlue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview("Onboarding") {
    OnboardingView()
        .environmentObject(AuthenticationViewModel())
}

#Preview("Instance Selection Card - Cloud") {
    InstanceSelectionCard(
        instanceType: .cloud,
        isSelected: true
    ) {}
    .padding()
}

#Preview("Instance Selection Card - Self-Hosted") {
    InstanceSelectionCard(
        instanceType: .selfHosted,
        isSelected: false
    ) {}
    .padding()
}