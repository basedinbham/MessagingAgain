//
//  ViewController.swift
//  MessagingAgain
//
//  Created by Kyle Warren on 9/17/21.
//

import UIKit
import FirebaseAuth
import GoogleSignIn
import Firebase

class ViewController: UIViewController {
    
    @IBOutlet weak var googleSignIn: GIDSignInButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func googleSignInTapped(_ sender: Any) {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }

        // Create Google Sign In configuration object.
        let config = GIDConfiguration(clientID: clientID)

        // Start the sign in flow!
        GIDSignIn.sharedInstance.signIn(with: config, presenting: self) { [unowned self] user, error in

          if let error = error {
            // ...
            return
          }

          guard
            let authentication = user?.authentication,
            let idToken = authentication.idToken
          else {
            return
          }

          let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                         accessToken: authentication.accessToken)

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                  return
                }
                //performSegue(withIdentifier: "toDetailVC", sender: self)
            }
        }
    }
    


    
    
    
    
} // End of Class

