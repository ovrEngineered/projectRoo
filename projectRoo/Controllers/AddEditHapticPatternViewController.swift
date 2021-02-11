//
//  AddEditHapticPatternViewController.swift
//  ovrHapticCollar
//
//  Created by Christopher Armenio on 12/11/20.
//  Copyright © 2020 Apple. All rights reserved.
//
import Eureka
import UIKit


class AddEditHapticPatternViewController: FormViewController {

    //MARK: Public Properties
    var hapticPattern: HapticPattern?
    
    
    //MARK: Private Types
    enum Row : String, CaseIterable {
        case Name = "name"
        case AhapType = "type"
        case MonoAhapData = "monoAhapData"
        case LeftAhapData = "leftAhapData"
        case RightAhapData = "rightAhapData"
    }
    
    
    //MARK: Private Propeties
    private var hasChanges = false
    private var isFirstLoad = true
    
    
    //MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: "Back", style: .done, target: self, action: #selector(back(sender:)))
        self.navigationItem.leftBarButtonItem = newBackButton
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if( !self.isFirstLoad ) { return }
        self.isFirstLoad = false
        
        self.navigationItem.title = self.hapticPattern?.name ?? "Create Haptic Pattern"
        
        self.form +++ Section("Information")
            <<< NameRow(Row.Name.rawValue) { row in
                row.title = "Name"
                row.value = self.hapticPattern?.name
                row.placeholder = "<tap to enter name>"
                row.add(rule: RuleRequired(msg: "Name is required", id: nil))
            }.onChange({ (row) in
                self.hasChanges = true
            }).cellUpdate({ (cell, row) in
                cell.backgroundColor = row.isValid ? UIColor.clear : UIColor.systemPink
            })
        
            <<< ActionSheetRow<HapticPattern.HapticType>(Row.AhapType.rawValue) { row in
                row.title = "Haptic Type"
                row.value = self.hapticPattern?.hapticType ?? .Mono
                row.selectorTitle = "Pick a Haptic Type"
                row.options = HapticPattern.HapticType.allCases
                row.displayValueFor = { (hapticType: HapticPattern.HapticType?) in
                    return hapticType?.rawValue
                }
                row.add(rule: RuleRequired(msg: "Haptic Type is required", id: nil))
            }.onChange({ (row) in
                self.hasChanges = true
            }).cellUpdate({ (cell, row) in
                cell.backgroundColor = row.isValid ? UIColor.clear : UIColor.systemPink
            })
        
        self.form +++ Section("Channel Data")
            <<< PushRow<Data>(){ row in
                row.tag = Row.MonoAhapData.rawValue
                row.title = "Mono Ahap File"
                row.noValueDisplayText = "Tap To Specify"
//                row.presentationMode = PresentationMode.segueName(segueName: "sid_locationGroupToDistributorList", onDismiss: nil)
                row.hidden = Condition.function([Row.AhapType.rawValue], { (form) -> Bool in
                    return ((form.rowBy(tag: Row.AhapType.rawValue) as! ActionSheetRow<HapticPattern.HapticType>).value != .Mono)
                })
                row.add(rule: RuleClosure(closure: { (_) -> ValidationError? in
                    return (((self.form.rowBy(tag: Row.AhapType.rawValue) as! ActionSheetRow<HapticPattern.HapticType>).value == .Mono) && (row.value == nil)) ?
                            ValidationError(msg: "Missing Ahap File") : nil
                }))
            }.cellUpdate({ (cell, row) in
                cell.backgroundColor = row.isValid ? UIColor.clear : UIColor.systemPink
            })
        
