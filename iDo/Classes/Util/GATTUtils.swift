//
//  Copyright (c) 2014年 NY. All rights reserved.
//

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
let BLE_FIRMWARE_REVISION_STRING = "2A26" // Firmware Revision String
let BLE_MANUFACTURER_NAME_STRING = "2A29" // Manufacturer Name String
let BLE_MODEL_NUMBER_STRING = "2A24" // Model Number String

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
    var bytes = [UInt8](count: 5, repeatedValue: 0)
    data.getBytes(&bytes, length: 5)
    let exponent = Double(-(255 - bytes[4]) - 1) // 我自己都忘了为什么这么写，总之很对就是了
    let mantissa = Int32(bytes[3]) << 16 | Int32(bytes[2]) << 8 | Int32(bytes[1])
    return Double(mantissa) * pow(10.0, exponent)
}

func calculateAdvTemperature(data: NSData) -> Double {
    var bytes = [UInt8](count: 4, repeatedValue: 0)
    data.getBytes(&bytes, length: 4)
    let exponent = Double(-(255 - bytes[3]) - 1) // 我自己都忘了为什么这么写，总之很对就是了
    let mantissa = Int32(bytes[2]) << 16 | Int32(bytes[1]) << 8 | Int32(bytes[0])
    return Double(mantissa) * pow(10.0, exponent)
}

func transformTemperature(value: Double) -> Double {
    return Double(32) + value * 1.8
}
