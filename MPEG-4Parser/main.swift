//
//  main.swift
//  MPEG4Parser
//
//  Created by USER on 24/04/2019.
//  Copyright © 2019 USER. All rights reserved.
//

import Foundation
import VideoToolbox
import AVFoundation



var streamBuffer: [UInt8] = []

@discardableResult
func readStream(stream: InputStream?, amount: Int) -> Int {
    guard let stream = stream, stream.hasBytesAvailable, amount > 0 else {
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
print(stream?.hasBytesAvailable)

let asset = AVAsset(url: dataPath)
let reader = FileReader(url: dataPath)
let mediaReader = MediaFileReader(fileReader: reader!, type: .mp4)
let root: RootType = RootType()
root.size = 1000000000
mediaReader.decodeFile(type: .mp4, root: root)

print(root.moov.mvhd.nextTrackId)
print("is..\(root.moov.traks[1].mdia.minf.stbl.stco.chunkOffsets.count)")//traks[1].mdia.minf.stbl.stsz.entrySize.count)


