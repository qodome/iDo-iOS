//
//  Copyright (c) 2015年 NY. All rights reserved.
//

import ObjectiveC

private var info: DeviceInfo?

extension CBPeripheral {
    
    var deviceInfo: DeviceInfo? {
        get {
            return objc_getAssociatedObject(self, &info) as? DeviceInfo
        }
        set(newValue) {
            objc_setAssociatedObject(self, &info, newValue, UInt(OBJC_ASSOCIATION_RETAIN))
        }
    }
}