            <<< PushRow<Data>(){ row in
                row.tag = Row.LeftAhapData.rawValue
                row.title = "Left Ahap File"
                row.noValueDisplayText = "Tap To Specify"
//                row.presentationMode = PresentationMode.segueName(segueName: "sid_locationGroupToDistributorList", onDismiss: nil)
                row.hidden = Condition.function([Row.AhapType.rawValue], { (form) -> Bool in
                    return ((form.rowBy(tag: Row.AhapType.rawValue) as! ActionSheetRow<HapticPattern.HapticType>).value != .Stereo)
                })
                row.add(rule: RuleClosure(closure: { (_) -> ValidationError? in
                    return (((self.form.rowBy(tag: Row.AhapType.rawValue) as! ActionSheetRow<HapticPattern.HapticType>).value == .Stereo) && (row.value == nil)) ?
                            ValidationError(msg: "Missing Ahap File") : nil
                }))
            }.cellUpdate({ (cell, row) in
                cell.backgroundColor = row.isValid ? UIColor.clear : UIColor.systemPink
            })
        
            <<< PushRow<Data>(){ row in
                row.tag = Row.RightAhapData.rawValue
                row.title = "Right Ahap File"
                row.noValueDisplayText = "Tap To Specify"
//                row.presentationMode = PresentationMode.segueName(segueName: "sid_locationGroupToDistributorList", onDismiss: nil)
                row.hidden = Condition.function([Row.AhapType.rawValue], { (form) -> Bool in
                    return ((form.rowBy(tag: Row.AhapType.rawValue) as! ActionSheetRow<HapticPattern.HapticType>).value != .Stereo)
                })
                row.add(rule: RuleClosure(closure: { (_) -> ValidationError? in
                    return (((self.form.rowBy(tag: Row.AhapType.rawValue) as! ActionSheetRow<HapticPattern.HapticType>).value == .Stereo) && (row.value == nil)) ?
                            ValidationError(msg: "Missing Ahap File") : nil
                }))
            }.cellUpdate({ (cell, row) in
                cell.backgroundColor = row.isValid ? UIColor.clear : UIColor.systemPink
            })
        
        self.form +++ Section()
            <<< ButtonRow() { row in
                row.title = "Save Pattern"
            }.onCellSelection({ (cell, row) in
                let validationErrors = self.form.validate()
                self.tableView.reloadData()
                if( validationErrors.count > 0 ) {
                    self.showValidationError(msgIn: validationErrors.first?.msg ?? "???")
                    return
                }
                // if we made it here, we're good to save
                self.saveCurrentPattern()
            })
    }
}


//MARK: - IBActions
extension AddEditHapticPatternViewController {
    @objc func back(sender: UIBarButtonItem) {
        if( self.hasChanges == true ) {
            let alert = UIAlertController(title: "Unsaved Changes", message: "This will discard your changes. Are you sure you wish to continue?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Stay", style: .cancel))
            alert.addAction(UIAlertAction(title: "Discard", style: .destructive){ _ -> Void in
                self.navigationController?.popViewController(animated: true)
            })
            self.present(alert, animated: true, completion:nil)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
}


//MARK: - Private Methods
extension AddEditHapticPatternViewController {
    private func showValidationError(msgIn: String) {
        let alert = UIAlertController(title: "Validation Error", message: msgIn, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Continue", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    
    private func saveCurrentPattern() {
        let newPattern = HapticPattern()
        newPattern.name = (self.form.rowBy(tag: Row.Name.rawValue) as! NameRow).value
        if( (self.form.rowBy(tag: Row.AhapType.rawValue) as! ActionSheetRow<HapticPattern.HapticType>).value == .Stereo ) {
            newPattern.leftChannelAhapData = (self.form.rowBy(tag: Row.LeftAhapData.rawValue) as! PushRow<Data>).value
            newPattern.rightChannelAhapData = (self.form.rowBy(tag: Row.RightAhapData.rawValue) as! PushRow<Data>).value
        } else {
            newPattern.monoAhapData = (self.form.rowBy(tag: Row.MonoAhapData.rawValue) as! PushRow<Data>).value
        }
        
        newPattern.save()
    }
}
