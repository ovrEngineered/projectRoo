//
//  OneDriveHelper.swift
//  ovrHapticCollar
//
//  Created by Christopher Armenio on 12/13/20.
//  Copyright © 2020 Apple. All rights reserved.
//
import Foundation
import MSAL
import MSGraphClientSDK
import MSGraphClientModels


class OneDriveHelper: NSObject {
    
    // MARK: Private Contants
    private static let ERROR_NO_CLIENT = NSError(domain: "io.ovrenginered", code: -1, userInfo:nil)
    
    
    // MARK: Public Types
    class File {
        let name : String
        let id: String
        
        init(nameIn: String, idIn: String) {
            self.name = nameIn
            self.id = idIn
        }
    }
    
    class Folder {
        let name : String
        let id : String?
        var folders = [Folder]()
        var files = [File]()
        var error : Error?
        
        init() {
            self.name = "/"
            self.id = nil
        }
        
        init(nameIn: String, idIn: String) {
            self.name = nameIn
            self.id = idIn
        }

        fileprivate func addFolder(folderIn: Folder) {
            self.folders.append(folderIn)
        }
        
        fileprivate func addFile(fileIn: File) {
            self.files.append(fileIn)
        }
    }
    
    
    //MARK: Public Static Properties
    static let sharedInstance = OneDriveHelper()
    
    
    //MARK: Private Properties
    private var publicClient : MSALPublicClientApplication?
    private var graphClient : MSHTTPClient?
    private var accessToken : String?
    
    
    //MARK: Public Methods
    public func authenticate(parentVcIn: UIViewController, compBlock: ((String?, Error?) -> Void)?) {
        // try silently first
        self.getTokenSilently { (emailAddressIn, errorIn) in
            if( errorIn == nil ) {
                if( compBlock != nil ) {
                    compBlock!(emailAddressIn, nil)
                }
                return
            }
            // if we made it here, silent mode didn't work...try interactive
            
            let webParameters = MSALWebviewParameters(parentViewController: parentVcIn)
            let interactiveParameters = MSALInteractiveTokenParameters(scopes: ["Files.ReadWrite"], webviewParameters: webParameters)
            interactiveParameters.promptType = .login

            // Call acquireToken to open a browser so the user can sign in
            self.publicClient?.acquireToken(with: interactiveParameters, completionBlock: { (result, error) in
                if( error != nil ) {
                    if( compBlock != nil ) {
                        compBlock!(nil, error)
                    }
                    return
                }
                
                // check result
                if( result == nil ) {
                    if( compBlock != nil ) {
                        let details = [NSDebugDescriptionErrorKey: "No result was returned"]
                        compBlock!(nil, NSError(domain: "AuthenticationManager", code: 0, userInfo: details))
                    }
                    return
                }
                
                self.accessToken = result?.accessToken
                if( compBlock != nil ) {
                    compBlock!(result?.account.username, nil)
                }
            })
        }
    }
    
    
    public func listRootFolderContents(compBlock: ((Folder?, Error?) -> Void)?) {
        // GET /me
        let meUrlString = String(format: "%@/me/drive/root/children", MSGraphBaseURL)
        let meUrl = URL(string: meUrlString)
        let meRequest = NSMutableURLRequest(url: meUrl!)
        
        let meDataTask = MSURLSessionDataTask(request: meRequest, client: self.graphClient) { (data, response, error) in
            if( error != nil ) {
                if( compBlock != nil ) {
                    compBlock!(nil, error)
                }
                return
            }
            
            do {
                let rootItems = try MSCollection(data: data)
                
                let retVal = Folder()
                let grp = DispatchGroup()
                for case let currItem_dict as [AnyHashable : Any] in rootItems.value {
                    let currItem = MSGraphDriveItem(dictionary: currItem_dict)
                    if( currItem?.folder != nil ) {
                        let newFolder = Folder(nameIn: currItem?.name ?? "???", idIn: currItem!.entityId)
                        retVal.addFolder(folderIn: newFolder)
                        self.enumerateAndAddChildrenToFolder(folderIn: newFolder, withDispatchGroup: grp)
                    } else if( currItem?.file != nil ) {
                        let newFile = File(nameIn: currItem?.name ?? "???", idIn: currItem!.entityId)
                        retVal.addFile(fileIn: newFile)
                    }
                }
                
                grp.notify(queue: DispatchQueue.main) {
                    //TODO: recurse through all folders and check for errors
                    if( compBlock != nil ) {
                        compBlock!(retVal, nil)
                    }
                }
            } catch {
                if( compBlock != nil ) {
                    compBlock!(nil, error)
                }
                return
            }
        }
        
        meDataTask?.execute()
    }
    
    
    private override init() {
        super.init()
        
        // Create the MSAL client
        self.publicClient = try? MSALPublicClientApplication(clientId: "d5716605-f1c8-43ae-89d4-c1c489720232")
        self.graphClient = MSClientFactory.createHTTPClient(with: self)
    }
}


