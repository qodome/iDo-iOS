//
//  Copyright (c) 2014年 NY. All rights reserved.
//

let APP_ID = "923307110" // "https://itunes.apple.com/cn/app/id923307110"
let APP_COLOR = 0xFF5A5F

let PRODUCTS = ["ID14TB" : "iDo"]

let BASE_URL = "http://qodome.com"
let API_VERSION = "api/v1"
let DEFAULT_TOKEN = ""

var token: String?

var low = 35.0
var high = 37.0
var lowAlert = false
var highAlert = true
var temperatureUnit = ""

func initSettings() {
    low = getDouble(R.Pref.LowTemperature.rawValue, defaultValue: 35)
    high = getDouble(R.Pref.HighTemperature.rawValue, defaultValue: 37)
    lowAlert = getBool(R.Pref.NotificationLow.rawValue)
    highAlert = getBool(R.Pref.NotificationHigh.rawValue, defaultValue: true)
    temperatureUnit = getPref(R.Pref.TemperatureUnit.rawValue, defaultValue: "℃")
}
