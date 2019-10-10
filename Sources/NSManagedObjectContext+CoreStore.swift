//
//  NSManagedObjectContext+CoreStore.swift
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


// MARK: - NSManagedObjectContext

extension NSManagedObjectContext {
    
    // MARK: Internal
    
    @nonobjc
    internal var shouldCascadeSavesToParent: Bool {
        
        get {
            
            let number: NSNumber? = Internals.getAssociatedObjectForKey(
                &PropertyKeys.shouldCascadeSavesToParent,
                inObject: self
            )
            return number?.boolValue ?? false
        }
        set {
            
            Internals.setAssociatedCopiedObject(
                NSNumber(value: newValue),
                forKey: &PropertyKeys.shouldCascadeSavesToParent,
                inObject: self
            )
        }
    }
    
    @nonobjc
    internal func setupForCoreStoreWithContextName(_ contextName: String) {
        
        self.name = contextName
        self.observerForWillSaveNotification = Internals.NotificationObserver(
            notificationName: NSNotification.Name.NSManagedObjectContextWillSave,
            object: self,
            closure: { (note) -> Void in
                
                let context = note.object as! NSManagedObjectContext
                let insertedObjects = context.insertedObjects
                let numberOfInsertedObjects = insertedObjects.count
                guard numberOfInsertedObjects > 0 else {
                    
                    return
                }
                
                do {
                    
                    try context.obtainPermanentIDs(for: Array(insertedObjects))
                }
                catch {
                    
                    Internals.log(
                        CoreStoreError(error),
                        "Failed to obtain permanent ID(s) for \(numberOfInsertedObjects) inserted object(s)."
                    )
                }
            }
        )
    }

    @nonobjc
    internal func liveObject<D: DynamicObject>(id: NSManagedObjectID) -> LiveObject<D> {

        let cache = self.liveObjectsCache(D.self)
        return Internals.with {

            if let liveObject = cache.object(forKey: id) {

                return liveObject
            }
            let liveObject = LiveObject<D>(id: id, context: self)
            cache.setObject(liveObject, forKey: id)
            return liveObject
        }
    }

    @nonobjc
    private func liveObjectsCache<D: DynamicObject>(_ objectType: D.Type) -> NSMapTable<NSManagedObjectID, LiveObject<D>> {

        let key = Internals.typeName(objectType)
        if let cache = self.userInfo[key] {

            return cache as! NSMapTable<NSManagedObjectID, LiveObject<D>>
        }
        let cache = NSMapTable<NSManagedObjectID, LiveObject<D>>.strongToWeakObjects()
        self.userInfo[key] = cache
        return cache
    }
    
    
    // MARK: Private
    
    private struct PropertyKeys {
        
        static var observerForWillSaveNotification: Void?
        static var shouldCascadeSavesToParent: Void?
    }
    
    @nonobjc
    private var observerForWillSaveNotification: Internals.NotificationObserver? {
        
        get {
            
            return Internals.getAssociatedObjectForKey(
                &PropertyKeys.observerForWillSaveNotification,
                inObject: self
            )
        }
        set {
            
            Internals.setAssociatedRetainedObject(
                newValue,
                forKey: &PropertyKeys.observerForWillSaveNotification,
                inObject: self
            )
        }
    }
}

