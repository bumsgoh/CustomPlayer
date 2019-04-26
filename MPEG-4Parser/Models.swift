//
//  Models.swift
//  MPEG-4Parser
//
//  Created by USER on 26/04/2019.
//  Copyright © 2019 bumslap. All rights reserved.
//

import Foundation



class BigBox: Container {
    
    var type: ContainerType
    var size: Int
    var data: [UInt8] = []
    var buffer: [UInt8] = []
    var offset: Int = 0
    var children: [Container]?
    
    @discardableResult
    private func readDataStream(buffer: inout [UInt8], amount: Int) -> Int {
        guard !data.isEmpty, amount > 0, offset < data.count else {
            return 0
        }
        
        let readData = Array(data[offset..<offset + amount])
        let size = readData.count
        buffer = readData
        offset += amount
        if size > 0 {
            return size
        }
        return 0
    }
    
    init(type: ContainerType, size: Int) {
        self.type = type
        self.size = size
    }
    
    func parse() {
        let containerPool = ContainerPool()
        let headerSize = readDataStream(buffer: &buffer, amount: 4)
        //readStream(stream: fileContents, amount: 4)
        let hexNumbers = buffer.tohexNumbers
        buffer.flush()
        var infoSize = hexNumbers.toDecimalValue
        
        if headerSize > 0 {
            self.children = []
        }
        
        while true {
            var container: Container?
            readDataStream(buffer: &buffer, amount: infoSize - headerSize)
            guard let containerType =
                String(data: Array(buffer[0..<4])
                .tohexNumbers
                .mergeToString
                .convertHexStringToData,
                       encoding: .utf8) else {
                                                return
            }
            let dataFromBuffer = Array(buffer[4...])
            buffer.flush()
            
            do {
                let typeOfContainer = try containerPool.pullOutContainer(with: containerType)
                
                if typeOfContainer.isParent {
                    container = BigBox(type: typeOfContainer, size: infoSize)
                    
                } else {
                    container = SmallBox(type: typeOfContainer, size: infoSize)
                }
                container?.data = dataFromBuffer
            } catch {
                assertionFailure("initialization failed")
                return
            }
            guard let productedContainer = container else {
                assertionFailure("no container")
                return
            }
            
            children?.append(productedContainer)
            readDataStream(buffer: &buffer, amount: 4)
            //readStream(stream: stream, amount: 4)
            
            if buffer.isEmpty {
                break
            }
            infoSize = Array(buffer[0..<4]).tohexNumbers.toDecimalValue
            buffer.flush()
            
            
        }
        print("big parsing..")
        children?.forEach {
            $0.parse()
        }
    }
}

class SmallBox: Container {
    
    var type: ContainerType
    var size: Int
    var data: [UInt8] = []
    
    init(type: ContainerType, size: Int) {
        self.type = type
        self.size = size
    }
    
    func parse() {
    }
}

enum ContainerType: String, CaseIterable {
    case root
    case ftyp
    case free
    case mdat
    case moov
    case mvhd
    case trak
    case tkhd
    case edts
    case mdia
    case mdhd
    case hdlr
    case minf
    case vmhd
    case smhd
    case dinf
    case dref
    case stbl
    case co64
    case ctts
    case stsd
    case stts
    case stss
    case stsc
    case stsz
    case stco
    case udta
    case meta
}

extension ContainerType {
    var isParent: Bool {
        if self == .moov || self == .trak || self == .mdia || self == .minf
            || self == .dinf || self == .stbl || self == .udta || self == .mdat {
            return true
        } else {
            return false
        }
    }
    
    var isHeader: Bool {
        if self == .ftyp || self == .free || self == .mvhd || self == .tkhd
            || self == .mdhd || self == .stbl || self == .hdlr || self == .vmhd
            || self == .smhd {
            
            return true
        } else {
            return false
        }
    }
}
