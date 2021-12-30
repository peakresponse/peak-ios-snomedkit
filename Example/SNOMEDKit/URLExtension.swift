//
//  URLExtension.swift
//  SNOMEDKit_Example
//
//  Created by Francis Li on 12/16/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation

extension URL {
    // adapted from: https://stackoverflow.com/a/69176348
    func read(_ line: ((String, Int) -> Void)) {
        let path = self.path
        guard let cfilePath = (path as NSString).utf8String,
              let m = ("r" as NSString).utf8String
        else {return}

        guard let file = fopen(cfilePath, m)
        else {
            print("fopen can't open file: \"\(path)\"")
            return
        }

        // Row capacity for getline()
        var cap = 0
        var index = 0

        // Row container for getline()
        var cline: UnsafeMutablePointer<CChar>?

        // Free memory and close file at the end
        defer {
            free(cline)
            fclose(file)
        }
        while getline(&cline, &cap, file) > 0 {
            if let crow = cline,
               // the output line may contain '\n' that's why we filtered it
               let s = String(utf8String: crow)?.filter({($0.asciiValue ?? 0) >= 32 || ($0.asciiValue ?? 0) == 9}) {
                line(s, index)
            }
            index += 1
        }
    }
}
