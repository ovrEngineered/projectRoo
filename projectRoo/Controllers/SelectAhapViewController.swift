//
//  SelectAhapViewController.swift
//  ovrHapticCollar
//
//  Created by Christopher Armenio on 12/11/20.
//  Copyright © 2020 Apple. All rights reserved.
//
import DZNEmptyDataSet
import Eureka
import UIKit


class SelectAhapViewController: UIViewController, TypedRowControllerType {
    
    //MARK: Private Constants
    private static let CID_FOLDER = "cid_folder"
    private static let CID_FILE = "cid_file"
    
    
    //MARK: Public Properties
    // the row that push or presented this controller
    public var row: RowOf<Data>!
    
    // a closure to be called when the controller disappears
    public var onDismissCallback : ((UIViewController) -> ())?
    
    
    //MARK: IBOutlets
    @IBOutlet weak var tableView: UITableView!
    
    
    //MARK: Private Properties
    private var rootFolder : OneDriveHelper.Folder?
    
    
    //MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.tableFooterView = UIView()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.loadFromOneDrive()
    }
}
    

//MARK: - DZNEmptyDataSet
extension SelectAhapViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        return (self.rootFolder == nil)
    }
    
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "No OneDrive Files Found",
                                  attributes: [
                                      NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18.0),
                                      NSAttributedString.Key.foregroundColor: UIColor.label
                                  ])
    }
    
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "Ensure you've logged in and try again",
                                  attributes: [
                                      NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12.0),
                                      NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel
                                  ])
    }
}


//MARK: - UITableViewDataSource / UITableViewDelegate
extension SelectAhapViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (self.rootFolder != nil) ?
                ((self.rootFolder?.folders.count ?? 0) + (self.rootFolder?.files.count ?? 0)) :
                0
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        if( indexPath.row < (self.rootFolder?.folders.count ?? 0) ) {
            cell = tableView.dequeueReusableCell(withIdentifier: SelectAhapViewController.CID_FOLDER, for: indexPath)
            cell.textLabel?.text = self.rootFolder?.folders[indexPath.row].name
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: SelectAhapViewController.CID_FILE, for: indexPath)
            cell.textLabel?.text = self.rootFolder?.files[indexPath.row - (self.rootFolder?.folders.count ?? 0)].name
        }
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
}
    
  
//MARK: - Private Methods
extension SelectAhapViewController {
    private func loadFromOneDrive() {
        OneDriveHelper.sharedInstance.authenticate(parentVcIn: self) { (userEmailAddress, error) in
            OneDriveHelper.sharedInstance.listRootFolderContents { (rootfolder, error) in
                //TODO: use breakwall empty data set
                //TODO: handle errors
                //TODO: show email address somewhere
                //TODO: add logout button
                
                self.rootFolder = rootfolder
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
    }
}
