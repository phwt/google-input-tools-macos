//
//  CloudInputEngine.swift
//  GoogleInputTools
//
//  Created by lennylxx on 8/22/21.
//

import Foundation

enum InputTool: String {
    case Thai = "th-t-i0-und"
    case Pinyin = "zh-t-i0-pinyin"
    case Shuangpin_ABC = "zh-t-i0-pinyin-x0-shuangpin-abc"
    case Shuangpin_Microsoft = "zh-t-i0-pinyin-x0-shuangpin-ms"
    case Shuangpin_Xiaohe = "zh-t-i0-pinyin-x0-shuangpin-flypy"
    case Shuangpin_Jiajia = "zh-t-i0-pinyin-x0-shuangpin-jiajia"
    case Shuangpin_Ziguang = "zh-t-i0-pinyin-x0-shuangpin-ziguang"
    case Shuangpin_Ziranma = "zh-t-i0-pinyin-x0-shuangpin-ziranma"
    case Wubi = "zh-t-i0-wubi-1986"
}

class CloudInputEngine {

    static let shared = CloudInputEngine()

    let _inputTool = InputTool.Thai
    let _candidateNum = 11

    func requestCandidates(
        _ text: String,
        complete: @escaping (_ candidates: [String], _ matchedLength: [Int]?) -> Void
    ) {
        let url = URL(
            string:
                "https://inputtools.google.com/request?text=\(text)&itc=\(_inputTool.rawValue)&num=\(_candidateNum)&cp=0&cs=1&ie=utf-8&oe=utf-8&app=demopage"
        )!

        NSLog("%@", url.absoluteString)

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else { return }

            /*
            [
              "SUCCESS",
              [[
                "abc",
                ["ABC","啊","阿","A","吖","腌","呵","阿布","嗄","啊不","锕"],
                [],
                {
                    "annotation":["a b c","a","a","a","a","a","a","a bu","a","a bu","a"],
                    "candidate_type":[0,0,0,0,0,0,0,0,0,0,0],
                    "lc":["0 0 0","16","16","0","16","16","16","16 16","16","16 16","16"],
                    "matched_length":[3,1,1,1,1,1,1,2,1,2,1]
                }
              ]]
             ]
            */

            let json = try? JSONSerialization.jsonObject(with: data, options: [])

            let response = json as! [Any]
            let status = response[0] as! String

            if status == "SUCCESS" {
                let candidateObject = (response[1] as! [Any])[0] as! [Any]

                // let inputText = candidateObject[0] as! String
                let candidateArray = candidateObject[1] as! [String]
                let candidateMeta = candidateObject[3] as! [String: Any]

                // let annotation = candidateMeta["annotation"] as! Array<String>
                let matchedLength = candidateMeta["matched_length"] as? [Int]
                complete(candidateArray, matchedLength)
            }
        }

        task.resume()
    }

    func requestCandidatesSync(_ text: String) -> ([String], [Int]?) {
        let semaphore = DispatchSemaphore(value: 0)

        var candidates: [String] = []
        var matchedLength: [Int]? = []
        requestCandidates(text) { result, length in
            candidates = result
            matchedLength = length
            semaphore.signal()
        }

        semaphore.wait()

        return (candidates, matchedLength)
    }
}
