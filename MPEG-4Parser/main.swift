//
//  main.swift
//  MPEG4Parser
//
//  Created by USER on 24/04/2019.
//  Copyright © 2019 USER. All rights reserved.
//

import Foundation
import VideoToolbox

func dataWithHexString(hex: String) -> Data {
    var hex = hex
    var data = Data()
    while(hex.count > 0) {
        let subIndex = hex.index(hex.startIndex, offsetBy: 2)
        let c = String(hex[..<subIndex])
        hex = String(hex[subIndex...])
        var ch: UInt32 = 0
        Scanner(string: c).scanHexInt32(&ch)
        var char = UInt8(ch)
        data.append(&char, count: 1)
    }
    return data
}

extension Array where Element == UInt8 {
    mutating func flush() {
        self.removeAll()
    }
    
    var tohexNumbers: [String] {
        let hexNumbers = self.map {
            $0.toHexNumber
        }
        return hexNumbers
    }
}

extension UInt8 {
    var toHexNumber: String {
        return String(self, radix: 16, uppercase: false)
    }
}

extension InputStream {
    func readByHexNumber(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        
        return self.read(buffer, maxLength: len)
    }
}

extension Array where Element == String {
    var mergeToString: String {
        let mergedString = self.joined()
        return mergedString
    }
    
    var toDecimalValue: Int {
        guard let hexNumber = Int(self.mergeToString, radix: 16) else {
            return 0
        }
        return hexNumber
    }
}

var streamBuffer: [UInt8] = []

@discardableResult
func readStream(stream: InputStream?, amount: Int) -> Int {
    guard let stream = stream, stream.hasBytesAvailable else {
        return 0
    }
    
    var tempBuffer = [UInt8].init(repeating: 0,
                                  count: amount)
    let size = stream.read(&tempBuffer,
                            maxLength: amount)
    if size > 0 {
        streamBuffer.append(contentsOf: Array(tempBuffer[0..<size]))
        return size
    }
    
    return 0
}

let fileManager = FileManager()
let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
let dataPath = documentsDirectory.appendingPathComponent("firewerk.mp4")

let stream = InputStream(url: dataPath)
stream?.open()

let headerSize = readStream(stream: stream, amount: 4)
let hexNumbers = streamBuffer.tohexNumbers
streamBuffer.flush()
var infoSize = hexNumbers.toDecimalValue

while true {
    readStream(stream: stream, amount: (infoSize - headerSize))
    let header = String(data: dataWithHexString(hex: Array(streamBuffer[0..<4]).tohexNumbers.mergeToString), encoding: .utf8)
    streamBuffer.flush()
    print("-   -   -   -   -   -   -   -")
    print("\(header!), number of data \(infoSize)")
    readStream(stream: stream, amount: 4)
    
    if streamBuffer.isEmpty {
        break
    }
    
    infoSize = Array(streamBuffer[0..<4]).tohexNumbers.toDecimalValue
    streamBuffer.flush()
}
