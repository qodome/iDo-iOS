//
//  Copyright (c) 2014年 NY. All rights reserved.
//

class BaseDetail: UIViewController {
    // MARK: - 🍀 变量
    var data: AnyObject?
    var baseUrl: String = BASE_URL
    var keyPath: String?
    var errorKeyPath = "detail"
    var descriptor: RKResponseDescriptor!
    var errorDescriptor: RKResponseDescriptor!
    var pk = "1"
    // 手动设置
    var endpoint: String! // AF处理30x跳转会丢掉Authorization头，处理了加/，子类不要再加
    var mapping: RKObjectMapping!
    
    // MARK: - 💖 生命周期 (Lifecycle)
    override func viewDidLoad() {
        super.viewDidLoad()
        // 🔹 准备数据
        RKObjectManager.setSharedManager(RKObjectManager(baseURL: NSURL(string: baseUrl)))
        RKObjectManager.sharedManager().HTTPClient.setDefaultHeader("Authorization", value: "Token \(DEFAILT_TOKEN)")
        prepareForLoadData() // 准备数据
        descriptor = RKResponseDescriptor(mapping: mapping, method: .Any, pathPattern: nil, keyPath: keyPath, statusCodes: RKStatusCodeIndexSetForClass(UInt(RKStatusCodeClassSuccessful)))
        // 🔹 错误处理
        let errorMapping = RKObjectMapping(forClass: RKErrorMessage.self)
        errorMapping.addPropertyMapping(RKAttributeMapping(fromKeyPath: nil, toKeyPath: "errorMessage"))
        errorDescriptor = RKResponseDescriptor(mapping: errorMapping, method: .Any, pathPattern: nil, keyPath: errorKeyPath, statusCodes: RKStatusCodeIndexSetForClass(UInt(RKStatusCodeClassClientError)))
        // 🔹 绑定并加载数据
        RKObjectManager.sharedManager().addResponseDescriptorsFromArray([descriptor, errorDescriptor])
        loadData(nil)
    }
    
    // MARK: 💛 准备加载数据 🐤 子类必须调用
    func prepareForLoadData() {
        assert(false, "This method must be overriden")
    }
    
    // MARK: 💛 加载数据
    func loadData(sender: UIControl?) {
        RKObjectManager.sharedManager().addResponseDescriptorsFromArray([descriptor, errorDescriptor])
        RKObjectManager.sharedManager().getObjectsAtPath("\(endpoint)/\(pk)/", parameters: nil, success: { (operation: RKObjectRequestOperation!, result: RKMappingResult!) in
            self.data = result.array()[0]
            self.onLoadSuccess(self.data as NSObject)
            }, failure: { (operation: RKObjectRequestOperation!, error: NSError!) in
                Log("%@", operation.HTTPRequestOperation.request.allHTTPHeaderFields!)
                var code = 233
                let response = operation.HTTPRequestOperation.response
                if response != nil {
                    Log("%@", response.allHeaderFields)
                    code = response.statusCode
                }
                UIAlertView(title: "🐳 \(code)", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "OK").show()
        })
    }
    
    // MARK: 💛 获取数据成功
    func onLoadSuccess<E : NSObject>(entity: E) {
    }
}
