//
//  MP4File.swift
//  MPEG-4Parser
//
//  Created by USER on 26/04/2019.
//  Copyright © 2019 bumslap. All rights reserved.
//

import Foundation

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
            guard let containerType = String(data: Array(streamBuffer[0..<4])
                .tohexNumbers
                .mergeToString
                .convertHexStringToData,
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
