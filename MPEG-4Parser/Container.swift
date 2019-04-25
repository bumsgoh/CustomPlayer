//
//  Container.swift
//  MPEG-4Parser
//
//  Created by USER on 25/04/2019.
//  Copyright © 2019 bumslap. All rights reserved.
//

import Foundation

protocol Container {
    var type: ContainerType { get set }
    var size: Int { get set }
    var data: [UInt8] { get set }
    
    func parse()
}
extension Container {
    var isParent: Bool {
        if type == .moov || type == .trak || type == .mdia || type == .minf
            || type == .dinf || type == .stbl || type == .udta || type == .mdat {
            return true
        } else {
            return false
        }
    }
    
    var isHeader: Bool {
        if type == .ftyp || type == .free || type == .mvhd || type == .tkhd || type == . edts
            || type == .mdhd || type == .stbl || type == .hdlr || type == .vmhd
            || type == .smhd {
            
            return true
        } else {
            return false
        }
    }
}


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
            guard let containerType = String(data: convertHexStringToData(string: Array(buffer[0..<4]).tohexNumbers.mergeToString),
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

struct MPEG4File {
    let root: BigBox
    let fileContents: InputStream
    init(file: InputStream) {
        self.root = BigBox(type: .root, size: 0)
        self.fileContents = file
        initailizeContainers()
    }
    private func initailizeContainers(){
        let containerPool = ContainerPool()
        let headerSize = readStream(stream: fileContents, amount: 4)
        let hexNumbers = streamBuffer.tohexNumbers
        streamBuffer.flush()
        var infoSize = hexNumbers.toDecimalValue
        
        if headerSize > 0 {
            root.children = []
        }
        
        while true {
            var container: Container?
            readStream(stream: stream, amount: (infoSize - headerSize))
            guard let containerType = String(data: convertHexStringToData(string: Array(streamBuffer[0..<4]).tohexNumbers.mergeToString),
                                             encoding: .utf8) else {
                return
            }
            let dataFromBuffer = streamBuffer
            streamBuffer.flush()
            do {
                let typeOfContainer = try containerPool.pullOutContainer(with: containerType)
                
                if typeOfContainer.isParent {
                    container = BigBox(type: typeOfContainer, size: infoSize)
                    
                } else {
                    container = SmallBox(type: typeOfContainer, size: infoSize)
                }
                container?.data = Array(dataFromBuffer[4...])
            } catch {
                assertionFailure("initialization failed")
                return
            }
            guard let productedContainer = container else {
                assertionFailure("no container")
                return
            }
            
            root.children?.append(productedContainer)
            readStream(stream: stream, amount: 4)
            
            if streamBuffer.isEmpty {
                break
            }
            infoSize = Array(streamBuffer[0..<4]).tohexNumbers.toDecimalValue
            streamBuffer.flush()
        }
        fileContents.close()
        parse()
    }
    
    private func parse() {
        root.children?.forEach {
            $0.parse()
        }
    }
}
