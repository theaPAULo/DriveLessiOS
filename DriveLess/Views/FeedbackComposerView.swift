//
//  FeedbackComposerView.swift
//  DriveLess
//
//  Created by Paul Soni on 6/24/25.
//


//
//  FeedbackComposerView.swift
//  DriveLess
//
//  Contact/Feedback composer with hidden email recipient
//

import SwiftUI
import MessageUI
import UIKit

struct FeedbackComposerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var feedbackType: FeedbackType = .general
    @State private var feedbackText: String = ""
    @State private var showingMailComposer = false
    @State private var canSendMail = true  // Start as true, check in onAppear
    @State private var showingNoMailAlert = false
    
    // MARK: - Color Theme (matching app style)
    private let primaryGreen = Color(red: 0.2, green: 0.4, blue: 0.2)
    private let accentBrown = Color(red: 0.4, green: 0.3, blue: 0.2)
    
    // MARK: - Feedback Types
    enum FeedbackType: String, CaseIterable {
        case bug = "Bug Report"
        case feature = "Feature Request"
        case general = "General Feedback"
        
        var icon: String {
            switch self {
            case .bug: return "ladybug.fill"
            case .feature: return "lightbulb.fill"
            case .general: return "bubble.left.and.bubble.right.fill"
            }
        }
        
        var description: String {
            switch self {
            case .bug: return "Report a problem or issue"
            case .feature: return "Suggest a new feature"
            case .general: return "General comments or questions"
            }
        }
        
        var emailSubject: String {
            switch self {
            case .bug: return "DriveLess iOS - Bug Report"
            case .feature: return "DriveLess iOS - Feature Request"
            case .general: return "DriveLess iOS - Feedback"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // MARK: - Header
                    headerSection
                    
                    // MARK: - Feedback Type Selection
                    feedbackTypeSection
                    
                    // MARK: - Message Input
                    messageInputSection
                    
                    // MARK: - Send Button
                    sendButton
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("Send Feedback")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .sheet(isPresented: $showingMailComposer) {
            MailComposerView(
                subject: feedbackType.emailSubject,
                messageBody: generateEmailBody(),
                onDismiss: { result in
                    handleMailResult(result)
                }
            )
        }
        .alert("Email Not Available", isPresented: $showingNoMailAlert) {
            Button("OK") { }
        } message: {
            Text("Please set up an email account in your device settings to send feedback.")
        }
        .onAppear {
            // Check mail availability when view appears
            canSendMail = MFMailComposeViewController.canSendMail()
            print("📧 Can send mail: \(canSendMail)")
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [primaryGreen, accentBrown]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "envelope.open.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white)
                )
            
            VStack(spacing: 8) {
                Text("We'd Love Your Feedback!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Help us improve DriveLess by sharing your thoughts, reporting bugs, or suggesting new features.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
    }
    
    // MARK: - Feedback Type Selection
    private var feedbackTypeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What would you like to share?")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                ForEach(FeedbackType.allCases, id: \.self) { type in
                    FeedbackTypeButton(
                        type: type,
                        isSelected: feedbackType == type,
                        action: {
                            feedbackType = type
                            // Add haptic feedback
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                        }
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Message Input Section
    private var messageInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Message")
                .font(.headline)
                .foregroundColor(.primary)
            
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .frame(minHeight: 120)
                
                if feedbackText.isEmpty {
                    Text(placeholderText)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
                
                TextEditor(text: $feedbackText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.clear)
                    .scrollContentBackground(.hidden) // iOS 16+ to hide default background
            }
            
            Text("\(feedbackText.count)/500 characters")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private var sendButton: some View {
        Button(action: sendFeedback) {
            HStack(spacing: 12) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 16, weight: .medium))
                
                Text("Send Feedback")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [primaryGreen, primaryGreen.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: primaryGreen.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .disabled(feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity(feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
    }
    
    // MARK: - Computed Properties
    
    private var placeholderText: String {
        switch feedbackType {
        case .bug:
            return "Please describe the bug you encountered. Include steps to reproduce the issue if possible..."
        case .feature:
            return "Describe the feature you'd like to see added to DriveLess..."
        case .general:
            return "Share your thoughts, questions, or suggestions..."
        }
    }
    
    // MARK: - Helper Methods
    
    private func sendFeedback() {
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Check mail availability each time (in case it changed)
        let canSendMailNow = MFMailComposeViewController.canSendMail()
        print("📧 Attempting to send feedback. Can send mail: \(canSendMailNow)")
        
        if canSendMailNow {
            showingMailComposer = true
        } else {
            print("❌ Mail not available - showing alert")
            showingNoMailAlert = true
        }
    }
    
    private func generateEmailBody() -> String {
        var body = ""
        
        // User's message
        body += feedbackText
        body += "\n\n"
        
        // Separator
        body += "--- App Information ---\n"
        
        // App details (helpful for debugging)
        body += "App Version: 1.0.0\n"
        body += "iOS Version: \(UIDevice.current.systemVersion)\n"
        body += "Device: \(UIDevice.current.model)\n"
        body += "Device Name: \(UIDevice.current.name)\n"
        
        // Date/time
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .medium
        body += "Date: \(formatter.string(from: Date()))\n"
        
        return body
    }
    
    private func handleMailResult(_ result: MFMailComposeResult) {
        switch result {
        case .sent:
            print("✅ Feedback email sent successfully")
            // Add success haptic
            let successFeedback = UINotificationFeedbackGenerator()
            successFeedback.notificationOccurred(.success)
            
            // Close the feedback composer
            dismiss()
            
        case .cancelled:
            print("📧 User cancelled email")
            
        case .saved:
            print("💾 Email saved as draft")
            
        case .failed:
            print("❌ Email failed to send")
            // Add error haptic
            let errorFeedback = UINotificationFeedbackGenerator()
            errorFeedback.notificationOccurred(.error)
            
        @unknown default:
            print("⚠️ Unknown email result")
        }
    }
}

// MARK: - Feedback Type Button Component
struct FeedbackTypeButton: View {
    let type: FeedbackComposerView.FeedbackType
    let isSelected: Bool
    let action: () -> Void
    
    private let primaryGreen = Color(red: 0.2, green: 0.4, blue: 0.2)
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: type.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isSelected ? .white : primaryGreen)
                    .frame(width: 32)
                
                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(type.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(type.description)
                        .font(.system(size: 14))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? .white : .secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? primaryGreen : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(primaryGreen, lineWidth: isSelected ? 0 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Mail Composer UIViewControllerRepresentable
struct MailComposerView: UIViewControllerRepresentable {
    let subject: String
    let messageBody: String
    let onDismiss: (MFMailComposeResult) -> Void
    
    // MARK: - Hidden email recipient (your email address)
    private let recipientEmail = ConfigurationManager.shared.feedbackEmail

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        
        // Set delegate
        composer.mailComposeDelegate = context.coordinator
        
        // Configure email (recipient is hidden from user)
        composer.setToRecipients([recipientEmail])
        composer.setSubject(subject)
        composer.setMessageBody(messageBody, isHTML: false)
        
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let onDismiss: (MFMailComposeResult) -> Void
        
        init(onDismiss: @escaping (MFMailComposeResult) -> Void) {
            self.onDismiss = onDismiss
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            onDismiss(result)
            controller.dismiss(animated: true)
        }
    }
}

#Preview {
    FeedbackComposerView()
}
