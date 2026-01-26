//
//  AuthViewModel.swift
//  hook
//
//  Firebase authentication view model (updated)
//

import Foundation
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import Combine
import UIKit

@MainActor
class AuthViewModel: ObservableObject {
    @Published var user: FirebaseAuth.User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var handle: AuthStateDidChangeListenerHandle?

    init() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
        }
    }

    deinit {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Helpers

    /// Format input into E.164-like string (keeps leading + if present, otherwise adds +)
    /// Basic sanitization: keep digits and optional leading +
    private func formatE164(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let allowed = Set(Array("+0123456789"))
        let filtered = String(trimmed.filter { allowed.contains($0) })
        if filtered.isEmpty { return trimmed }
        if filtered.first == "+" { return filtered }
        return "+" + filtered
    }

    private func setError(_ error: Error) {
        let ns = error as NSError
        print("🔥 Firebase Auth Error code:", ns.code)
        print("🔥 Firebase Auth domain:", ns.domain)
        print("🔥 Firebase Auth userInfo:", ns.userInfo)
        self.errorMessage = error.localizedDescription
    }

    // MARK: - Email Auth

    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            user = result.user
        } catch {
            setError(error)
            throw error
        }
        isLoading = false
    }

    func signUp(email: String, password: String, firstName: String, lastName: String) async throws {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = "\(firstName) \(lastName)"
            try await changeRequest.commitChanges()
            user = result.user
        } catch {
            setError(error)
            throw error
        }
        isLoading = false
    }

    // MARK: - Google Auth

    func signInWithGoogle() async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw NSError(domain: "AuthViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing client ID"])
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let rootVC = scene.windows.first?.rootViewController
        else {
            throw NSError(domain: "AuthViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "No root view controller"])
        }

        isLoading = true
        errorMessage = nil

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
            guard let idToken = result.user.idToken?.tokenString else {
                throw NSError(domain: "AuthViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing ID token"])
            }
            let accessToken = result.user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            let authResult = try await Auth.auth().signIn(with: credential)
            user = authResult.user
        } catch {
            setError(error)
            throw error
        }

        isLoading = false
    }

    // MARK: - Phone Auth

    /// Send verification code to the provided phone number (input is sanitized)
    /// Returns verificationID
    func sendPhoneVerification(phoneNumber rawNumber: String) async throws -> String {
        isLoading = true
        errorMessage = nil

        let cleaned = formatE164(rawNumber)
        print("📱 Sending verification to:", cleaned)

        do {
            let verificationID = try await PhoneAuthProvider.provider().verifyPhoneNumber(cleaned, uiDelegate: nil)
            isLoading = false
            return verificationID
        } catch {
            setError(error)
            isLoading = false
            throw error
        }
    }

    /// Sign in with phone number using verification code
    func signInWithPhone(verificationID: String, verificationCode: String) async throws {
        isLoading = true
        errorMessage = nil

        do {
            let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: verificationCode)
            let result = try await Auth.auth().signIn(with: credential)
            user = result.user
        } catch {
            setError(error)
            throw error
        }

        isLoading = false
    }

    // MARK: - Sign Out

    func signOut() {
        do {
            try Auth.auth().signOut()
            user = nil
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
