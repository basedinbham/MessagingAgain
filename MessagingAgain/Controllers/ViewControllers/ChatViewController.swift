//
//  ChatViewController.swift
//  MessagingAgain
//
//  Created by Kyle Warren on 9/17/21.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import FirebaseFirestore
import FirebaseAuth
import SDWebImage

class ChatViewController: MessagesViewController, InputBarAccessoryViewDelegate, MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    
    //MARK: - PROPERTIES
    var currentUser: User = Auth.auth().currentUser!
    private var docReference: DocumentReference?
    var messages: [Message] = []
    
    // Will send profile of second user from previous class that is navigating to chat view.
    
    var user2Name: String?
    var user2ImgUrl: String?
    var user2UID: String?
    
    //MARK: - LIFECYCLES
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        // Do any additional setup after loading the view.
    }
    
    //MARK: - METHODS
    func setupViews() {
        self.title = user2Name ?? "Chat"
        
        navigationItem.largeTitleDisplayMode = .never
        
        maintainPositionOnKeyboardFrameChanged = true
        scrollsToLastItemOnKeyboardBeginsEditing = true
        
        messageInputBar.inputTextView.tintColor = .systemBlue
        messageInputBar.sendButton.setTitleColor(.systemTeal, for: .normal)
        messageInputBar.delegate = self
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
    }
    
    // Create new chat if there is no chat available between users
    // Load chat if it is available for users
    func loadChat() {
        // Fetch all chats which has current user in it
        let db = Firestore.firestore().collection("Chats").whereField("users", arrayContains: Auth.auth().currentUser?.uid ?? "User 1 not found")
        
        db.getDocuments { (chatQuerySnap, error) in
            if let error = error {
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return
                
            } else {
                // Count number of docucments returned
                guard let queryCount = chatQuerySnap?.documents.count else {
                    return
                }
                
                if queryCount == 0 {
                    // If documents count is zero there is no chat available, & we must create a new instance
                    self.createNewChat()
                }
                
                else if queryCount >= 1 {
                    // There are chats available for current user
                    for doc in chatQuerySnap!.documents {
                        let chat = Chat(dictionary: doc.data())
                        
                        // Get the chat for user2
                        // KWARR
                        if (chat?.users.contains(self.user2UID ?? "ID Not Found")) == true {
                            self.docReference = doc.reference
                            
                            // Fetch thread collection
                            doc.reference.collection("thread")
                                .order(by: "created", descending: false)
                                .addSnapshotListener(includeMetadataChanges: true, listener: { (threadQuery, error) in
                                    
                                    if let error = error {
                                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                                        return
                                    } else {
                                        self.messages.removeAll()
                                        
                                        for message in threadQuery!.documents {
                                            let msg = Message(dictionary: message.data())
                                            self.messages.append(msg!)
                                            print("Data: \(msg?.content ?? "No Message Found")")
                                        }
                                        // We will edid viewDidLoad below to solve the error
                                        self.messagesCollectionView.reloadData()
                                        self.messagesCollectionView.scrollToLastItem(at: .bottom, animated: true)
                                    }
                                })
                            return
                        } // End of if statement
                    } // End of for statement
                    self.createNewChat()
                } else {
                    print("Error, oh no!")
                }
            }
        }
    }
    func createNewChat() {
        //KWARR
        let users = [self.currentUser.uid, self.user2UID]
        let data: [String: Any] = [
            "users": users
        ]
        
        let db = Firestore.firestore().collection("Chats")
        db.addDocument(data: data) { (error) in
            
            if let error = error {
                print("Cannot create chat! \(error)")
                return
            } else {
                self.loadChat()
            }
        }
    }
    
    // Insert new message in feed
    private func insertNewMessage(_ message: Message) {
        // Append message to messages array & reload
        messages.append(message)
        messagesCollectionView.reloadData()
        
        DispatchQueue.main.async {
            self.messagesCollectionView.scrollToLastItem(at: .bottom, animated: true)
        }
    }
    
    // Save message on firestore
    private func save(_ message: Message) {
        // Prepare data for firestore collection
        let data: [String: Any] = [
            "content": message.content,
            "created": message.created,
            "id": message.id,
            "senderID": message.senderID,
            "senderName": message.senderName
        ]
        
        // Write to thread using saved document reference in load chat function
        docReference?.collection("thread").addDocument(data: data, completion: { (error) in
            
            if let error = error {
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return
            }
            self.messagesCollectionView.scrollToLastItem(at: .bottom, animated: true)
        })
    }
    
    // InputBarAccessoryView delegate methods
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        // Send Button method
        let message = Message(id: UUID().uuidString, content: text, created: Timestamp(), senderID: currentUser.uid, senderName: currentUser.displayName!)
        
        // Call fuction to insert & save message
        insertNewMessage(message)
        save(message)
        
        // Clear text input field
        inputBar.inputTextView.text = ""
        
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToLastItem(at: .bottom, animated: true)
    }
    
    // Message data source delegate method
    func currentSender() -> SenderType {
        return chatUser(senderId: Auth.auth().currentUser!.uid, displayName: (Auth.auth().currentUser?.displayName ?? "Name not found"))
    }
    
    // Returns MessageType (defined in Messages.swift as text)
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    // Return total number of messages
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        if messages.count == 0 {
            print("No messages")
            return 0
        } else {
            return messages.count
        }
    }
    
    //Default avatar size.  This method handles size of user avatar displayed alongside message
    func avatarSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        return .zero
    }
    //KWARR Explore delegate funcitons more
    
    // MessagesDisplayDelegate method; will provide message bubble dimensions / shape
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .blue: .lightGray
    }
    
    // Display avatar
    //    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
    //        // If current user, show their photo
    //        if message.sender.senderId == currentUser.uid {
    //
    //            SDWebImageManager.shared.loadImage(with: URL(string: user2ImgUrl!), options: .highPriority, progress: nil) { (image, data, error, cacheType, isFinished, imageUrl) in
    //                avatarView.image = image
    //            }
    //        }
    //    }
    
    //  Bubble style: tail
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight: .bottomLeft
        return .bubbleTail(corner, .curved)
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
} // End of Class
