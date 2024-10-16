//
//  TaskAwareButton.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/15/24.
//

import SwiftUI

enum TaskStatus: Equatable {
    case idle
    case failed(String)
    case success
}

struct TaskAwareButton<Label: View>: View {
    
    var showErrorsAsAlert: Bool
    var buttonColor: Color
    var contentColor: Color
    var action: () async -> TaskStatus
    var label: () -> Label
    
    @State private var isWorking: Bool = false
    @State private var taskStatus: TaskStatus = .idle
    @State private var isFailed: Bool = false
    @State private var wiggle: Bool = false
    
    public init(
        buttonColor: Color = .accentColor,
        contentColor: Color = .white,
        showErrorsAsAlert: Bool = false,
        action: @escaping () async -> TaskStatus,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.buttonColor = buttonColor
        self.contentColor = contentColor
        self.showErrorsAsAlert = showErrorsAsAlert
        self.action = action
        self.label = label
    }
    
    @State private var showPopup: Bool = false
    @State private var popupMessage: String = ""
    
    var body: some View {
        Button {
            Task {
                isWorking = true
                taskStatus = await action()
                
                switch taskStatus {
                case .idle:
                    isFailed = false
                case .failed(let reason):
                    isFailed = true
                    popupMessage = reason
                case .success:
                    isFailed = false
                }
                
                wiggle = isFailed
                try? await Task.sleep(for: .seconds(0.8))
                showPopup = isFailed
                
                taskStatus = .idle
                isWorking = false
            }
        } label: {
            label()
                .padding()
                .foregroundColor(contentColor)
                .opacity(isWorking ? 0 : 1)
                .lineLimit(1)
                .frame(width: isWorking ? 48 : nil, height: 48)
                .background {
                    RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous)
                        .fill(taskStatus == .idle
                              ? buttonColor
                              : taskStatus == .success
                              ? .green
                              : .red)
                }
                .clipped()  // So shadows only apply to capsule shape
                .overlay {
                    if isWorking && taskStatus == .idle {
                        ProgressView()
                            .tint(contentColor)
                    }
                }
                .overlay {
                    if taskStatus != .idle {
                        Image(systemName: isFailed ? "exclamationmark" : "checkmark")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                    }
                }
        }
        .disabled(isWorking)
        .errorPopover(
            isPresented: $showPopup,
            text: popupMessage,
            showAsAlert: showErrorsAsAlert
        )
        .animation(.snappy(), value: isWorking)
        .animation(.snappy(), value: taskStatus)
        .shake($wiggle)
    }
}

fileprivate extension View {
    @ViewBuilder func errorPopover(isPresented: Binding<Bool>, text: String, showAsAlert: Bool = false) -> some View {
        if showAsAlert {
            self.alert(text, isPresented: isPresented) {}
        } else {
            self.popover(isPresented: isPresented) {
                Text(text)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, .paddingHorizontalButtonMedium)
                    .padding(.vertical, .paddingVerticalButtonMedium)
                    .presentationCompactAdaptation(.popover)
            }
        }
    }
}

#Preview {
    ZStack {
        VStack {
            TaskAwareButton() {
                try? await Task.sleep(for: .seconds(2))
                return .failed("Password Incorrect!")
            } label: {
                HStack(spacing: 10) {
                    Text(String("Failing"))
                }
                .fontWeight(.bold)
            }
            
            TaskAwareButton() {
                try? await Task.sleep(for: .seconds(2))
                return .success
            } label: {
                HStack(spacing: 10) {
                    Text(String("Succeeding"))
                    Image(systemName: "chevron.right")
                }
                .fontWeight(.bold)
            }
            
            TaskAwareButton() {
                try? await Task.sleep(for: .seconds(2))
                return .failed("failed")
            } label: {
                Text(String("Continue"))
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .padding(.horizontal)
            }
        }
    }
    .preferredColorScheme(.light)
}
