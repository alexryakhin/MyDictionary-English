import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import AuthenticationServices

final class FirebaseDebugService {
    static let shared = FirebaseDebugService()
    
    private init() {}
    
    func checkFirebaseConfiguration() {
        print("🔍 [FirebaseDebug] Checking Firebase configuration...")
        
        // Check if Firebase is configured
        if let app = FirebaseApp.app() {
            print("✅ [FirebaseDebug] Firebase is configured")
            print("📝 [FirebaseDebug] App name: \(app.name)")
            print("📝 [FirebaseDebug] App options: \(app.options)")
        } else {
            print("❌ [FirebaseDebug] Firebase is NOT configured")
        }
        
        // Check Firestore connectivity
        let db = Firestore.firestore()
        print("📡 [FirebaseDebug] Firestore instance created")
        
        // Test a simple read operation
        db.collection("test").document("test").getDocument { document, error in
            if let error = error {
                print("❌ [FirebaseDebug] Firestore connectivity test failed: \(error.localizedDescription)")
            } else {
                print("✅ [FirebaseDebug] Firestore connectivity test passed")
            }
        }
    }
    
    func checkAuthenticationStatus() {
        print("🔍 [FirebaseDebug] Checking authentication status...")
        
        if let user = Auth.auth().currentUser {
            print("✅ [FirebaseDebug] User is authenticated")
            print("📝 [FirebaseDebug] User ID: \(user.uid)")
            print("📝 [FirebaseDebug] User email: \(user.email ?? "nil")")
        } else {
            print("❌ [FirebaseDebug] No user is authenticated")
        }
    }
    
    func testFirestoreWritePermissions() {
        print("🔍 [FirebaseDebug] Testing Firestore write permissions...")
        
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ [FirebaseDebug] No authenticated user for write test")
            return
        }
        
        let db = Firestore.firestore()
        let testData: [String: Any] = [
            "test": true,
            "timestamp": Timestamp(date: Date()),
            "userId": userId
        ]
        
        // Test write to private dictionary path
        let privateDocRef = db.collection("users").document(userId)
            
            .collection("words").document("test-write")
        
        print("📝 [FirebaseDebug] Attempting to write to: \(privateDocRef.path)")
        
        // Add timeout
        let timeoutTask = DispatchWorkItem {
            print("⏰ [FirebaseDebug] Write test timed out after 10 seconds")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: timeoutTask)
        
        privateDocRef.setData(testData) { error in
            timeoutTask.cancel() // Cancel timeout if we get a response
            
            if let error = error {
                print("❌ [FirebaseDebug] Write test failed: \(error.localizedDescription)")
            } else {
                print("✅ [FirebaseDebug] Write test successful")
                
                // Clean up the test document
                privateDocRef.delete { error in
                    if let error = error {
                        print("⚠️ [FirebaseDebug] Failed to clean up test document: \(error.localizedDescription)")
                    } else {
                        print("🧹 [FirebaseDebug] Test document cleaned up")
                    }
                }
            }
        }
    }
} 
