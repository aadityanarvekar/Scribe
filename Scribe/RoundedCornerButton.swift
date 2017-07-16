//
//  RoundedCornerButton.swift
//  Scribe
//
//  Created by AADITYA NARVEKAR on 7/14/17.
//  Copyright © 2017 Aaditya Narvekar. All rights reserved.
//

import UIKit

@IBDesignable
class RoundedCornerButton: UIButton {
    private var _cornerRadius: CGFloat = 30.0
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return _cornerRadius
        }
        
        set {
            _cornerRadius = cornerRadius
            if cornerRadius > 0 {
                self.layer.cornerRadius = cornerRadius
            }
        }
    }
    
    override func prepareForInterfaceBuilder() {
        self.layer.cornerRadius = cornerRadius
    }
    
}
