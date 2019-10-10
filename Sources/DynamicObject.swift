//
//  DynamicObject.swift
//  CoreStore
//
//  Copyright © 2018 John Rommel Estropia
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation
import CoreData


// MARK: - DynamicObject

/**
 All CoreStore's utilities are designed around `DynamicObject` instances. `NSManagedObject` and `CoreStoreObject` instances all conform to `DynamicObject`.
 */
public protocol DynamicObject: AnyObject {

    /**
     The object ID for this instance
     */
    typealias ObjectID = NSManagedObjectID

    /**
     Used internally by CoreStore. Do not call directly.
     */
    static func cs_forceCreate(entityDescription: NSEntityDescription, into context: NSManagedObjectContext, assignTo store: NSPersistentStore) -> Self

    /**
     Used internally by CoreStore. Do not call directly.
     */
    static func cs_snapshotDictionary(id: ObjectID, context: NSManagedObjectContext) -> [String: Any]

    /**
     Used internally by CoreStore. Do not call directly.
     */
    static func cs_fromRaw(object: NSManagedObject) -> Self
    
    /**
     Used internally by CoreStore. Do not call directly.
     */
    static func cs_matches(object: NSManagedObject) -> Bool
    
    /**
     Used internally by CoreStore. Do not call directly.
     */
    func cs_id() -> ObjectID
    
    /**
     Used internally by CoreStore. Do not call directly.
     */
    func cs_toRaw() -> NSManagedObject
}

extension DynamicObject {

    // MARK: Internal
    
    internal static func keyPathBuilder() -> DynamicObjectMeta<Never, Self> {

        return .init(keyPathString: "SELF")
    }
    
    internal func runtimeType() -> Self.Type {
        
        // Self.self does not return runtime-created types
        return object_getClass(self)! as! Self.Type
    }
}


// MARK: - NSManagedObject

extension NSManagedObject: DynamicObject {
    
    // MARK: DynamicObject
    
    public class func cs_forceCreate(entityDescription: NSEntityDescription, into context: NSManagedObjectContext, assignTo store: NSPersistentStore) -> Self {
        
        let object = self.init(entity: entityDescription, insertInto: context)
        defer {
            
            context.assign(object, to: store)
        }
        return object
    }

    public class func cs_snapshotDictionary(id: ObjectID, context: NSManagedObjectContext) -> [String: Any] {

        let object = context.fetchExisting(id)! as Self
        let rawObject = object.cs_toRaw()
        return rawObject.dictionaryWithValues(forKeys: rawObject.entity.properties.map({ $0.name }))
    }
    
    public class func cs_fromRaw(object: NSManagedObject) -> Self {
        
        return unsafeDowncast(object, to: self)
    }
    
    public static func cs_matches(object: NSManagedObject) -> Bool {
        
        return object.isKind(of: self)
    }
    
    public func cs_id() -> ObjectID {
        
        return self.objectID
    }
    
    public func cs_toRaw() -> NSManagedObject {
        
        return self
    }
}


// MARK: - CoreStoreObject

extension CoreStoreObject {
    
    // MARK: DynamicObject
    
    public class func cs_forceCreate(entityDescription: NSEntityDescription, into context: NSManagedObjectContext, assignTo store: NSPersistentStore) -> Self {
        
        let type = NSClassFromString(entityDescription.managedObjectClassName!)! as! NSManagedObject.Type
        let object = type.init(entity: entityDescription, insertInto: context)
        defer {
            
            context.assign(object, to: store)
        }
        return self.cs_fromRaw(object: object)
    }

    public class func cs_snapshotDictionary(id: ObjectID, context: NSManagedObjectContext) -> [String: Any] {

        func initializeAttributes(mirror: Mirror, object: Self, into attributes: inout [KeyPathString: Any]) {

            if let superClassMirror = mirror.superclassMirror {

                initializeAttributes(
                    mirror: superClassMirror,
                    object: object,
                    into: &attributes
                )
            }
            for child in mirror.children {

                switch child.value {

                case let property as AttributeProtocol:
                    attributes[property.keyPath] = property.valueForSnapshot

                case let property as RelationshipProtocol:
                    attributes[property.keyPath] = property.valueForSnapshot

                default:
                    continue
                }
            }
        }
        let object = context.fetchExisting(id)! as Self
        var values: [KeyPathString: Any] = [:]
        initializeAttributes(
            mirror: Mirror(reflecting: object),
            object: object,
            into: &values
        )
        return values
    }
    
    public class func cs_fromRaw(object: NSManagedObject) -> Self {
        
        if let coreStoreObject = object.coreStoreObject {
            
            return unsafeDowncast(coreStoreObject, to: self)
        }
        func forceTypeCast<T: CoreStoreObject>(_ type: AnyClass, to: T.Type) -> T.Type {
            
            return type as! T.Type
        }
        let coreStoreObject = forceTypeCast(object.entity.dynamicObjectType!, to: self).init(rawObject: object)
        object.coreStoreObject = coreStoreObject
        return coreStoreObject
    }
    
    public static func cs_matches(object: NSManagedObject) -> Bool {
        
        guard let type = object.entity.coreStoreEntity?.type else {
            
            return false
        }
        return (self as AnyClass).isSubclass(of: type as AnyClass)
    }
    
    public func cs_id() -> ObjectID {
        
        return self.rawObject!.objectID
    }
    
    public func cs_toRaw() -> NSManagedObject {
        
        return self.rawObject!
    }
}
