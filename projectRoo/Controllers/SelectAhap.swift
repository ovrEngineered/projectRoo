//
//  SelectAhap.swift
//  ovrHapticCollar
//
//  Created by Christopher Armenio on 12/11/20.
//  Copyright © 2020 Apple. All rights reserved.
//
import Eureka
import UIKit


class SelectAhap: UIViewController, TypedRowControllerType {
    
    //MARK: Public Properties
    // the row that push or presented this controller
    public var row: RowOf<Data>!
    
    // a closure to be called when the controller disappears
    public var onDismissCallback : ((UIViewController) -> ())?
    
    
    //MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