//MARK: - MSAuthenticationProvider
extension OneDriveHelper: MSAuthenticationProvider {
    func getAccessToken(for authProviderOptions: MSAuthenticationProviderOptions!, andCompletion completion: ((String?, Error?) -> Void)!) {
        self.getTokenSilently { (emailADdressIn, errorIn) in
            completion(self.accessToken, errorIn)
        }
    }
}


//MARK: - Private Methods
extension OneDriveHelper {
    private func getTokenSilently(compBlock: ((String?, Error?) -> Void)?) {
        // Check if there is an account in the cache
        let account = try? self.publicClient?.allAccounts().first
        
        if( account == nil ) {
            if( compBlock != nil) {
                var details = [String : String]()
                details[NSDebugDescriptionErrorKey] = "Could not retrieve account from cache"
                compBlock!(nil, NSError(domain: "AuthenicationManager", code: 0, userInfo: details))
            }
            return
        }
        
        let silentParameters = MSALSilentTokenParameters(scopes: ["Files.ReadWrite"], account: account!)
        
        // Attempt to get token silently
        self.publicClient?.acquireTokenSilent(with: silentParameters, completionBlock: { (result, error) in
             // Check error
             if( error != nil)
             {
                if( compBlock != nil) {
                    compBlock!(nil, error);
                }
                return;
             }
             
             // Check result
             if( result == nil ) {
                if( compBlock != nil) {
                    var details = [String : String]()
                    details[NSDebugDescriptionErrorKey] = "No result was returned"
                    compBlock!(nil, NSError(domain: "AuthenicationManager", code: 0, userInfo: details))
                }
                return;
             }
             
            self.accessToken = result?.accessToken
            if( compBlock != nil ) {
                compBlock!(result?.account.username, nil)
            }
        })
    }
    
    
    private func enumerateAndAddChildrenToFolder(folderIn: Folder, withDispatchGroup: DispatchGroup) {
        withDispatchGroup.enter()
        
        // GET /me
        let meUrlString = String(format:"%@/me/drive/items/%@/children", MSGraphBaseURL, folderIn.id!)
        let meUrl = URL(string: meUrlString)
        let meRequest = NSMutableURLRequest(url: meUrl!)
        
        let meDataTask = MSURLSessionDataTask(request: meRequest, client: self.graphClient) { (data, response, error) in
            defer {
                withDispatchGroup.leave()
            }
            
            if( error != nil ) {
                folderIn.error = error
                return
            }
            
            do {
                let rootItems = try MSCollection(data: data)
                
                let grp = DispatchGroup()
                for case let currItem_dict as [AnyHashable : Any] in rootItems.value {
                    let currItem = MSGraphDriveItem(dictionary: currItem_dict)
                    if( currItem?.folder != nil ) {
                        let newFolder = Folder(nameIn: currItem?.name ?? "???", idIn: currItem!.entityId)
                        folderIn.addFolder(folderIn: newFolder)
                        self.enumerateAndAddChildrenToFolder(folderIn: newFolder, withDispatchGroup: grp)
                    } else if( currItem?.file != nil ) {
                        let newFile = File(nameIn: currItem?.name ?? "???", idIn: currItem!.entityId)
                        folderIn.addFile(fileIn: newFile)
                    }
                }
            } catch {
                folderIn.error = error
                return
            }
        }
        
        meDataTask?.execute()
    }
}
