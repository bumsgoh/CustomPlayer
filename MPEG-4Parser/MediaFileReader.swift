//
//  MediaFileReader.swift
//  MPEG-4Parser
//
//  Created by bumslap on 29/04/2019.
//  Copyright © 2019 bumslap. All rights reserved.
//

import Foundation

class MediaFileReader {
    let fileReader: FileStreamReadable
    let typeOfContainer: FileContainerType
    let containerPool: ContainerPool = ContainerPool()
    let root: RootType = RootType()
    
    private let headerSize = 8
    
    private var fileOffset = 0
    
    init(fileReader: FileStreamReadable, type: FileContainerType) {
        self.fileReader = fileReader
        self.typeOfContainer = type
    }
    
    private func readHeader(completion: @escaping ((Int, String))->()) {
        fileReader.read(length: 8) {(data) in
            let result = self.converToHeaderInfo(data: data)
            completion(result)

        }
    }
    
    private func converToHeaderInfo(data: Data) -> (Int, String) {

        let sizeData = data.subdata(in: 0..<4)
        let size = sizeData.convertToInt
        guard let decodedHeaderName = String(data: data.subdata(in: 4..<8),
                                       encoding: .utf8) else {
            return (0,"")
        }
        fileOffset += 8
        return (size, decodedHeaderName)
    }
    
    func decodeFile(type: FileContainerType, root: HalfContainer) {
        //TODO filetype 에 따라 다른 디코딩 방식제공해야함
        var containers: [HalfContainer] = []
        
        containers = decode(root: root)
        
        while let item = containers.first {
            containers.remove(at: 0)
            let parentContainers = decode(root: item)
            containers.append(contentsOf: parentContainers)
        }
    }
    
    private func decode(root: HalfContainer) -> [HalfContainer] {
        var containers: [HalfContainer] = []
        var currentRootContainer: HalfContainer = root
        var currentOffset = currentRootContainer.offset
        fileReader.seek(offset: currentOffset)
        while fileReader.hasAvailableData() {
            readHeader() { [weak self] (headerData) in
                guard let self = self else { return }
                let size = headerData.0
                let headerName = headerData.1
                currentOffset = self.fileReader.currentOffset()
                
                self.fileReader.read(length: size - self.headerSize) { (data) in
                    do {
                        if Int(currentRootContainer.offset) + currentRootContainer.size > Int(currentOffset) {
                        let typeOfContainer = try self.containerPool.pullOutContainer(with: headerName)
                        var box = self.containerPool.pullOutFileTypeContainer(with: typeOfContainer)
                        box.size = size
                            
                        if box.isParent {
                            guard var castedBox = box as? HalfContainer else { return }
                            castedBox.offset = currentOffset
                            containers.append(castedBox)
                        } else {
                            box.data = data[0..<(size - self.headerSize)]
                        }
                        currentRootContainer.children.append(box)
                        }
                        
                    } catch {
                        assertionFailure("initialization box failed")
                        return
                    }
                }
            }
           if Int(currentRootContainer.offset) + currentRootContainer.size < Int(currentOffset) { break }
        }
        return containers
    }
}
enum FileContainerType {
    case mp4
}


