//
//  Copyright (c) 2014年 NY. All rights reserved.
//

let IDO1_OAD_SERVICE = "f000ffc0-0451-4000-b000-000000000000"
let IDO1_OAD_IDENTIFY = "f000ffc1-0451-4000-b000-000000000000"
let IDO1_OAD_BLOCK = "f000ffc2-0451-4000-b000-000000000000"

// https://developer.bluetooth.org/gatt/services/Pages/ServicesHome.aspx
// https://developer.bluetooth.org/gatt/characteristics/Pages/CharacteristicsHome.aspx
// https://developer.bluetooth.org/gatt/profiles/Pages/ProfilesHome.aspx // 定义了产品必须实现的规范
// http://developer.bluetooth.cn/libs/Cn/Specifi/GATT/2014/0117/54.html 中文
let BLE_BATTERY_SERVICE = "180F" // Battery Service
let BLE_BATTERY_LEVEL = "2A19" // Battery Level 必须 (Mandatory)

let BLE_CURRENT_TIME_SERVICE = "1805" // Current Time Service
let BLE_CURRENT_TIME = "2A2B" // Current Time 必须 (Mandatory)
let BLE_DATE_TIME = "2A08" // Date Time

let BLE_DEVICE_INFORMATION = "180A" // Device Information
let BLE_MODEL_NUMBER_STRING = "2A24" // Model Number String
let BLE_SERIAL_NUMBER_STRING = "2A25" // Serial Number
let BLE_FIRMWARE_REVISION_STRING = "2A26" // Firmware Revision String
let BLE_SOFTWARE_REVISION_STRING = "2A28" // Software Revision String
let BLE_MANUFACTURER_NAME_STRING = "2A29" // Manufacturer Name String

let BLE_HEALTH_THERMOMETER = "1809" // Health Thermometer
let BLE_TEMPERATURE_MEASUREMENT = "2A1C" // Temperature Measurement 必须 (Mandatory)
let BLE_INTERMEDIATE_TEMPERATURE = "2A1E" // Intermediate Temperature

// https://developer.bluetooth.org/gatt/profiles/Pages/ProfileViewer.aspx?u=org.bluetooth.profile.find_me.xml 防丢器的话必须要有的Service
let BLE_IMMEDIATE_ALERT = "1802" // Immediate Alert
let BLE_ALERT_LEVEL = "2A06" // Alert Level 必须 (Mandatory)
// https://developer.bluetooth.org/gatt/profiles/Pages/ProfileViewer.aspx?u=org.bluetooth.profile.proximity.xml 灯必须有的Service
// https://developer.bluetooth.org/gatt/profiles/Pages/ProfileViewer.aspx?u=org.bluetooth.profile.running_speed_and_cadence.xml 手环必须有的Service

/** 处理蓝牙传来的data */
func calculateTemperature(data: NSData) -> Double {
    var bytes = [UInt8](count: data.length, repeatedValue: 0)
    data.getBytes(&bytes, length: bytes.count)
    // TODO: 目前只处理长度为5的, 未来需要支持第三方设备可能不为5
    let exponent = Double(getInt8(bytes[4])) // 永远小于0
    let mantissa = Int32(getInt8(bytes[3])) << 16 | Int32(bytes[2]) << 8 | Int32(bytes[1])
    return Double(mantissa) * pow(10, exponent)
}

func transformTemperature(value: Double, fahrenheit: Bool) -> Double {
    // 这里进来的value需要是四舍五入并保留一位处理过的，也就是存入json的
    return fahrenheit ? round(320 + value * 18) * 0.1 : value
}

func getInt8(byte: UInt8) -> Int8 {
    return byte < 128 ? Int8(byte) : Int8(byte - 255 - 1) // -(255 - byte) - 1
}
