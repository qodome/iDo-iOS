//
//  Copyright (c) 2014年 NY. All rights reserved.
//

let BLE_UUID_DATE = "1805" // Current Time
let BLE_UUID_DATE_TIME_CHAR = "2A08"     /**< Date Time characteristic UUID. */

let BLE_UUID_INFO = "180A"
let BLE_UUID_FIRMWARE_REVISION_STRING_CHAR = "2A26" /**< Firmware Revision String characteristic UUID. */
let BLE_UUID_MODEL_NUMBER_STRING_CHAR = "2A24" /**< Model Number String characteristic UUID. */
let BLE_UUID_MANUFACTURER_NAME_STRING_CHAR = "2A29" /**< Manufacturer Name String characteristic UUID. */

let kServiceUUID = "1809" // Health Thermometer
let BLE_UUID_TEMPERATURE_MEASUREMENT = "2A1C" // Temperature Measurement
let kCharacteristicUUID = "2A1E"

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
