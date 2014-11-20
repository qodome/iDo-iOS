//
//  Copyright (c) 2014年 NY. All rights reserved.
//

class RESTUICollectionViewController: BaseUICollectionViewController {
    // MARK: - 🍀 变量
    var refreshControl = UIRefreshControl()
    var baseUrl: String = BASE_URL
    var keyPath = "results"
    var errorKeyPath = "detail"
    var page = 1
    var page_size = 20
    var rootMapping: RKObjectMapping!
    var descriptor: RKResponseDescriptor!
    var errorDescriptor: RKResponseDescriptor!
    // 手动设置
    var endpoint: String! // AF处理30x跳转会丢掉Authorization头，处理了加/，子类不要再加
    var mapping: RKObjectMapping!
    var parameters = ["page": "1"]
    // 选中
    var selected: AnyObject!
    // 私有 (Privete)
    var count: NSNumber = 0 // 总数
    var next: String?
    var previous: String?
    
    // MARK: - 💖 生命周期 (Lifecycle)
    override func viewDidLoad() {
        super.viewDidLoad()
        // 🔹 设置下拉刷新
        refreshControl.addTarget(self, action: "loadData:", forControlEvents: .ValueChanged)
        collectionView.addSubview(refreshControl)
        collectionView.alwaysBounceVertical = true // 保证没有数据或小于屏幕时，也能下拉
        // 🔹 准备数据
        RKObjectManager.setSharedManager(RKObjectManager(baseURL: NSURL(string: baseUrl)))
        RKObjectManager.sharedManager().HTTPClient.setDefaultHeader("Authorization", value: "Token \(DEFAULT_TOKEN)")
        // 🔹 列表root
        rootMapping = RKObjectMapping(forClass: RESTList.self)
        rootMapping.addAttributeMappingsFromDictionary(RESTList.getMapping())
        prepareForLoadData() // 准备数据
        rootMapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: keyPath, toKeyPath: "results", withMapping: mapping)) // 级联
        // 🔹 错误处理
        let errorMapping = RKObjectMapping(forClass: RKErrorMessage.self)
        errorMapping.addPropertyMapping(RKAttributeMapping(fromKeyPath: nil, toKeyPath: "errorMessage"))
        // 🔹 绑定并加载数据
        descriptor = RKResponseDescriptor(mapping: rootMapping, method: .Any, pathPattern: nil, keyPath: nil, statusCodes: RKStatusCodeIndexSetForClass(UInt(RKStatusCodeClassSuccessful)))
        errorDescriptor = RKResponseDescriptor(mapping: errorMapping, method: .Any, pathPattern: nil, keyPath: errorKeyPath, statusCodes: RKStatusCodeIndexSetForClass(UInt(RKStatusCodeClassClientError)))
        RKObjectManager.sharedManager().addResponseDescriptorsFromArray([descriptor, errorDescriptor])
        loadData(refreshControl)
    }

    // MARK: 💛 准备加载数据 🐤 子类必须调用
    func prepareForLoadData() {
        assert(false, "This method must be overriden")
    }
    
    // MARK: 💛 加载数据
    func loadData(sender: UIControl?) {
        if sender == refreshControl {
            refreshControl.beginRefreshing()
            page = 1
        }
        parameters["page"] = String(page)
        parameters["page_size"] = String(page_size)
        RKObjectManager.sharedManager().addResponseDescriptorsFromArray([descriptor, errorDescriptor]) // 这句必须每次进来重载一次，否则切换页面会丢失内容
        RKObjectManager.sharedManager().getObjectsAtPath("\(endpoint)/", parameters: parameters, success: { (operation: RKObjectRequestOperation!, result: RKMappingResult!) in
            self.refreshControl.endRefreshing()
            let entity: RESTList = result.array()[0] as RESTList
            if self.keyPath == "results" { // 处理不同情况，如专题做根目录不返回count
                self.count = entity.count
                self.next = entity.next
                self.previous = entity.previous
            }
            if self.page <= 1 {
                self.data.removeAll(keepCapacity: true)
            }
            self.data += entity.results
            self.onLoadSuccess(entity)
            self.collectionView.reloadData() // 刷新视图
            }, failure: { (operation: RKObjectRequestOperation!, error: NSError!) in
                self.refreshControl.endRefreshing()
                Log("%@", operation.HTTPRequestOperation.request.allHTTPHeaderFields!)
                var code = 233
                let response = operation.HTTPRequestOperation.response
                if response != nil {
                    Log("%@", response.allHeaderFields)
                    code = response.statusCode
                }
                UIAlertView(title: "🐳 \(code) page \(self.page)", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "OK").show()
                if self.page > 1 {
                    self.page--
                }
        })
    }
    
    // MARK: 💛 获取数据成功
    func onLoadSuccess<E : NSObject>(entity: E) {
    }
    
    // MARK: - 💛 加载更多
    func loadMore(collectionView: UICollectionView, indexPath: NSIndexPath) {
        if next != nil && indexPath.row == collectionView.numberOfItemsInSection(indexPath.section) - 1 {
            page++
            loadData(nil)
        }
    }
    
    // MARK: - 💙 UICollectionViewDataSource
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        loadMore(collectionView, indexPath: indexPath) // 下一页
        return super.collectionView(collectionView, cellForItemAtIndexPath: indexPath)
    }
}
