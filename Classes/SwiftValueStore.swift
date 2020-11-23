//
//  SwiftValueStore.swift
//  MPWFoundation
//
//  Created by Marcel Weiher on 22.11.20.
//

import Foundation

private struct ValueStoreTestStruct {
    let firstIvar=2
    let secondIvar="Hello"
    let thirdIvar=2.3
}

@objc class SwiftValueStore : MPWAbstractStore {
    var val:Any?

    override public func at(_ ref:MPWReferencing) -> Any? {
        if let val = val {
            let path=ref.path!
            let m=Mirror(reflecting: val)
            if (path=="." || path=="" ) {
                return m.children.map { (key,_) -> String in
                    return key!
                }
            } else {
                for (key,value) in m.children {
                    if key == path {
                        return value
                    }
                }
            }
            return nil

        } else {
            return "Hello"
        }
    }

    override public func at(_ ref:MPWReferencing, put newVal:Any)  {
        val = newVal
    }

    @objc public class func testAtDotReturnsIvarNames() {
        let store=SwiftValueStore.init()
        store.val=ValueStoreTestStruct()
        let result=store.at( MPWGenericReference.init(path: ".") ) as! Array<String>
        precondition(result.count==3)
        precondition(result[0]=="firstIvar")
        precondition(result[1]=="secondIvar")
        precondition(result[2]=="thirdIvar")

    }

    @objc public class func testAtOfKeysReturnsValues() {
        let store=SwiftValueStore.init()
        store.val=ValueStoreTestStruct()
        let result1=store.at( MPWGenericReference.init(path: "firstIvar") ) as! Int
        precondition(result1==2)
        let result2=store.at( MPWGenericReference.init(path: "secondIvar") ) as! String
        precondition(result2=="Hello")

    }

    @objc public class func testSelectors() -> NSArray {
        return [
            "testAtDotReturnsIvarNames",
            "testAtOfKeysReturnsValues"
        ]
    }
}
