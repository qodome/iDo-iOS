//
//  Copyright (c) 2015年 NY. All rights reserved.
//

class R {
    enum Pref: String {
        case LowTemperature = "low_temperature"
        case HighTemperature = "high_temperature"
        case NotificationLow = "notification_low"
        case NotificationHigh = "notification_high"
        case TemperatureUnit = "temperature_unit"
        case Review = "review"
        case Developer = "developer"
    }
    
    enum Color: Int {
        case iDoRed = 0xE24424
        case iDoOranges = 0xFFBB1F
        case iDoGreen = 0x17A865
        case iDoBlue = 0x2897C3
        case iDoPurple = 0xAA66CC
    }
}
