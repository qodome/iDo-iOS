//
//  Copyright (c) 2015年 NY. All rights reserved.
//

class FirmwareDetail: TableDetail {
    
    var progress: M13ProgressViewPie!
    
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
        super.onLoadSuccess(entity)
        let remote = String(entity.revision)
        let local = "0.0.0(32B)"
        if remote != local { // 如果版本号不同
            var url = String(entity.downloadUrl)
            // 以下基于服务器端永远只返回A.bin
            let range = remote.rangeOfString("A)", options: .BackwardsSearch)
            if entity.modelNumber == "ID14TB" && remote.substringToIndex(range!.startIndex) != local.substringToIndex(range!.startIndex) { // 比较去掉A)之后的版本号
                if local.substringWithRange(Range(start: range!.startIndex, end: advance(range!.startIndex, 1))) == "A" { // 如果本地为A去找B，为B无需处理
                    url = url.stringByReplacingOccurrencesOfString("A.bin", withString: "B.bin")
                }
            }
            download(url, directory: PATH_DOCUMENT.stringByAppendingPathComponent("\(entity.modelNumber)"), size: entity.size.integerValue)
        }
    }
    
    // MARK: - 💛 自定义方法 (Custom Method)
    func download(url: String, directory: String, size: NSNumber = 0) {
        let path = directory.stringByAppendingPathComponent(url.lastPathComponent)
        NSFileManager.defaultManager().removeItemAtPath(path, error: nil)
        if NSFileHandle(forUpdatingAtPath: path) != nil && size.integerValue > 0 {
            let attributes = NSFileManager.defaultManager().attributesOfItemAtPath(path, error: nil)
            if attributes != nil && size != attributes![NSFileSize] as NSNumber {
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
                //            self.progress.hidden = true
                // TODO: 刷iDo
                }, failure: { (operation, error) in
                    self.progress.performAction(M13ProgressViewActionFailure, animated: true)
            })
            operation.setDownloadProgressBlock({ (bytesRead, totalBytesRead, totalBytesExpectedToRead) in
                self.progress.setProgress(CGFloat(totalBytesRead / totalBytesExpectedToRead), animated: true)
            })
            operation.start()
        }
    }
}
