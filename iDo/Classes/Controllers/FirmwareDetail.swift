//
//  Copyright (c) 2015年 NY. All rights reserved.
//

class FirmwareDetail: TableDetail {
    let UPDATE_ITEM = "download_and_install"
    
    var peripheral: CBPeripheral!
    var path: String!
    var oadThread: NSThread!
    
    var HUD: M13ProgressHUD!
    
    // MARK: - 🐤 继承 Taylor
    override func onPrepare() {
        super.onPrepare()
        title = LocalizedString("update")
        refreshMode = .WillAppear
        endpoint = getEndpoint("firmwares/\(peripheral.deviceInfo!.modelNumber!)")
        HUD = M13ProgressHUD(progressView: M13ProgressViewRing())
        HUD.progressViewSize = CGSizeMake(60, 60)
        HUD.animationPoint = CGPointMake(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2)
        HUD.hudBackgroundColor = UIColor.whiteColor()
        HUD.statusColor = UIColor.defaultColor()
        HUD.maskType = M13ProgressHUDMaskTypeSolidColor // MaskTypeIOS7Blur参数无效
        UIApplication.sharedApplication().delegate?.window!!.addSubview(HUD)
    }
    
    override func onCreateLoader() -> BaseLoader? {
        return HttpLoader(endpoint: endpoint, type: Firmware.self)
    }
    
    override func onLoadSuccess<E : Firmware>(entity: E) {
        let local = peripheral.deviceInfo!.firmwareRevision! // 如果数据格式不对下面会闪退
        //        let local = "0.0.0(35B)"
        if entity.modelNumber == "ID14TB" { // 注意: 以下基于服务器端永远只返回A.bin
            let remote: String = entity.revision
            let range = remote.rangeOfString("A)", options: .BackwardsSearch)
            if remote.substringToIndex(range!.startIndex) != local.substringToIndex(range!.startIndex) { // 比较去掉A)之后的版本号
                if local.rangeOfString("A)") != nil { // 如果本地为A去找B，为B无需处理
                    entity.downloadUrl = entity.downloadUrl.stringByReplacingOccurrencesOfString("A.bin", withString: "B.bin")
                    entity.revision = entity.revision.stringByReplacingOccurrencesOfString("A)", withString: "B)")
                }
            } else { // 这里如果不处理本地B版会一直发现更新
                entity.revision = local
            }
        }
        if entity.revision != local { // 如果版本号不同
            items = [[entity.revision], [UPDATE_ITEM]]
        } else {
            UIAlertView(title: "", message: LocalizedString("up_to_date"), delegate: nil, cancelButtonTitle: LocalizedString("ok")).show()
        }
        super.onLoadSuccess(entity)
    }
    
    override func getItemView<T : Firmware, C : UITableViewCell>(tableView: UITableView, indexPath: NSIndexPath, data: T?, item: String, cell: C) -> UITableViewCell {
        if indexPath.section == 0 {
            cell.detailTextLabel?.text = NSByteCountFormatter.stringFromByteCount(data!.size.longLongValue, countStyle: .Binary)
        } else if getItem(indexPath) == UPDATE_ITEM {
            cell.textLabel?.textColor = UIColor.defaultColor()
        }
        return cell
    }
    
    // MARK: - 💙 UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if getItem(indexPath) == UPDATE_ITEM {
            let entity = data as Firmware
            download(entity.downloadUrl, directory: PATH_DOCUMENTS.stringByAppendingPathComponent("\(entity.modelNumber)"), size: entity.size.integerValue)
        }
    }
    
    // MARK: - 💛 自定义方法 (Custom Method)
    func download(url: String, directory: String, size: NSNumber = 0) {
        path = directory.stringByAppendingPathComponent(url.lastPathComponent)
        NSFileManager.defaultManager().removeItemAtPath(path, error: nil)
        if NSFileHandle(forUpdatingAtPath: path) != nil && size.integerValue > 0 {
            let attributes = NSFileManager.defaultManager().attributesOfItemAtPath(path, error: nil)
            if attributes != nil && size != attributes![NSFileSize] as NSNumber { // 大小不一样
                NSFileManager.defaultManager().removeItemAtPath(path, error: nil) // 删除文件
                download(url, directory: directory, size: size)
            }
        } else {
            NSFileManager.defaultManager().createDirectoryAtPath(path.stringByDeletingLastPathComponent, withIntermediateDirectories: true, attributes: nil, error: nil) // 创建目录
            HUD.show(true)
            HUD.status = LocalizedString("download")
            let request = NSURLRequest(URL: NSURL(string: url)!)
            let operation = AFHTTPRequestOperation(request: request)
            operation.outputStream = NSOutputStream(toFileAtPath: path, append: false)
            operation.setCompletionBlockWithSuccess({ (operation, responseObject) in
                delay(0.5 + Double(self.HUD.animationDuration)) {
                    self.HUD.status = LocalizedString("install")
                    self.HUD.progressView.indeterminate = true
                    self.HUD.setProgress(0, animated: false)
                    self.oadThread = NSThread(target: self, selector: "OADDownload", object: nil)
                    self.oadThread.start()
                }
                }, failure: { (operation, error) in
                    delay(0.5 + Double(self.HUD.animationDuration)) {
                        self.HUD.performAction(M13ProgressViewActionFailure, animated: true)
                        delay(1 + Double(self.HUD.animationDuration)) {
                            self.HUD.hide(true)
                            self.HUD.performAction(M13ProgressViewActionNone, animated: false)
                        }
                    }
            })
            operation.setDownloadProgressBlock({ (bytesRead, totalBytesRead, totalBytesExpectedToRead) in
                self.HUD.setProgress(CGFloat(totalBytesRead / totalBytesExpectedToRead), animated: true)
            })
            operation.start()
        }
    }
    
    func OADDownload() { // TODO: 更新成功刷新或退出这个界面
        switch (data as Firmware).modelNumber {
        case "ID14TB":
            iDo1OADHandler.sharedManager.revision = (data as Firmware).revision
            iDo1OADHandler.sharedManager.update(peripheral, data: NSData.dataWithContentsOfMappedFile(path) as NSData, progress: HUD)
        default: break
        }
    }
}
