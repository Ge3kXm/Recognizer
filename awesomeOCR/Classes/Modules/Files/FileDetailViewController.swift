//
//  FileDetailViewController.swift
//  awesomeOCR
//
//  Created by maRk'sTheme on 2019/7/2.
//  Copyright © 2019 maRk. All rights reserved.
//

import UIKit
import SnapKit

class FileDetailViewController: UIViewController {
    var content: String? {
        didSet {
            
            // fix textview nil
            if textView == nil {
                for subView in view.subviews {
                    if subView is UITextView {
                        textView = subView as! UITextView
                    }
                }
            }
            textView.text = content
        }
    }

    var index: Int = 0

    @IBOutlet weak var textView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupNav()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupNav() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "保存",
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(saveClick))
    }
    
    @objc
    private func saveClick() {
        FileService.update(title: "", content: textView.text, index: index)
        SVProgressHUD.showSuccess(withStatus: "保存成功!")
        textView.resignFirstResponder()
    }
    
    @objc
    private func backClick() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func keyboardWillShow(_ notification: NSNotification) {
        guard let endFrame = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
                return
        }
        textView.snp.updateConstraints {
            $0.bottom.equalToSuperview().offset(-endFrame.height)
        }
    }

    @objc func keyboardWillHide(_ notification: NSNotification) {
        textView.snp.updateConstraints {
            $0.bottom.equalToSuperview()
        }
    }
    
    override func viewDidLayoutSubviews() {
        textView.setContentOffset(.zero, animated: false)
    }
}
