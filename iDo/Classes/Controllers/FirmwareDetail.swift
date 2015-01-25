//
//  Copyright (c) 2015年 NY. All rights reserved.
//

class FirmwareDetail: TableDetail {
    let UPDATE_ITEM = "download_and_install"
    
    var progress: M13ProgressViewPie!
    var peripheral: CBPeripheral!
    var path: String!
    var oadThread: NSThread!
    
    // MARK: - 🐤 继承 Taylor
    override func onPrepare() {
        super.onPrepare()
        title = LocalizedString("update")
        refreshMode = .WillAppear
        endpoint = getEndpoint("firmwares/ID14TB")
        progress = M13ProgressViewPie(frame: CGRectMake(view.frame.width / 2 - 13, view.frame.height / 2 - 13, 26, 26))
        progress.hidden = true
        view.addSubview(progress)
    }
    
    override func onCreateLoader() -> BaseLoader? {
        return HttpLoader(endpoint: endpoint, type: Firmware.self)
    }
    
    override func onLoadSuccess<E : Firmware>(entity: E) {
        let local = peripheral.deviceInfo?.firmwareRevision != nil ? peripheral.deviceInfo!.firmwareRevision : ""
//        let local = "1.0.0(33B)"
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
        }
        if getItem(indexPath) == UPDATE_ITEM {
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
            progress.performAction(M13ProgressViewActionNone, animated: false)
            progress.hidden = false
            let request = NSURLRequest(URL: NSURL(string: url)!)
            let operation = AFHTTPRequestOperation(request: request)
            operation.outputStream = NSOutputStream(toFileAtPath: path, append: false)
            operation.setCompletionBlockWithSuccess({ (operation, responseObject) in
                self.progress.performAction(M13ProgressViewActionSuccess, animated: true)
                self.oadThread = NSThread(target: self, selector: "OADDownload", object: nil)
                self.oadThread.start()
                }, failure: { (operation, error) in
                    self.progress.performAction(M13ProgressViewActionFailure, animated: true)
            })
            operation.setDownloadProgressBlock({ (bytesRead, totalBytesRead, totalBytesExpectedToRead) in
                self.progress.setProgress(CGFloat(totalBytesRead / totalBytesExpectedToRead), animated: true)
            })
            operation.start()
        }
    }
    
    func OADDownload() {
        switch (data as Firmware).modelNumber {
        case "ID14TB":
            progress.performAction(M13ProgressViewActionNone, animated: true)
            progress.hidden = false
            iDo1OADHandler.sharedManager.revision = (data as Firmware).revision
            iDo1OADHandler.sharedManager.update(peripheral, data: NSData.dataWithContentsOfMappedFile(path) as NSData, progress: progress)
        default: break
        }
    }
}
