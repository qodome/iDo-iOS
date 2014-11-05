//
//  Copyright (c) 2014年 NY. All rights reserved.
//

/** 处理蓝牙传来的data */
func calculateTemperature(data: NSData) -> Float {
    println("bytes--\(data.length)")
    var bytes = [UInt8](count: 5, repeatedValue: 0)
    data.getBytes(&bytes, length:5)
    var byte0 = bytes[0]
    println("byte0:\(bytes[0])")
    var exponent = bytes[4] // -4
    var fuzhiExponent = Float(-(255 - exponent)-1) //?
    var b3 = Int32(bytes[3])
    var mantissa = ( Int32(bytes[3]) << 16) | (Int32(bytes[2]) << 8) | Int32(bytes[1])
    println("mantissa--\(mantissa)")
    let temperature = Float (mantissa) * Float(pow(10.0, fuzhiExponent))
    return temperature
}
