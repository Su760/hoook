//
//  SplashScreenView.swift
//  hook
//
//  Created for Hook app
//

import SwiftUI

struct SplashScreenView: View {
    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 0.8
    @Binding var showSplash: Bool
    
    var body: some View {
        ZStack {
            // Primary Brand Blue background
            Color.brandPrimary
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Display logo.png from Assets
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 250)
                    .scaleEffect(scale)
                    .opacity(opacity)
                
                Spacer()
            }
        }
        .onAppear {
            // Animate in
            withAnimation(.easeOut(duration: 0.5)) {
                scale = 1.0
            }
            
            // Hold for 3 seconds, then fade out
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeOut(duration: 0.5)) {
                    opacity = 0.0
                }
                
                // Hide splash after fade
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showSplash = false
                }
            }
        }
    }
}

#Preview {
    SplashScreenView(showSplash: .constant(true))
}
