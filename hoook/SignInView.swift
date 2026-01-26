//
//  SignInView.swift
//  hook
//

import SwiftUI

struct SignInView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    // Email/Password states
    @State private var email = ""
    @State private var password = ""

    // Phone states
    @State private var phoneNumber = ""
    @State private var verificationCode = ""
    @State private var verificationID: String?
    @State private var isCodeSent = false

    // Navigation states
    @State private var showSignUp = false
    @State private var signInMethod: SignInMethod = .email

    enum SignInMethod {
        case email
        case phone
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Logo/Header
                VStack(spacing: 12) {
                    Image("1")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 120)
                        .padding(.top, 40)

                    Text("Welcome to Hook")
                        .font(.montserratBold(size: 28))
                        .foregroundColor(.textPrimary)

                    Text("Sign in to track your games")
                        .font(.montserrat(size: 16))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
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

                // Sign In Method Picker
                Picker("Sign In Method", selection: $signInMethod) {
                    Text("Email").tag(SignInMethod.email)
                    Text("Phone").tag(SignInMethod.phone)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 24)

                // Email/Password or Phone Sign In
                if signInMethod == .email {
                    emailSignInForm
                } else {
                    phoneSignInForm
                }

                // Divider
                HStack {
                    Rectangle()
                        .fill(Color.cardBorder)
                        .frame(height: 1)
                    Text("OR")
                        .font(.montserratMedium(size: 14))
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal, 16)
                    Rectangle()
                        .fill(Color.cardBorder)
                        .frame(height: 1)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)

                // Google Sign In Button
                Button {
                    Task {
                        do {
                            try await authViewModel.signInWithGoogle()
                        } catch {
                            // Errors logged in ViewModel
                            print("Google sign-in failed:", error)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "globe")
                            .font(.system(size: 18))
                        Text("Continue with Google")
                            .font(.montserratSemiBold(size: 16))
                    }
                    .foregroundColor(.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.cardBackground)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cardBorder, lineWidth: 1))
                    .cornerRadius(12)
                }
                .disabled(authViewModel.isLoading)
                .padding(.horizontal, 24)

                // Sign Up Link
                HStack {
                    Text("Don't have an account?")
                        .font(.montserrat(size: 14))
                        .foregroundColor(.textSecondary)
                    Button {
                        showSignUp = true
                    } label: {
                        Text("Sign Up")
                            .font(.montserratSemiBold(size: 14))
                            .foregroundColor(.brandPrimary)
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .background(Color.screenBackground)
        .sheet(isPresented: $showSignUp) {
            SignUpView()
                .environmentObject(authViewModel)
        }
    }

    // MARK: - Email Sign In Form

    private var emailSignInForm: some View {
        VStack(spacing: 16) {
            // Email Field
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

            // Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.montserratMedium(size: 14))
                    .foregroundColor(.textPrimary)
                SecureField("Enter your password", text: $password)
                    .textContentType(.password)
                    .font(.montserrat(size: 16))
                    .foregroundColor(.textPrimary)
                    .padding()
                    .background(Color.cardBackground)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cardBorder, lineWidth: 1))
                    .cornerRadius(12)
            }

            // Sign In Button
            Button {
                Task {
                    do {
                        try await authViewModel.signIn(email: email, password: password)
                    } catch {
                        // Errors handled/logged in view model
                        print("Email sign-in failed:", error)
                    }
                }
            } label: {
                if authViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .buttonPrimaryText))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                } else {
                    Text("Sign In")
                        .font(.montserratSemiBold(size: 16))
                        .foregroundColor(.buttonPrimaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
            }
            .disabled(authViewModel.isLoading || email.isEmpty || password.isEmpty)
            .background(authViewModel.isLoading || email.isEmpty || password.isEmpty ? Color.gray.opacity(0.5) : Color.buttonPrimaryBackground)
            .cornerRadius(12)
            .padding(.top, 8)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Phone Sign In Form

    private var phoneSignInForm: some View {
        VStack(spacing: 16) {
            if !isCodeSent {
                // Phone Number Entry
                VStack(alignment: .leading, spacing: 8) {
                    Text("Phone Number")
                        .font(.montserratMedium(size: 14))
                        .foregroundColor(.textPrimary)

                    TextField("+1 (555) 123-4567", text: $phoneNumber)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                        .font(.montserrat(size: 16))
                        .foregroundColor(.textPrimary)
                        .padding()
                        .background(Color.cardBackground)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cardBorder, lineWidth: 1))
                        .cornerRadius(12)

                    Text("Include country code (e.g., +1 for US)")
                        .font(.montserrat(size: 12))
                        .foregroundColor(.textSecondary)
                }

                // Send Code Button
                Button {
                    sendVerificationCode()
                } label: {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .buttonPrimaryText))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    } else {
                        Text("Send Code")
                            .font(.montserratSemiBold(size: 16))
                            .foregroundColor(.buttonPrimaryText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                }
                .disabled(authViewModel.isLoading || phoneNumber.isEmpty)
                .background(authViewModel.isLoading || phoneNumber.isEmpty ? Color.gray.opacity(0.5) : Color.buttonPrimaryBackground)
                .cornerRadius(12)

            } else {
                // Verification Code Entry
                VStack(spacing: 12) {
                    Text("Code sent to \(phoneNumber)")
                        .font(.montserrat(size: 14))
                        .foregroundColor(.textSecondary)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Verification Code")
                            .font(.montserratMedium(size: 14))
                            .foregroundColor(.textPrimary)

                        TextField("123456", text: $verificationCode)
                            .textContentType(.oneTimeCode)
                            .keyboardType(.numberPad)
                            .font(.montserrat(size: 16))
                            .foregroundColor(.textPrimary)
                            .padding()
                            .background(Color.cardBackground)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cardBorder, lineWidth: 1))
                            .cornerRadius(12)
                    }

                    // Verify Button
                    Button {
                        verifyCode()
                    } label: {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .buttonPrimaryText))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        } else {
                            Text("Verify & Sign In")
                                .font(.montserratSemiBold(size: 16))
                                .foregroundColor(.buttonPrimaryText)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        }
                    }
                    .disabled(authViewModel.isLoading || verificationCode.isEmpty)
                    .background(authViewModel.isLoading || verificationCode.isEmpty ? Color.gray.opacity(0.5) : Color.buttonPrimaryBackground)
                    .cornerRadius(12)

                    // Resend Code
                    Button {
                        sendVerificationCode()
                    } label: {
                        Text("Resend Code")
                            .font(.montserratMedium(size: 14))
                            .foregroundColor(.brandPrimary)
                    }
                    .disabled(authViewModel.isLoading)
                }
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Helper Methods

    private func sendVerificationCode() {
        Task {
            do {
                let id = try await authViewModel.sendPhoneVerification(phoneNumber: phoneNumber)
                await MainActor.run {
                    verificationID = id
                    isCodeSent = true
                }
            } catch {
                print("sendVerificationCode failed:", error)
                // authViewModel.errorMessage will surface to the UI
            }
        }
    }

    private func verifyCode() {
        guard let verificationID = verificationID else { return }

        Task {
            do {
                try await authViewModel.signInWithPhone(verificationID: verificationID, verificationCode: verificationCode)
            } catch {
                print("verifyCode failed:", error)
                // authViewModel.errorMessage will surface to the UI
            }
        }
    }
}
