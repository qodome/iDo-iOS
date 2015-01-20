//
//  Copyright (c) 2015年 NY. All rights reserved.
//

class FirmwareDetail: TableDetail {
    
    var ring: M13ProgressViewPie!
    
    // MARK: - 🐤 继承 Taylor
    override func onPrepare() {
        super.onPrepare()
        title = LocalizedString("update")
        refreshMode = .WillAppear
        endpoint = getEndpoint("firmwares/ID14TB")
        ring = M13ProgressViewPie(frame: CGRectMake(view.frame.width / 2 - 25, view.frame.height / 2 - 25, 50, 50))
        ring.hidden = true
        view.addSubview(ring)
    }
    
    override func onCreateLoader() -> BaseLoader? {
        println(endpoint)
        return HttpLoader(endpoint: endpoint, type: Firmware.self)
    }
    
    override func onLoadSuccess<E : Firmware>(entity: E) {
        super.onLoadSuccess(entity)
        let remote = entity.revision as String
        let locale = "0.0.0(32B)"
        if remote != locale { // 如果不相同
            var downloadUrl = entity.downloadUrl as String
            if entity.modelNumber == "ID14TB" {
                let r = getSubstring(remote, start: "(", end: ")")
                let l = getSubstring(locale, start: "(", end: ")")
                if r.substringToIndex(advance(r.startIndex, 2)) == l.substringToIndex(advance(l.startIndex, 2)) {
                    return
                }
                let a = l.substringFromIndex(advance(r.endIndex, -1)) == "A" ? "B" : "A"
                let revenceA = (a == "A" ? "B" : "A")
                downloadUrl = downloadUrl.stringByReplacingOccurrencesOfString("\(revenceA).bin", withString: "\(a).bin")
            }
            // 开始下载
            let fileName = downloadUrl.lastPathComponent
            let basePath = paths[0].stringByAppendingPathComponent("\(entity.modelNumber)/\(fileName)")
            NSFileManager.defaultManager().removeItemAtPath(basePath, error: nil)
            let file = NSFileHandle(forUpdatingAtPath: basePath)
            if file != nil {
                let attributes = NSFileManager.defaultManager().attributesOfItemAtPath(basePath, error: nil)
                let filesize = (attributes! as NSDictionary).fileSize()
                if filesize != UInt64(entity.size.integerValue) {
                    NSFileManager.defaultManager().removeItemAtPath(basePath, error: nil) // 删除文件
                    download(downloadUrl, path: basePath)
                }
            } else {
                NSFileManager.defaultManager().createDirectoryAtPath(basePath.stringByDeletingLastPathComponent, withIntermediateDirectories: false, attributes: nil, error: nil) // 创建目录
                download(downloadUrl, path: basePath)
            }
        }
    }
    
    func getSubstring(string: String, start: String, end: String) -> String {
        let startRange = string.rangeOfString(start)
        let endRange = string.rangeOfString(end)
        if startRange != nil && endRange != nil {
            return string.substringWithRange(Range(start: startRange!.endIndex, end: endRange!.startIndex))
        }
        return ""
    }
    
    func download(url: String, path: String) {
        ring.performAction(M13ProgressViewActionNone, animated: false)
        ring.hidden = false
        let request = NSURLRequest(URL: NSURL(string: url)!)
        let operation = AFHTTPRequestOperation(request: request)
        operation.outputStream = NSOutputStream(toFileAtPath: path, append: false)
        operation.setCompletionBlockWithSuccess({ (operation, responseObject) in
            self.ring.performAction(M13ProgressViewActionSuccess, animated: true)
//            self.ring.hidden = true
            // TODO: 刷iDo
            }, failure: { (operation, error) in
                self.ring.performAction(M13ProgressViewActionFailure, animated: true)
        })
        operation.setDownloadProgressBlock({ (bytesRead, totalBytesRead, totalBytesExpectedToRead) in
            self.ring.setProgress(CGFloat(totalBytesRead / totalBytesExpectedToRead), animated: true)
        })
        operation.start()
    }
}
