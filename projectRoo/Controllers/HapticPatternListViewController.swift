//
//  HapticPatternListViewController.swift
//  ovrHapticCollar
//
//  Created by Christopher Armenio on 12/11/20.
//  Copyright © 2020 Apple. All rights reserved.
//
import DZNEmptyDataSet
import GameController
import UIKit


class HapticPatternListViewController: UIViewController {

    //MARK: Private Constants
    private static let CID_HAPTIC_PATTERN = "hapticPatternTableViewCellIdentifier"
    
    
    //MARK: IBOutlets
    @IBOutlet weak var tableView: UITableView!
    
    
    //MARK: Private Properties
    private var hapticPatterns: [HapticPattern]?
    
    
    //MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.tableFooterView = UIView()
        
        HapticsManager.sharedInstance.delegate = self
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.reloadFromNvStorage()
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if( segue.destination is AddEditHapticPatternViewController ) {
            (segue.destination as! AddEditHapticPatternViewController).hapticPattern = (sender is HapticPattern) ?
                                                                                        (sender as! HapticPattern) :
                                                                                        self.hapticPatterns?[self.tableView.indexPathForSelectedRow!.row]
        }
    }
}


//MARK: - DZNEmptyDataSet
extension HapticPatternListViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        return (hapticPatterns?.count ?? 0) == 0
    }
    
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "No Haptic Patterns Found",
                                  attributes: [
                                      NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18.0),
                                      NSAttributedString.Key.foregroundColor: UIColor.label
                                  ])
    }
    
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "Tap the + button to create a pattern",
                                  attributes: [
                                      NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12.0),
                                      NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel
                                  ])
    }
}


//MARK: - HapticsManagerDelegate
extension HapticPatternListViewController: HapticsManagerDelegate {
    func didConnect(controller: GCController) {
    }
    
    
    func didDisconnectController() {
    }
}


//MARK: - UITableViewDataSource / UITableViewDelegate
extension HapticPatternListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HapticPatternListViewController.CID_HAPTIC_PATTERN, for: indexPath)
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
}


//MARK: - Private Methods
extension HapticPatternListViewController {
    private func reloadFromNvStorage() {
        self.hapticPatterns = HapticPattern.loadHapticPatternsFromNvStorage()
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}
