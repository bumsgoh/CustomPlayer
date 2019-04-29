//
//  ContainerPool.swift
//  MPEG-4Parser
//
//  Created by USER on 25/04/2019.
//  Copyright © 2019 bumslap. All rights reserved.
//

import Foundation

class ContainerPool {
    private var containerPool = [String: ContainerType]()
    private var fileContainerPool = [ContainerType: Container]()
    init() {
        
        ContainerType.allCases.forEach {
            containerPool.updateValue($0, forKey: $0.rawValue)
        }
        
        fileContainerPool.updateValue(Ftyp(), forKey: .ftyp)
        fileContainerPool.updateValue(Free(), forKey: .free)
        fileContainerPool.updateValue(Mdat(), forKey: .mdat)
        fileContainerPool.updateValue(Moov(), forKey: .moov)
        fileContainerPool.updateValue(Iods(), forKey: .iods)
        fileContainerPool.updateValue(Mvhd(), forKey: .mvhd)
        fileContainerPool.updateValue(Trak(), forKey: .trak)
        fileContainerPool.updateValue(Tkhd(), forKey: .tkhd)
        fileContainerPool.updateValue(Edts(), forKey: .edts)
        fileContainerPool.updateValue(Elst(), forKey: .elst)
        fileContainerPool.updateValue(Mdia(), forKey: .mdia)
        fileContainerPool.updateValue(Mdhd(), forKey: .mdhd)
        fileContainerPool.updateValue(Hdlr(), forKey: .hdlr)
        fileContainerPool.updateValue(Minf(), forKey: .minf)
        fileContainerPool.updateValue(Vmhd(), forKey: .vmhd)
        fileContainerPool.updateValue(Smhd(), forKey: .smhd)
        fileContainerPool.updateValue(Dinf(), forKey: .dinf)
        fileContainerPool.updateValue(Dref(), forKey: .dref)
        fileContainerPool.updateValue(Stbl(), forKey: .stbl)
        fileContainerPool.updateValue(Co64(), forKey: .co64)
        fileContainerPool.updateValue(Ctts(), forKey: .ctts)
        fileContainerPool.updateValue(Stsd(), forKey: .stsd)
        fileContainerPool.updateValue(Stts(), forKey: .stts)
        fileContainerPool.updateValue(Stss(), forKey: .stss)
        fileContainerPool.updateValue(Stsc(), forKey: .stsc)
        fileContainerPool.updateValue(Stsz(), forKey: .stsz)
        fileContainerPool.updateValue(Stco(), forKey: .stco)
        fileContainerPool.updateValue(Udta(), forKey: .udta)
        fileContainerPool.updateValue(Meta(), forKey: .meta)
        
    }
    func pullOutContainer(with name: String) throws -> ContainerType {
        guard let container = containerPool[name] else {
            throw NSError(domain: "No container with input name", code: 0)
        }
        return container
    }
    func pullOutFileTypeContainer(with type: ContainerType) -> Container {
        
        switch type {
        case .root:
            return RootType()
        case .ftyp:
            return Ftyp()
        case .free:
            return Free()
        case .mdat:
            return Mdat()
        case .moov:
            return Moov()
        case .iods:
            return Iods()
        case .mvhd:
            return Mvhd()
        case .trak:
            return Trak()
        case .tkhd:
            return Tkhd()
        case .edts:
            return Edts()
        case .elst:
            return Elst()
        case .mdia:
            return Mdia()
        case .mdhd:
            return Mdhd()
        case .hdlr:
            return Hdlr()
        case .minf:
            return Minf()
        case .vmhd:
            return Vmhd()
        case .smhd:
            return Smhd()
        case .dinf:
            return Dinf()
        case .dref:
            return Dref()
        case .stbl:
            return Stbl()
        case .co64:
            return Co64()
        case .ctts:
            return Ctts()
        case .stsd:
            return Stsd()
        case .stts:
            return Stts()
        case .stss:
            return Stss()
        case .stsc:
            return Stsc()
        case .stsz:
            return Stsz()
        case .stco:
            return Stco()
        case .udta:
            return Udta()
        case .meta:
            return Meta()
        }
    }
}



