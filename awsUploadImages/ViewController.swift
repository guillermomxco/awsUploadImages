//
//  ViewController.swift
//  awsUploadImages
//
//  Created by Guillermo Cordero on 14/06/21.
//

import UIKit
import Amplify
import AWSCognitoAuthPlugin
import AWSCognitoIdentityProvider
import Photos

class ViewController: UIViewController, UINavigationControllerDelegate {
    
    @IBOutlet weak var imageViewSel: UIImageView!
    @IBOutlet weak var uploadImage: UIButton!
    @IBOutlet weak var downloadImage: UIButton!
    
    let imagePicker = UIImagePickerController()
    var nameFile = "XXX-XXX-XXX.jpeg"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
    }
    
    @IBAction func loadImageButtonTapped(_ sender: UIButton) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
            
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func getImageFromAWS(_ sender: UIButton) {
        self.downloadImage(self.nameFile, callback:{ (data) in
            self.showImage(data: data)
        })
    }
    
    func showImage(data: Data){
        DispatchQueue.main.async {
            self.imageViewSel.image = UIImage(data: data)
        }
    }
}



extension ViewController: UIImagePickerControllerDelegate {

    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        if let url = info[UIImagePickerController.InfoKey.imageURL.rawValue] as? URL {
            nameFile = url.lastPathComponent
        }
        if "public.image" == info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.mediaType)] as? String {
            let image: UIImage = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as! UIImage
            self.uploadImage(with: image.pngData()!, nameFile: nameFile)
        }

        dismiss(animated: true, completion: nil)
    }
    
    fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
        return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
    }
    
    fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
        return input.rawValue
    }
    
    @objc func uploadImage(with data: Data, nameFile: String) {
        Amplify.Storage.uploadData(key: nameFile, data: data,
            progressListener: { progress in
                print("ProgressUpload: \(progress)")
            }, resultListener: { (event) in
                switch event {
                case .success:
                    print("CompletedUpload: \(nameFile)")
                case .failure(let storageError):
                    print("FailedUpload: \(storageError.errorDescription). \(storageError.recoverySuggestion)")
            }
        })
    }
    
    func downloadImage(_ name: String, callback: @escaping (Data) -> Void ) {
           
       print("Downloading image : \(name)")

       _ = Amplify.Storage.downloadData(key: name,
           progressListener: { progress in
           }, resultListener: { (event) in
               switch event {
               case let .success(data):
                   print("CompleteDownload \(name) loaded")
                   callback(data)
               case let .failure(storageError):
                   print("Can not download image: \(storageError.errorDescription). \(storageError.recoverySuggestion)")
               }
           }
       )
    }
}

