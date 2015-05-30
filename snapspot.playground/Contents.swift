//: Playground - noun: a place where people can play

import UIKit

let jsonStr = "{\"user\": \"david\"}"

let data = jsonStr.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) ?? NSData()

let json = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil) as? [String:AnyObject]

json?["user"]

