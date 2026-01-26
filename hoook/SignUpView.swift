//
//  SignUpView.swift
//  hook
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image("1")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 100)
                            .padding(.top, 20)
                        
                        Text("Create Account")
                            .font(.montserratBold(size: 28))
                            .foregroundColor(.textPrimary)
                        
                        Text("Join the Hook community")
                            .font(.montserrat(size: 16))
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.bottom, 8)
                    
                    // Error Message
                    if let errorMessage = authViewModel.errorMessage {
                        Text(errorMessage)
                            .font(.montserrat(size: 14))
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal, 24)
                    }
                    
                    // Sign Up Form
                    VStack(spacing: 16) {
                        // First Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("First Name")
                                .font(.montserratMedium(size: 14))
                                .foregroundColor(.textPrimary)
                            TextField("Enter your first name", text: $firstName)
                                .textContentType(.givenName)
                                .font(.montserrat(size: 16))
                                .foregroundColor(.textPrimary)
                                .padding()
                                .background(Color.cardBackground)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cardBorder, lineWidth: 1))
                                .cornerRadius(12)
                        }
                        
                        // Last Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Last Name")
                                .font(.montserratMedium(size: 14))
                                .foregroundColor(.textPrimary)
                            TextField("Enter your last name", text: $lastName)
                                .textContentType(.familyName)
                                .font(.montserrat(size: 16))
                                .foregroundColor(.textPrimary)
                                .padding()
                                .background(Color.cardBackground)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cardBorder, lineWidth: 1))
                                .cornerRadius(12)
                        }
                        
                        // Email
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.montserratMedium(size: 14))
                                .foregroundColor(.textPrimary)
                            TextField("Enter your email", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .font(.montserrat(size: 16))
                                .foregroundColor(.textPrimary)
                                .padding()
                                .background(Color.cardBackground)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cardBorder, lineWidth: 1))
                                .cornerRadius(12)
                        }
                        
                        // Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.montserratMedium(size: 14))
                                .foregroundColor(.textPrimary)
                            SecureField("Create a password", text: $password)
                                .textContentType(.newPassword)
                                .font(.montserrat(size: 16))
                                .foregroundColor(.textPrimary)
                                .padding()
                                .background(Color.cardBackground)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cardBorder, lineWidth: 1))
                                .cornerRadius(12)
                            
                            Text("At least 6 characters")
                                .font(.montserrat(size: 12))
                                .foregroundColor(.textSecondary)
                        }
                        
                        // Sign Up Button
                        Button {
                            Task {
                                do {
                                    try await authViewModel.signUp(email: email, password: password, firstName: firstName, lastName: lastName)
                                    dismiss()
                                } catch {
                                    // Error is handled in authViewModel
                                }
                            }
                        } label: {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .buttonPrimaryText))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                            } else {
                                Text("Sign Up")
                                    .font(.montserratSemiBold(size: 16))
                                    .foregroundColor(.buttonPrimaryText)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                            }
                        }
                        .disabled(authViewModel.isLoading || email.isEmpty || password.isEmpty || firstName.isEmpty || lastName.isEmpty)
                        .background(authViewModel.isLoading || email.isEmpty || password.isEmpty || firstName.isEmpty || lastName.isEmpty ? Color.gray.opacity(0.5) : Color.buttonPrimaryBackground)
                        .cornerRadius(12)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
            }
            .background(Color.screenBackground)
            .navigationTitle("Sign Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.textPrimary)
                    }
                }
            }
        }
    }
}
