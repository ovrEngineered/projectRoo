//
//  HapticPattern.swift
//  ovrHapticCollar
//
//  Created by Christopher Armenio on 12/11/20.
//  Copyright © 2020 Apple. All rights reserved.
//
import Foundation


class HapticPattern: Codable {
    
    //MARK: Private Constants
    private static let DEF_KEY_PATTERNS = "com.ovrengineered.ovrHapticCollar.patterns"
    
    
    //MARK: Public Types
    enum HapticType: String, CaseIterable {
        case Stereo = "Stereo"
        case Mono = "Mono"
    }
    
    
    //MARK: Public Properties
    var name: String?
    var leftChannelAhapData: Data?
    var rightChannelAhapData: Data?
    var monoAhapData: Data?
    
    var hapticType : HapticType {
        get {
            return ((self.leftChannelAhapData != nil) && (self.rightChannelAhapData != nil)) ? .Stereo : .Mono
        }
    }
    
    
    //MARK: Public Methods
    func save() {
        var patterns = HapticPattern.loadHapticPatternsFromNvStorage()
        patterns?.append(self)
        
        var patternDict = [String:HapticPattern]()
        for currPattern in patterns ?? [] {
            if( (currPattern.name == nil) || (currPattern.name?.count == 0) ) { continue }
            patternDict[currPattern.name!.lowercased()] = currPattern
        }
        UserDefaults.standard.setValue(patternDict, forKey: HapticPattern.DEF_KEY_PATTERNS)
    }
    
    
    func delete() {
        var patterns = HapticPattern.loadHapticPatternsFromNvStorage()
        patterns = patterns?.filter({ (currPattern) -> Bool in
            return currPattern.name!.lowercased() != self.name!.lowercased()
        })
        
        var patternDict = [String:HapticPattern]()
        for currPattern in patterns ?? [] {
            if( (currPattern.name == nil) || (currPattern.name?.count == 0) ) { continue }
            patternDict[currPattern.name!.lowercased()] = currPattern
        }
        UserDefaults.standard.setValue(patternDict, forKey: HapticPattern.DEF_KEY_PATTERNS)
    }
    
    
    //MARK: Public Static Methods
    static func loadHapticPatternsFromNvStorage() -> [HapticPattern]? {
        let patterns = (UserDefaults.standard.dictionary(forKey: HapticPattern.DEF_KEY_PATTERNS) as? [String:HapticPattern])?.values
        return patterns?.sorted(by: { (p1, p2) -> Bool in
            return p1.name!.lowercased() > p2.name!.lowercased()
        })
    }
}
