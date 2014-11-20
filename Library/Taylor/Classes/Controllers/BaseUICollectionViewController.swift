//
//  Copyright (c) 2014年 NY. All rights reserved.
//

class BaseUICollectionViewController: UICollectionViewController {
    
    var data: [AnyObject] = []
    var cellId: String = "list_cell"
    
    // MARK: - 💖 生命周期 (Lifecycle)
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.backgroundColor = UIColor.whiteColor()
    }
    
    // MARK: - 💛 绘制单元项 🐤 子类必须调用
    func getItemView<T : NSObject, C : UICollectionViewCell>(collectionView: UICollectionView, indexPath: NSIndexPath, item: T, cell: C) -> UICollectionViewCell {
        assert(false, "This method must be overriden")
        //        return cell
    }
    
    // MARK: - 💙 UICollectionViewDataSource
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count // 为了下拉刷新的添加逻辑，默认组数为1
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var item = data[indexPath.row] as NSObject
        var cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellId, forIndexPath: indexPath) as UICollectionViewCell
        return getItemView(collectionView, indexPath: indexPath, item: item, cell: cell)
    }
    
    // MARK: - 💙 场景切换 (Segue)
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        (segue.destinationViewController as UIViewController).hidesBottomBarWhenPushed = true
    }
}
