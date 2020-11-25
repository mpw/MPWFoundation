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
    public func sum() -> Double {
        return Double(firstIvar)+thirdIvar
    }
}

public func check(_ condition: @autoclosure () -> Bool, _ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line)
{
    if !condition() {
        let msg="\(file):\(line): error: \(message())"
        let e=NSException.init(name: NSExceptionName(rawValue: "MPWTestFailedException"), reason: msg, userInfo: nil)
        e.raise()
    }
}


@objc class SwiftValueStore : MPWAbstractStore {
    var val:Any?
    @objc public func setVal(_ newVal:Any ) {
        val=newVal
    }
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
        check(result.count==3)
        check(result[0]=="firstIvar")
        check(result[1]=="secondIvar")
        check(result[2]=="thirdIvar")

    }

    @objc public class func testAtOfKeysReturnsValues() {
        let store=SwiftValueStore.init()
        store.val=ValueStoreTestStruct()
        let result1=store.at( MPWGenericReference.init(path: "firstIvar") ) as! Int
        check(result1==2)
        let result2=store.at( MPWGenericReference.init(path: "secondIvar") ) as! String
        check(result2=="Hello")

    }

    @objc public class func testSelectors() -> NSArray {
        return [
            "testAtDotReturnsIvarNames",
            "testAtOfKeysReturnsValues"
        ]
    }
}
