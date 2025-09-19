//
//  ImagesOnboardingView.swift
//  My Dictionary
//
//  Created by AI Assistant on 1/9/25.
//

import SwiftUI

struct ImagesOnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    let onCompleted: (() -> Void)?
    
    private let totalPages = 4
    
    init(isPresented: Binding<Bool>, onCompleted: (() -> Void)? = nil) {
        self._isPresented = isPresented
        self.onCompleted = onCompleted
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Content
            TabView(selection: $currentPage) {
                // Page 1: Word Details with Image
                wordDetailsPreviewPage
                    .tag(0)
                
                // Page 2: How to Add Image in Word Details
                addImageInDetailsPage
                    .tag(1)
                
                // Page 3: How to Add Image During Adding Word
                addImageDuringAddWordPage
                    .tag(2)
                
                // Page 4: Images in Quizzes
                imagesInQuizzesPage
                    .tag(3)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)
            
            // Bottom Controls
            bottomControlsView
        }
        .groupedBackground()
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 16) {
            // Drag Handle
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.secondary)
                .frame(width: 36, height: 5)
                .padding(.top, 8)
            
            // Title
            Text("Enhance Your Learning with Images")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            // Page Indicator
            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut, value: currentPage)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }
    
    // MARK: - Page 1: Word Details with Image
    
    private var wordDetailsPreviewPage: some View {
        VStack(spacing: 0) {
            // Word Details Screenshot
            Image(.wordWithImageScreenshot)
                .resizable()
                .scaledToFit()
                .clipShape(.rect(cornerRadius: 16))
                .shadow(radius: 8)
                .padding(16)

            // Description
            VStack(spacing: 12) {
                Text("See Your Words Come to Life")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Every word in your dictionary can have a beautiful, relevant image that helps you remember and understand it better.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Page 2: How to Add Image in Word Details
    
    private var addImageInDetailsPage: some View {
        VStack(spacing: 24) {
            // Image Slideshow
            VStack(spacing: 16) {
                ImageSlideshowView()
                    .frame(height: 200)
                    .clipShape(.rect(cornerRadius: 16))
                    .shadow(radius: 8)
                    .padding(16)

                // Step-by-step instructions
                VStack(alignment: .leading, spacing: 12) {
                    Spacer()

                    Text("Add Images to Existing Words")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Spacer()

                    instructionStep(
                        number: 1,
                        title: "Find the image section",
                        description: "Scroll down to see the 'Add Image' button"
                    )
                    
                    instructionStep(
                        number: 2,
                        title: "Choose your image",
                        description: "Browse thousands of high-quality photos"
                    )
                    
                    instructionStep(
                        number: 3,
                        title: "Click 'Done'",
                        description: "Enjoy your customized word now!"
                    )

                    Spacer()
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Page 3: How to Add Image During Adding Word
    
    private var addImageDuringAddWordPage: some View {
        VStack(spacing: 24) {
            // Mock Add Word Screen
            VStack(spacing: 16) {
                // Word Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Word")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                        .frame(height: 44)
                        .overlay {
                            HStack {
                                Text("Enter your word...")
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                        }
                }
                
                // Definitions
                VStack(alignment: .leading, spacing: 8) {
                    Text("Definitions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                        .frame(height: 80)
                        .overlay {
                            HStack {
                                Text("Add definitions...")
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                        }
                }
                
                // Image Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Image")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(height: 60)
                        .overlay {
                            HStack {
                                Image(systemName: "photo.badge.plus")
                                    .foregroundColor(.accentColor)
                                Text("Add Image")
                                    .foregroundColor(.accentColor)
                                    .fontWeight(.medium)
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                        }
                }
            }
            .padding(.horizontal, 20)
            
            // Description
            VStack(spacing: 12) {
                Text("Add Images While Creating Words")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("When adding new words, you can immediately search for and add relevant images. Start with a complete, visual vocabulary from day one.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Page 4: Images in Quizzes
    
    private var imagesInQuizzesPage: some View {
        VStack(spacing: 24) {
            // Mock Quiz Screen
            VStack(spacing: 16) {
                // Quiz Question with Image
                VStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [.green.opacity(0.3), .blue.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 120)
                        .overlay {
                            VStack {
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                                Text("Quiz Image")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                        }
                    
                    Text("What is this?")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                // Answer Options
                VStack(spacing: 8) {
                    answerOption(text: "Apple", isCorrect: true)
                    answerOption(text: "Orange", isCorrect: false)
                    answerOption(text: "Banana", isCorrect: false)
                }
            }
            .padding(.horizontal, 20)
            
            // Description
            VStack(spacing: 12) {
                Text("Images Make Quizzes More Effective")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("When you practice with quizzes, images help you make stronger connections between words and their meanings. Visual learning is proven to improve memory retention.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Bottom Controls
    
    private var bottomControlsView: some View {
        VStack(spacing: 12) {
            // Action Buttons
            HStack(spacing: 12) {
                if currentPage > 0 {
                    ActionButton(Loc.Actions.back) {
                        withAnimation {
                            currentPage -= 1
                        }
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                }
                
                if currentPage < totalPages - 1 {
                    ActionButton(Loc.Actions.next, style: .borderedProminent) {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                } else {
                    ActionButton("Get Started", style: .borderedProminent) {
                        isPresented = false
                        onCompleted?()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                }
            }

            // Skip Button
            Button("Skip") {
                isPresented = false
                onCompleted?()
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .hidden(currentPage == totalPages - 1)
        }
        .padding(vertical: 12, horizontal: 16)
    }
    
    // MARK: - Helper Views
    
    private func instructionStep(number: Int, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Color.accentColor)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    private func answerOption(text: String, isCorrect: Bool) -> some View {
        HStack {
            Text(text)
                .font(.body)
            Spacer()
            if isCorrect {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isCorrect ? Color.green.opacity(0.1) : Color(.systemGray6))
        )
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Image Slideshow View

private struct ImageSlideshowView: View {
    @State private var currentImageIndex = 0
    @State private var timer: Timer?
    
    private let images = [
        "word_image_onboarding_1step",
        "word_image_onboarding_2step", 
        "word_image_onboarding_3step"
    ]
    
    private let imageChangeInterval: TimeInterval = 3.0
    
    var body: some View {
        ZStack {
            // Current Image
            Image(images[currentImageIndex])
                .resizable()
                .scaledToFit()
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            
            // Image Indicators
            VStack {
                Spacer()
                HStack(spacing: 8) {
                    ForEach(0..<images.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentImageIndex ? Color.white : Color.white.opacity(0.5))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentImageIndex ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: currentImageIndex)
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .onAppear {
            startSlideshow()
        }
        .onDisappear {
            stopSlideshow()
        }
    }
    
    private func startSlideshow() {
        timer = Timer.scheduledTimer(withTimeInterval: imageChangeInterval, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentImageIndex = (currentImageIndex + 1) % images.count
            }
        }
    }
    
    private func stopSlideshow() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            
            ImagesOnboardingView(isPresented: .constant(true))
                .frame(height: 600)
        }
    }
}
