//
//  FirebaseUserDataProvider.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/15/24.
//

import Foundation
import FirebaseFirestore
import Combine

class FirebaseUserDataProvider: UserDataProvider {
    
    private let pollingInterval: TimeInterval = 30
    
    private var timer: Timer?
    private var userId: UserId?
    
    @Published var userData: UserData? = nil
    var userDataPublisher: AnyPublisher<UserData,Never> {
        $userData
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    var userDocListener: ListenerRegistration?
    
    let userRepo = FirebaseUserRepository()
    
    deinit {
        stopTimer()
    }
    
    private func startTimer() {
        stopTimer()
        
        timer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            self?.fetchUserData()
        }
        RunLoop.current.add(timer!, forMode: .default)
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func fetchUserData() {
        Task {
            guard let userId = userId else { return }
            
            if let userData = try? await userRepo.fetchUserData(withId: userId) {
                RunLoop.main.perform { self.userData = userData }
            } else {
                RunLoop.main.perform { self.userData = UserData(id: userId) }
            }
        }
    }
    
    func startListeningToUser(withId id: UserId) {
        self.userId = id
        fetchUserData()
        startTimer()
    }
    
    func stopListeningToUser() {
        stopTimer()
        self.userId = nil
        self.userData = nil
    }
}
