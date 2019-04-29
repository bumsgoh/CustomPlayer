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
    var data: Data = Data()
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
               // container?.data = dataFromBuffer
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
    var data: Data = Data()
    
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
    case iods
    case mvhd
    case trak
    case tkhd
    case edts
    case elst
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
            || self == .dinf || self == .stbl || self == .edts {
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

class RootType: HalfContainer {
    var offset: UInt64 = 0
    
    
    var type: ContainerType = .root
    var size: Int = 0
    var data: Data = Data()
    
    var ftyp: Ftyp = Ftyp()
    var free: Free = Free()
    var moov: Moov = Moov()
    var udta: Udta = Udta()
    var mdat: Mdat = Mdat()
    
    var children: [Container] = []

    func parse() {
        children.forEach {
            switch $0.type {
            case .ftyp:
                $0.parse()
                self.ftyp = $0 as! Ftyp
            case .free:
                $0.parse()
                self.free = $0 as! Free
            case .moov:
                $0.parse()
                self.moov = $0 as! Moov
            case .udta:
                let child = $0 as! Udta
                child.parse()
                self.udta = child
            case .mdat:
                $0.parse()
                self.mdat = $0 as! Mdat
            default:
                assertionFailure("failed to make root")
            }
        }
    }

}

class Ftyp: Container {
    
    var type: ContainerType = .ftyp
    var size: Int = 0
    var data: Data = Data()
    
    var majorBrand: String = ""
    var minorVersion: String = ""
    var compatibleBrand: [String] = []
    
    func parse() {
        let dataArray = data.slice(in: [4,4,4,4])
        majorBrand = dataArray[0].convertToString
        minorVersion = dataArray[1].convertToString
        compatibleBrand = [dataArray[2].convertToString,
                           dataArray[3].convertToString]
        
    }
    
   /* init(majorBrand: String, minorVersion: String, compatibleBrand: [String] ) {
        self.majorBrand = majorBrand
        self.minorVersion = minorVersion
        self.compatibleBrand = compatibleBrand
    }*/
}

class Free: Container {
    
    var type: ContainerType = .free
    var size: Int = 0
    var data: Data = Data()
    
    func parse() {
        //TODO: freetype parse
    }
    
    /*init(data: Data) {
        self.data = data
    }*/
}
class Mdat: Container {
    
    var type: ContainerType = .mdat
    var size: Int = 0
    var data: Data = Data()
    func parse() {
        
    }
    /*init(data: Data) {
        self.data = data
    }*/
}
class Moov: HalfContainer {
    var offset: UInt64 = 0
    var type: ContainerType = .moov
    var size: Int = 0
    var data: Data = Data()
    
    var mvhd: Mvhd = Mvhd()
    var iods: Iods = Iods()
    var traks: [Trak] = []
    
    var children: [Container] = []
    
    func parse() {
        children.forEach {
            switch $0.type {
            case .mvhd:
                $0.parse()
                self.mvhd = $0 as! Mvhd
            case .iods:
                $0.parse()
                self.iods = $0 as! Iods
            case .trak:
                $0.parse()
                self.traks.append($0 as! Trak)
            default:
                assertionFailure("failed to make moov")
            }
        }
    /*init(mvhd: Mvhd, iods: Iods) {
        self.mvhd = mvhd
        self.iods = iods
    }*/
    }
}

class Mvhd: Container {
   
    var type: ContainerType = .mvhd
    var size: Int = 0
    var data: Data = Data()
    
    var version: Int = 0
    var flag: Int = 0
    var creationDate: Date = Date()
    var modificationTime: Date = Date()
    var timeScale: Int = 0
    var duration: Int = 0
    var nextTrackId: Int = 0
    var rate: Int = 0
    var volume: Int = 0
    var others: Int = 0
    
    init() {}
    
    func parse() {
        let dataArray = data.slice(in: [1,3,4,4,4,4,4,2])
       
       // print(data.count)
        self.version = dataArray[0].convertToInt
        self.flag = dataArray[1].convertToInt
       // print("is//\(dataArray[2].convertToInt)")
        self.creationDate = Date(timeIntervalSince1970: TimeInterval(dataArray[3].convertToInt))
       // self.creationDate = dataArray[2]
       // self.modificationTime = dataArray[3]
        self.timeScale = dataArray[4].convertToInt
        self.duration = dataArray[5].convertToInt
        self.nextTrackId = dataArray[6].convertToInt
        self.rate = dataArray[7].convertToInt
        //self.volume = dataArray[8]
//        self.others = dataArray
    
        
        print(type)
    }
    /*init(version: Int,
         flag: Int,
         creationDate: Date,
         modificationTime: Date,
         timeScale: Int,
         duration: Int,
         nextTrackId: Int,
         rate: Int,
         volume: Int,
         others: Int) {
        self.version = version
        self.flag = flag
        self.creationDate = creationDate
        self.modificationTime = modificationTime
        self.timeScale = timeScale
        self.duration = duration
        self.nextTrackId = nextTrackId
        self.rate = rate
        self.volume = volume
        self.others = others
    }*/
}

class Iods: Container {
    
    var type: ContainerType = .iods
    var size: Int = 0
    var data: Data = Data()
    
    init() {}
    
    func parse() {
        print(type)
    }
    /*init(data: Data) {
        self.data = data
    }*/
}

class Trak: HalfContainer {
    var offset: UInt64 = 0
    
    
    var type: ContainerType = .trak
    var size: Int = 0
    var data: Data = Data()
    
    var tkhd: Tkhd = Tkhd()
    var mdia: Mdia = Mdia()
    var edts: Edts = Edts()
    var chunks: [Chunk] = []
    var samples: [Sample] = []
    
    var children: [Container] = []
    
    init() {}
    
    func parse() {
        children.forEach {
            switch $0.type {
            case .tkhd:
                $0.parse()
                self.tkhd = $0 as! Tkhd
            case .mdia:
                $0.parse()
                self.mdia = $0 as! Mdia
            case .edts:
                $0.parse()
                self.edts = $0 as! Edts
            default:
                assertionFailure("failed to make trak")
            }
        }
   /* init(tkhd: Tkhd,
         mdia: Mdia,
         chunks: [Chunk],
         samples: [Sample]) {
        self.tkhd = tkhd
        self.mdia = mdia
        self.chunks = chunks
        self.samples = samples
    }*/
    }
}
class Tkhd: Container {
    
    var type: ContainerType = .tkhd
    var size: Int = 0
    var data: Data = Data()
    
    var version: Int = 0
    var flag: Int = 0
    var creationDate: Date = Date()
    var modificationTime: Date = Date()
    var layer: Int = 0
    var alternateGroup: Int = 0
    var duration: Int = 0
    var trackId: Int = 0
    var volume: Int = 0
    var matrix: [Int] = []
    var width: Int = 0
    var height: Int = 0
    
    init() {}
    
    func parse() {
        
        let dataArray = data.slice(in: [1,3,4,4,4,4,4,8,2,2,2,2,36,4,4])
        self.creationDate = Date(timeIntervalSince1970: TimeInterval(dataArray[2].convertToInt))
        //self.modificationTime = dataArray[3].convertToInt
        self.trackId = dataArray[4].convertToInt
        
        self.version = dataArray[0].convertToInt
        self.flag = dataArray[1].convertToInt
        self.creationDate = Date(timeIntervalSince1970: TimeInterval(dataArray[2].convertToInt))
        self.modificationTime = Date(timeIntervalSince1970: TimeInterval(dataArray[3].convertToInt))
        self.trackId = dataArray[4].convertToInt
            //reserve 4
        self.duration = dataArray[6].convertToInt
            //reserve 8
        self.layer = dataArray[8].convertToInt
        
        self.alternateGroup = dataArray[9].convertToInt
        self.volume = dataArray[10].convertToInt
        self.matrix = []
        self.width = dataArray[12].convertToInt
        self.height = dataArray[13].convertToInt
        
    }
   /* init(version: Int,
         flag: Int,
         creationDate: Date,
         modificationTime: Date,
         timeScale: Int,
         duration: Int,
         trackId: Int,
         layer: Int,p
         alternateGroup: Int,
         volume: Int,
         matrix: [Int],
         width: Int,
         height: Int) {
        self.version = version
        self.flag = flag
        self.creationDate = creationDate
        self.modificationTime = modificationTime
        self.layer = layer
        self.alternateGroup = alternateGroup
        self.duration = duration
        self.trackId = trackId
        self.volume = volume
        self.matrix = matrix
        self.width = width
        self.height = height
    }*/
}
class Edts: HalfContainer {
    var offset: UInt64 = 0
    
    
    var type: ContainerType = .edts
    var size: Int = 0
    var data: Data = Data()
    
    var elst: Elst = Elst()
    
    init() {}
    
    var children: [Container] = []
    func parse() {
        children.forEach {
            if $0.type == .elst {
                $0.parse()
                self.elst = $0 as! Elst
            }
        }
    }
    /*init(elst: Elst) {
        self.elst = elst
    }*/
}
    
class Elst: Container {
    
    var type: ContainerType = .elst
    var size: Int = 0
    var data: Data = Data()
    
    var version: Int = 0
    var flags: Int = 0
    var entryCount: Int = 0
    var segmentDuration: [Int] = []
    var mediaTime: [Int] = []
    var mediaRateInteger: [Int] = []
    var mediaRateFraction: [Int] = []
    
    init() {}
    
    func parse() {
        let dataArray = data.slice(in: [1,3,4,4])
        self.version = dataArray[0].convertToInt
        self.flags = dataArray[1].convertToInt
        self.entryCount = dataArray[2].convertToInt
        for i in 0..<entryCount {
            let seg = data.subdata(in: (8+12*i)..<(12+12*i)).convertToInt
            let mt = data.subdata(in: (12+12*i)..<(16+12*i)).convertToInt
            let mri = data.subdata(in: (16+12*i)..<(18+12*i)).convertToInt
            let mrf = data.subdata(in: (18+12*i)..<(20+12*i)).convertToInt
            segmentDuration.append(seg)
            mediaTime.append(mt)
            mediaRateInteger.append(mri)
            mediaRateFraction.append(mrf)
        }
    }
}

class Mdia: HalfContainer {
    var offset: UInt64 = 0
    
    
    var type: ContainerType = .mdia
    var size: Int = 0
    var data: Data = Data()
    
    var mdhd: Mdhd = Mdhd()
    var hdlr: Hdlr = Hdlr()
    var minf: Minf = Minf()
    
    var children: [Container] = []
    
    init() {}
    
    
    func parse() {
        children.forEach {
            switch $0.type {
            case .mdhd:
                $0.parse()
                self.mdhd = $0 as! Mdhd
            case .hdlr:
                $0.parse()
                self.hdlr = $0 as! Hdlr
            case .minf:
                $0.parse()
                self.minf = $0 as! Minf
            default:
                assertionFailure("failed to make mdia")
            }
        }
    /*init(mdhd: Mdhd, hdlr: Hdlr, minf: Minf) {
        self.mdhd = mdhd
        self.hdlr = hdlr
        self.minf = minf
    }*/
    }
}
class Mdhd: Container {
    
    var type: ContainerType = .mdhd
    var size: Int = 0
    var data: Data = Data()
    
    var version: Int = 0
    var flag: Int = 0
    var creationDate: Date = Date()
    var modificationTime: Date = Date()
    var timeScale: Int = 0
    var duration: Int = 0
    var language: Int = 0
    
    init() {}
    
    func parse() {
        let dataArray = data.slice(in: [1,3,4,4,4,4,2])
        self.version = dataArray[0].convertToInt
        self.flag = dataArray[1].convertToInt
        self.creationDate = Date(timeIntervalSince1970: TimeInterval(dataArray[2].convertToInt))
        self.modificationTime = Date(timeIntervalSince1970: TimeInterval(dataArray[3].convertToInt))
        self.timeScale = dataArray[4].convertToInt
        self.duration = dataArray[5].convertToInt
        self.language = dataArray[6].convertToInt
    }
    
    /*init(version: Int,
         flag: Int,
         creationDate: Date,
         modificationTime: Date,
         timeScale: Int,
         duration: Int,
         language: Int
         ) {
        self.version = version
        self.flag = flag
        self.creationDate = creationDate
        self.modificationTime = modificationTime
        self.timeScale = timeScale
        self.duration = duration
        self.language = language
    }*/
}
    
class Hdlr: Container {
    
    var type: ContainerType = .hdlr
    var size: Int = 0
    var data: Data = Data()
    
    var version: Int = 0
    var flags: Int = 0
    var preDefined: Int = 0
    var handlerType: String = ""
    var trackName: String = ""
    
    init() {}
    
    func parse() {
        let dataArray = data.slice(in: [1,3,4,4])
        self.version = dataArray[0].convertToInt
        self.flags = dataArray[1].convertToInt
        self.preDefined = dataArray[2].convertToInt
        self.handlerType = dataArray[3].convertToString
        self.trackName = data.subdata(in: 24..<data.count).convertToString
    }
    /*init(version: Int,
         flags: Int,
         preDefined: Int,
         handlerType: String,
         trackName: String) {
        self.version = version
        self.flags = flags
        self.preDefined = preDefined
        self.handlerType = handlerType
        self.trackName = trackName
    }*/
    
}
    
class Minf: HalfContainer {
    var offset: UInt64 = 0
    
    
    var type: ContainerType = .minf
    var size: Int = 0
    var data: Data = Data()
    
    var vmhd: Vmhd = Vmhd()
    var smhd: Smhd = Smhd()
    var stbl: Stbl = Stbl()
    var dinf: Dinf = Dinf()
    var hdlr: Hdlr = Hdlr()
    
    var children: [Container] = []
    
    init() {}
    
    
    func parse() {
        children.forEach {
            switch $0.type {
            case .vmhd:
                $0.parse()
                self.vmhd = $0 as! Vmhd
            case .smhd:
                $0.parse()
                self.smhd = $0 as! Smhd
            case .stbl:
                $0.parse()
                self.stbl = $0 as! Stbl
            case .dinf:
                $0.parse()
                self.dinf = $0 as! Dinf
            case .hdlr:
                $0.parse()
                self.hdlr = $0 as! Hdlr
            default:
                assertionFailure("failed to make mdia")
            }
        }
    /*init(vmhd: Vmhd, smhd: Smhd, stbl: Stbl, dinf: Dinf, hdlr: Hdlr) {
        self.vmhd = vmhd
         self.smhd = smhd
         self.stbl = stbl
         self.dinf = dinf
         self.hdlr = hdlr
    }*/
    }
}
class Vmhd: Container {
    
    var type: ContainerType = .vmhd
    var size: Int = 0
    var data: Data = Data()
    
    var version: Int = 0
    var flags: Int = 0
    var graphicsmode: Int = 0
    var opcolor: [Int] = [] //[3]
    
    init() {}
    
    func parse() {
        let dataArray = data.slice(in: [1,3,2,2])
        self.version = dataArray[0].convertToInt
        self.flags = dataArray[1].convertToInt
        self.graphicsmode = dataArray[2].convertToInt
        for i in 0..<3 {
            self.opcolor.append(data.subdata(in: (6 + 2 * i)..<(8 + 2 * i)).convertToInt)
        }
    }
    
   /* init(version: Int, flags: Int, graphicsmode: Int, opcolor: Int) {
        self.version = version
        self.flags = flags
        self.graphicsmode = graphicsmode
        self.opcolor = opcolor
    }*/
}
class Smhd: Container {
    
    var type: ContainerType = .smhd
    var size: Int = 0
    var data: Data = Data()
    
    var version: Int = 0
    var flags: Int = 0
    var balance: Int = 0
    
    init() {}
    
    func parse() {
        let dataArray = data.slice(in: [1,3,2])
        self.version = dataArray[0].convertToInt
        self.flags = dataArray[1].convertToInt
        self.balance = dataArray[2].convertToInt
    }
    
   /* init(version: Int, flags: Int, balance: Int) {
        self.version = version
        self.flags = flags
        self.balance = balance
    }*/
}

class Dinf: HalfContainer {
    var offset: UInt64 = 0
    
    
    var type: ContainerType = .dinf
    var size: Int = 0
    var data: Data = Data()
    
    var dref: Dref = Dref()
    
    var children: [Container] = []
    
    init() {}
    
    func parse() {
        children.forEach {
            if $0.type == .dref {
                $0.parse()
                self.dref = $0 as! Dref
            }
        }
    }
    
   /* init(dref: Dref) {
        self.dref = dref
    }*/
}

class Dref: Container {
    
    var type: ContainerType = .dref
    var size: Int = 0
    var data: Data = Data()
    
    var version: Int = 0
    var flags: Int = 0
    var entryCount: Int = 0
    var others: Int = 0
    
    init() {}
    
    func parse() {
        let dataArray = data.slice(in: [1,3,2])
        self.version = dataArray[0].convertToInt
        self.flags = dataArray[1].convertToInt
        self.entryCount = dataArray[2].convertToInt
    }
    /*init(version: Int, flags: Int, entryCount: Int) {
        self.version = version
        self.flags = flags
        self.entryCount = entryCount
        self.others = 0
    }*/
}
    
class Stbl: HalfContainer {
    var offset: UInt64 = 0
    
    
    var type: ContainerType = .stbl
    var size: Int = 0
    var data: Data = Data()
    
    var stsd: Stsd = Stsd()// mandatory
    var stts: Stts = Stts() // mandatory
    var stss: Stss = Stss()
    var stsc: Stsc = Stsc()// mandatory
    var stsz: Stsz = Stsz()// mandatory
    var stco: Stco = Stco()// mandatory
    var co64: Co64 = Co64() // mandatory 이지만 없는경우있는듯
    var ctts: Ctts = Ctts()
    
    var children: [Container] = []
    
    init() {}
    
    
    func parse() {
        children.forEach {
            switch $0.type {
            case .stsd:
                $0.parse()
                self.stsd = $0 as! Stsd
            case .stts:
                $0.parse()
                self.stts = $0 as! Stts
            case .stss:
                $0.parse()
                self.stss = $0 as! Stss
            case .stsc:
                $0.parse()
                self.stsc = $0 as! Stsc
            case .stsz:
                $0.parse()
                self.stsz = $0 as! Stsz
            case .stco:
                $0.parse()
                self.stco = $0 as! Stco
            case .co64:
                $0.parse()
                self.co64 = $0 as! Co64
            case .ctts:
                $0.parse()
                self.ctts = $0 as! Ctts
            default:
                assertionFailure("failed to make stbl")
            }
        }
    }
    
    /*init(stsd: Stsd, stts: Stts, stsc: Stsc, stsz: Stsz, stco: Stco) {
        self.stsd = stsd
        self.stts = stts
        self.stsc = stsc
        self.stsz = stsz
        self.stco = stco
    }*/
}
class Co64: Container {
    
    var type: ContainerType = .co64
    var size: Int = 0
    var data: Data = Data()
    
    init() {}
    
    func parse() {
        print(type)
    }
}

class Ctts: Container {
    
    var type: ContainerType = .ctts
    var size: Int = 0
    var data: Data = Data()
    
    var version: Int = 0
    var flags: Int = 0
    var entryCount: Int = 0
    var sampleCounts: [Int] = []
    var sampleOffsets: [Int] = []
    
    init() {}
    
    func parse(){
        print("data..\(data.count)")
        let dataArray = data.slice(in: [1,3,4])
        self.version = dataArray[0].convertToInt
        self.flags = dataArray[1].convertToInt
        self.entryCount = dataArray[2].convertToInt
        print(entryCount)
        for i in 0..<entryCount {
            let sampleCount = data.subdata(in: (8 + 8 * i)..<(12 + 8 * i)).convertToInt
            let sampleOffset = data.subdata(in: (12 + 8 * i)..<(16 + 8 * i)).convertToInt
            self.sampleCounts.append(sampleCount)
            self.sampleOffsets.append(sampleOffset)
            print(sampleOffset)
        }
    }
    
    /*init(version: Int,
         flags: Int,
         entryCount: Int,
         sampleCounts: [Int],
         sampleOffset: [Int]) {
        
        self.version = version
        self.flags = flags
        self.entryCount = entryCount
        self.sampleCounts = sampleCounts
        self.sampleOffset = sampleOffset
    }*/
}

class Stsd: Container {
    
    var type: ContainerType = .stsd
    
    var size: Int = 0
    var data: Data = Data()
    
    var version: Int = 0
    var flags: Int = 0
    var entryCount: Int = 0
    var other: Int = 0
    
    init() {}
    
    func parse() {
        let dataArray = data.slice(in: [1,3,4])
        self.version = dataArray[0].convertToInt
        self.flags = dataArray[1].convertToInt
        self.entryCount = dataArray[2].convertToInt
    }
    
   /* init(version: Int,
         flags: Int,
         entryCount: Int,
         other: Int) {
        
        self.version = version
        self.flags = flags
        self.entryCount = entryCount
        self.other = other
    }*/
}

class Stts: Container {
    
    var type: ContainerType = .stts
    var size: Int = 0
    var data: Data = Data()
    
    var version: Int = 0
    var flags: Int = 0
    var entryCount: Int = 0
    var sampleCounts: [Int] = []
    var sampleDeltas: [Int] = []
    
    init() {}
    
    func parse() {
        let dataArray = data.slice(in: [1,3,4])
        self.version = dataArray[0].convertToInt
        self.flags = dataArray[1].convertToInt
        self.entryCount = dataArray[2].convertToInt
        for i in 0..<entryCount {
            let sampleCount = data.subdata(in: (8 + 8 * i)..<(12 + 8 * i)).convertToInt
            let sampleDelta = data.subdata(in: (12 + 8 * i)..<(16 + 8 * i)).convertToInt
            self.sampleCounts.append(sampleCount)
            self.sampleDeltas.append(sampleDelta)
        }
    }
    
   /* init(version: Int,
         flags: Int,
         entryCount: Int,
         sampleCounts: [Int],
         sampleDelta: [Int]) {
        
        self.version = version
        self.flags = flags
        self.entryCount = entryCount
        self.sampleCounts = sampleCounts
        self.sampleDelta = sampleDelta
    }*/
}
    
class Stss: Container {
    
    var type: ContainerType = .stss
    var size: Int = 0
    var data: Data = Data()
    
    var version: Int = 0
    var flags: Int = 0
    var entryCount: Int = 0
    var sampleNumbers: [Int] = []
    
    init() {}
    
    func parse() {
        let dataArray = data.slice(in: [1,3,4])
        self.version = dataArray[0].convertToInt
        self.flags = dataArray[1].convertToInt
        self.entryCount = dataArray[2].convertToInt
        for i in 0..<entryCount {
            let sample = data.subdata(in: (8 + 4 * i)..<(12 + 4 * i)).convertToInt
            self.sampleNumbers.append(sample)
        }
    }
    
    /*init(version: Int,
         flags: Int,
         entryCount: Int,
         sampleNumber: [Int]) {
        
        self.version = version
        self.flags = flags
        self.entryCount = entryCount
        self.sampleNumber = sampleNumber
    }*/
}
    
class Stsc: Container {
    
    var type: ContainerType = .stsc
    var size: Int = 0
    var data: Data = Data()
    
    var version: Int = 0
    var flags: Int = 0
    var entryCount: Int = 0
    var firstChunks: [Int] = []
    var samplesPerChunks: [Int] = []
    var sampleDescriptionIndexies: [Int] = []
    
    init() {}
    
    func parse() {
        let dataArray = data.slice(in: [1,3,4])
        self.version = dataArray[0].convertToInt
        self.flags = dataArray[1].convertToInt
        self.entryCount = dataArray[2].convertToInt
        for i in 0..<entryCount {
            let firstChunk = data.subdata(in: (8 + 12 * i)..<(12 + 12 * i)).convertToInt
            let samplesPerChunk = data.subdata(in: (12 + 12 * i)..<(16 + 12 * i)).convertToInt
            let sampleDescriptionIndex = data.subdata(in: (16 + 12 * i)..<(20 + 12 * i)).convertToInt
            self.firstChunks.append(firstChunk)
            self.samplesPerChunks.append(samplesPerChunk)
            self.sampleDescriptionIndexies.append(sampleDescriptionIndex)
        }
    }
    
   /* init(version: Int,
         flags: Int,
         entryCount: Int,
         firstChunk: [Int],
         samplesPerChunk: [Int],
         sampleDescriptionIndex: [Int]) {
        
        self.version = version
        self.flags = flags
        self.entryCount = entryCount
        self.firstChunk = firstChunk
        self.samplesPerChunk = samplesPerChunk
        self.sampleDescriptionIndex = sampleDescriptionIndex
    }*/
}

class Stsz: Container {
    
    var type: ContainerType = .stsz
    var size: Int = 0
    var data: Data = Data()
    
    var version: Int = 0
    var flags: Int = 0
    var entrySize: [Int] = []
    var samplesSize: Int = 0
    var sampleCount: Int = 0
    
    init() {}
    
    func parse() {
        let dataArray = data.slice(in: [1,3,4,4])
        self.version = dataArray[0].convertToInt
        self.flags = dataArray[1].convertToInt
        self.samplesSize = dataArray[2].convertToInt
        self.sampleCount = dataArray[3].convertToInt
        for i in 0..<sampleCount {
            if samplesSize == 0 {
                let entry = data.subdata(in: (12 + 4 * i)..<(16 + 4 * i)).convertToInt
                self.entrySize.append(entry)
            }
        }
    }
    /*init(version: Int,
         flags: Int,
         entryCount: [Int],
         sampleCount: Int,
         samplesSize: Int) {
        
        self.version = version
        self.flags = flags
        self.entrySize = entryCount
        self.sampleCount = sampleCount
        self.samplesSize = samplesSize
    }*/
}
    
class Stco: Container {
    
    var type: ContainerType = .stco
    var size: Int = 0
    var data: Data = Data()
    
    var version: Int = 0
    var flags: Int = 0
    var entryCount: Int = 0
    var chunkOffsets: [Int] = []
    
    init() {}
    
    func parse() {
        let dataArray = data.slice(in: [1,3,4])
        self.version = dataArray[0].convertToInt
        self.flags = dataArray[1].convertToInt
        self.entryCount = dataArray[2].convertToInt
        for i in 0..<entryCount {
            let chunkOffset = data.subdata(in: (8 + 4 * i)..<(12 + 4 * i)).convertToInt
            self.chunkOffsets.append(chunkOffset)
        }
    }
    /*init(version: Int,
         flags: Int,
         entryCount: Int,
         chunkOffset: [Int]) {
        
        self.version = version
        self.flags = flags
        self.entryCount = entryCount
        self.chunkOffset = chunkOffset
    }*/
}

class Udta: Container {
    var offset: UInt64 = 0
    
    
    var type: ContainerType = .udta
    var size: Int = 0
    var data: Data = Data()
    
   // var meta: Meta = Meta()
    
    var children: [Container] = []
    
    init() {}
    
    func parse() {
        /*children.forEach {
            if $0.type == .meta {
                    $0.parse()
                    self.meta = $0 as! Meta
            }
        }*/
        print(type)
    }
    
    /*init(meta: Meta) {
        self.meta = meta
    }*/
}


class Meta: Container {
    var offset: UInt64 = 0
    
    
    var type: ContainerType = .meta
    var size: Int = 0
    var data: Data = Data()
    
    var version: Int = 0
    var flag: Int = 0
    //var handler: Hdlr = Hdlr()
    
    //var children: [Container] = []
    
    init() {}
    
    func parse() {
        print(type)
        /*children.forEach {
            if $0.type == .hdlr {
                $0.parse()
                self.handler = $0 as! Hdlr
            }
        }*/
    }
    /*init(version: Int, flag: Int, handler: Hdlr) {
        self.version = version
        self.flag = flag
        self.handler = handler
    }*/
}

class Chunk {
    var sampleDescriptionIndex: Int = 0
    var firstSample: Int = 0
    var sampleCount: Int = 0
    var offset: Int = 0
    
    init() {}
    
    /*init(sampleDescriptionIndex: Int,
         firstSample: Int,
         sampleCount: Int,
         offset: Int) {
        self.sampleDescriptionIndex = sampleDescriptionIndex
        self.firstSample = firstSample
        self.sampleCount = sampleCount
        self.offset = offset
    }*/
}

class Sample {
    var size: Int = 0
    var offset: Int = 0
    var startTime: Int = 0
    var duration: Int = 0
    var cto: Int = 0
    
    init() {}
    
    /*init(size: Int,
         offset: Int,
         startTime: Int,
         duration: Int,
         cto: Int) {
        self.size = size
        self.offset = offset
        self.startTime = startTime
        self.duration = duration
        self.cto = cto
    }*/
    
}
