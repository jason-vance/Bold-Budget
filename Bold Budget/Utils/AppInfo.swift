//
//  AppInfo.swift
//  Bold Budget
//
//  Created by Jason Vance on 12/17/24.
//

import Foundation

public enum AppInfo {
    
    public static var appName: String {
        Bundle.main.infoDictionary?["CFBundleName"] as! String
    }
    
    public static var versionString: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
    }
    
    public static var buildNumberString: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as! String
    }
}
