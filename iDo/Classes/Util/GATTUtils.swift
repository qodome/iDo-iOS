//
//  Copyright (c) 2014年 NY. All rights reserved.
//

/** 处理蓝牙传来的data */
func calculateTemperature(data: NSData) -> Float {
    var bytes = [UInt8](count: 5, repeatedValue: 0)
    data.getBytes(&bytes, length: 5)
    let exponent = Float(-(255 - bytes[4]) - 1) // 我自己都忘了为什么这么写，总之很对就是了
    let mantissa = Int32(bytes[3]) << 16 | Int32(bytes[2]) << 8 | Int32(bytes[1])
    return Float(mantissa) * pow(10.0, exponent)
}

func calculateAdvTemperature(data: NSData) -> Float {
    var bytes = [UInt8](count: 4, repeatedValue: 0)
    data.getBytes(&bytes, length: 4)
    let exponent = Float(-(255 - bytes[3]) - 1) // 我自己都忘了为什么这么写，总之很对就是了
    let mantissa = Int32(bytes[2]) << 16 | Int32(bytes[1]) << 8 | Int32(bytes[0])
    return Float(mantissa) * pow(10.0, exponent)
}
