//
//  TMTopicInterface.swift
//  TMTopic
//
//  Created by Derrick  Ho on 1/3/15.
//  Copyright (c) 2015 dnthome. All rights reserved.
//

import Foundation
import UIKit

class TMTopicInterface: UIViewController, UIScrollViewDelegate {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var topicView: UIView!
    
    override func viewDidLoad() {
        scrollView.layer.masksToBounds = true
        scrollView.clipsToBounds = false
    }
    
    //MARK: UIScrollViewDelegate
    func scrollViewDidScroll(scrollView: UIScrollView) {
        //To prevent diagonal
        var dx = fabs(scrollView.contentOffset.x)
        var dy = fabs(scrollView.contentOffset.y)
        if dx >= dy {
            scrollView.contentOffset = CGPoint(x: scrollView.contentOffset.x, y: 0)
        } else {
            scrollView.contentOffset = CGPoint(x: 0, y: scrollView.contentOffset.y)
        }
    }
    
    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}