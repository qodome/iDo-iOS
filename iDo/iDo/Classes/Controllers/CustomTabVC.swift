//
//  CustomTabVC.swift
//  Olive-ios
//
//  Created by billsong on 14-9-28.
//  Copyright (c) 2014年 hongDing. All rights reserved.
//

import UIKit

class CustomTabVC: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        //println("VC:\(viewControllers?.description)")
        var measureNVC = viewControllers![0] as UINavigationController
        measureNVC.tabBarItem.title = NSLocalizedString("measure", tableName: "Localization", bundle: NSBundle.mainBundle(), value: "", comment: "")
       var settingNVC = viewControllers![1] as UINavigationController
        settingNVC.tabBarItem.title = NSLocalizedString("setting", tableName: "Localization", bundle: NSBundle.mainBundle(), value: "", comment: "")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
