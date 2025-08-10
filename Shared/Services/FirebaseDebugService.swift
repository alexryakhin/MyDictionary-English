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
    

} 
