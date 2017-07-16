//
//  RoundedCornerView.swift
//  Scribe
//
//  Created by AADITYA NARVEKAR on 7/14/17.
//  Copyright © 2017 Aaditya Narvekar. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    func makeSquareViewCircular() {
        guard self.frame.size.width == self.frame.size.height else {
            print("View is not a square")
            return
        }
        self.layer.cornerRadius = self.frame.size.width / 2
    }
}
