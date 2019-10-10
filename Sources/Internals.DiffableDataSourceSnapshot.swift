//
//  Internals.DiffableDataSourceSnapshot.swift
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

#if canImport(UIKit) || canImport(AppKit)

import CoreData

#if canImport(UIKit)
import UIKit

#elseif canImport(AppKit)
import AppKit

#endif


// MARK: - Internals

extension Internals {


    // MARK: - DiffableDataSourceSnapshot

    // Implementation based on https://github.com/ra1028/DiffableDataSources
    internal struct DiffableDataSourceSnapshot {

        // MARK: Internal

        internal let nextStateTag: UUID

        init() {

            self.structure = .init()
            self.nextStateTag = .init()
        }

        init(sections: [NSFetchedResultsSectionInfo], previousStateTag: UUID, nextStateTag: UUID) {

            self.structure = .init(sections: sections, previousStateTag: previousStateTag)
            self.nextStateTag = nextStateTag
        }

        var numberOfItems: Int {

            return self.structure.allItemIDs.count
        }

        var numberOfSections: Int {

            return self.structure.allSectionIDs.count
        }

        var allSectionIDs: [String] {

            return self.structure.allSectionIDs
        }

        var allSectionStateIDs: [SectionStateID] {

            return self.structure.allSectionStateIDs
        }

        var allItemIDs: [NSManagedObjectID] {

            return self.structure.allItemIDs
        }

        var allItemStateIDs: [ItemStateID] {

            return self.structure.allItemStateIDs
        }

        func numberOfItems(inSection identifier: String) -> Int {

            return self.itemIDs(inSection: identifier).count
        }

        func itemIDs(inSection identifier: String) -> [NSManagedObjectID] {

            return self.structure.items(in: identifier)
        }

        func itemStateIDs(inSection identifier: String) -> [ItemStateID] {

            return self.structure.itemStateIDs(in: identifier)
        }

        func sectionIDs(containingItem identifier: NSManagedObjectID) -> String? {

            return self.structure.section(containing: identifier)
        }

        func sectionStateIDs(containingItem identifier: NSManagedObjectID) -> SectionStateID? {

            return self.structure.sectionStateID(containing: identifier)
        }

        func indexOfItemID(_ identifier: NSManagedObjectID) -> Int? {

            return self.structure.allItemIDs.firstIndex(of: identifier)
        }

        func indexOfSectionID(_ identifier: String) -> Int? {

            return self.structure.allSectionIDs.firstIndex(of: identifier)
        }

        func itemIDs(where stateCondition: @escaping (UUID) -> Bool) -> [NSManagedObjectID] {

            return self.structure.itemsIDs(where: stateCondition)
        }

        mutating func appendItems(_ identifiers: [NSManagedObjectID], toSection sectionIdentifier: String?, nextStateTag: UUID) {

            self.structure.append(itemIDs: identifiers, to: sectionIdentifier, nextStateTag: nextStateTag)
        }

        mutating func insertItems(_ identifiers: [NSManagedObjectID], beforeItem beforeIdentifier: NSManagedObjectID, nextStateTag: UUID) {

            self.structure.insert(itemIDs: identifiers, before: beforeIdentifier, nextStateTag: nextStateTag)
        }

        mutating func insertItems(_ identifiers: [NSManagedObjectID], afterItem afterIdentifier: NSManagedObjectID, nextStateTag: UUID) {

            self.structure.insert(itemIDs: identifiers, after: afterIdentifier, nextStateTag: nextStateTag)
        }

        mutating func deleteItems(_ identifiers: [NSManagedObjectID]) {

            self.structure.remove(itemIDs: identifiers)
        }

        mutating func deleteAllItems() {

            self.structure.removeAllItems()
        }

        mutating func moveItem(_ identifier: NSManagedObjectID, beforeItem toIdentifier: NSManagedObjectID) {

            self.structure.move(itemID: identifier, before: toIdentifier)
        }

        mutating func moveItem(_ identifier: NSManagedObjectID, afterItem toIdentifier: NSManagedObjectID) {

            self.structure.move(itemID: identifier, after: toIdentifier)
        }

        mutating func reloadItems<S: Sequence>(_ identifiers: S, nextStateTag: UUID) where S.Element == NSManagedObjectID {

            self.structure.update(itemIDs: identifiers, nextStateTag: nextStateTag)
        }

        mutating func appendSections(_ identifiers: [String], nextStateTag: UUID) {

            self.structure.append(sectionIDs: identifiers, nextStateTag: nextStateTag)
        }

        mutating func insertSections(_ identifiers: [String], beforeSection toIdentifier: String, nextStateTag: UUID) {

            self.structure.insert(sectionIDs: identifiers, before: toIdentifier, nextStateTag: nextStateTag)
        }

        mutating func insertSections(_ identifiers: [String], afterSection toIdentifier: String, nextStateTag: UUID) {

            self.structure.insert(sectionIDs: identifiers, after: toIdentifier, nextStateTag: nextStateTag)
        }

        mutating func deleteSections(_ identifiers: [String]) {

            self.structure.remove(sectionIDs: identifiers)
        }

        mutating func moveSection(_ identifier: String, beforeSection toIdentifier: String) {

            self.structure.move(sectionID: identifier, before: toIdentifier)
        }

        mutating func moveSection(_ identifier: String, afterSection toIdentifier: String) {

            self.structure.move(sectionID: identifier, after: toIdentifier)
        }

        mutating func reloadSections<S: Sequence>(_ identifiers: S, nextStateTag: UUID) where S.Element == String {

            self.structure.update(sectionIDs: identifiers, nextStateTag: nextStateTag)
        }


        // MARK: Private

        private var structure: BackingStructure


        // MARK: - ItemStateID

        internal struct ItemStateID: Identifiable, Equatable {

            let stateTag: UUID

            init(id: NSManagedObjectID, stateTag: UUID) {

                self.id = id
                self.stateTag = stateTag
            }

            func isContentEqual(to source: ItemStateID) -> Bool {

                return self.id == source.id && self.stateTag == source.stateTag
            }

            // MARK: Identifiable

            let id: NSManagedObjectID
        }


        // MARK: - SectionStateID

        internal struct SectionStateID: Identifiable, Equatable {

            let stateTag: UUID

            init(id: String, stateTag: UUID) {
                self.id = id
                self.stateTag = stateTag
            }

            func isContentEqual(to source: SectionStateID) -> Bool {

                return self.id == source.id && self.stateTag == source.stateTag
            }

            // MARK: Identifiable

            let id: String
        }


        // MARK: - BackingStructure

        fileprivate struct BackingStructure {

            // MARK: Internal

            var sections: [Section]

            init() {

                self.sections = []
            }

            init(sections: [NSFetchedResultsSectionInfo], previousStateTag: UUID) {

                self.sections = sections.map {

                    Section(
                        id: $0.name,
                        items: $0.objects?
                            .compactMap({ ($0 as? NSManagedObject)?.objectID })
                            .map({ Item(id: $0, stateTag: previousStateTag) }) ?? [],
                        stateTag: previousStateTag
                    )
                }
            }

            var allSectionIDs: [String] {

                return self.sections.map({ $0.id })
            }

            var allSectionStateIDs: [SectionStateID] {

                return self.sections.map({ $0.stateID })
            }

            var allItemIDs: [NSManagedObjectID] {

                return self.sections.lazy.flatMap({ $0.elements }).map({ $0.id })
            }

            var allItemStateIDs: [ItemStateID] {

                return self.sections.lazy.flatMap({ $0.elements }).map({ $0.stateID })
            }

            func items(in sectionID: String) -> [NSManagedObjectID] {

                guard let sectionIndex = self.sectionIndex(of: sectionID) else {

                    Internals.abort("Section \"\(sectionID)\" does not exist")
                }
                return self.sections[sectionIndex].elements.map({ $0.id })
            }

            func itemsIDs(where stateCondition: @escaping (UUID) -> Bool) -> [NSManagedObjectID] {

                return self.sections.lazy
                    .flatMap({ $0.elements.filter({ stateCondition($0.stateTag) }) })
                    .map({ $0.id })
            }

            func itemStateIDs(in sectionID: String) -> [ItemStateID] {

                guard let sectionIndex = self.sectionIndex(of: sectionID) else {

                    Internals.abort("Section \"\(sectionID)\" does not exist")
                }
                return self.sections[sectionIndex].elements.map({ $0.stateID })
            }

            func section(containing itemID: NSManagedObjectID) -> String? {

                return self.itemPositionMap()[itemID]?.section.id
            }

            func sectionStateID(containing itemID: NSManagedObjectID) -> SectionStateID? {

                return self.itemPositionMap()[itemID]?.section.stateID
            }

            mutating func append(itemIDs: [NSManagedObjectID], to sectionID: String?, nextStateTag: UUID) {

                let index: Array<Section>.Index
                if let sectionID = sectionID {

                    guard let sectionIndex = self.sectionIndex(of: sectionID) else {

                        Internals.abort("Section \"\(sectionID)\" does not exist")
                    }
                    index = sectionIndex
                }
                else {

                    let section = self.sections
                    guard !section.isEmpty else {

                        Internals.abort("No sections exist")
                    }
                    index = section.index(before: section.endIndex)
                }
                let items = itemIDs.lazy.map({ Item(id: $0, stateTag: nextStateTag) })
                self.sections[index].elements.append(contentsOf: items)
            }

            mutating func insert(itemIDs: [NSManagedObjectID], before beforeItemID: NSManagedObjectID, nextStateTag: UUID) {

                guard let itemPosition = self.itemPositionMap()[beforeItemID] else {

                    Internals.abort("Item \(beforeItemID) does not exist")
                }
                let items = itemIDs.lazy.map({ Item(id: $0, stateTag: nextStateTag) })
                self.sections[itemPosition.sectionIndex].elements
                    .insert(contentsOf: items, at: itemPosition.itemRelativeIndex)
            }

            mutating func insert(itemIDs: [NSManagedObjectID], after afterItemID: NSManagedObjectID, nextStateTag: UUID) {

                guard let itemPosition = self.itemPositionMap()[afterItemID] else {

                    Internals.abort("Item \(afterItemID) does not exist")
                }
                let itemIndex = self.sections[itemPosition.sectionIndex].elements
                    .index(after: itemPosition.itemRelativeIndex)
                let items = itemIDs.lazy.map({ Item(id: $0, stateTag: nextStateTag) })
                self.sections[itemPosition.sectionIndex].elements
                    .insert(contentsOf: items, at: itemIndex)
            }

            mutating func remove(itemIDs: [NSManagedObjectID]) {

                let itemPositionMap = self.itemPositionMap()
                var removeIndexSetMap: [Int: IndexSet] = [:]

                for itemID in itemIDs {

                    guard let itemPosition = itemPositionMap[itemID] else {

                        continue
                    }
                    removeIndexSetMap[itemPosition.sectionIndex, default: []]
                        .insert(itemPosition.itemRelativeIndex)
                }
                for (sectionIndex, removeIndexSet) in removeIndexSetMap {

                    for range in removeIndexSet.rangeView.reversed() {

                        self.sections[sectionIndex].elements.removeSubrange(range)
                    }
                }
            }

            mutating func removeAllItems() {

                for sectionIndex in self.sections.indices {

                    self.sections[sectionIndex].elements.removeAll()
                }
            }

            mutating func move(itemID: NSManagedObjectID, before beforeItemID: NSManagedObjectID) {

                guard let removed = self.remove(itemID: itemID) else {

                    Internals.abort("Item \(itemID) does not exist")
                }
                guard let itemPosition = self.itemPositionMap()[beforeItemID] else {

                    Internals.abort("Item \(beforeItemID) does not exist")
                }
                self.sections[itemPosition.sectionIndex].elements
                    .insert(removed, at: itemPosition.itemRelativeIndex)
            }

            mutating func move(itemID: NSManagedObjectID, after afterItemID: NSManagedObjectID) {

                guard let removed = self.remove(itemID: itemID) else {

                    Internals.abort("Item \(itemID) does not exist")
                }
                guard let itemPosition = self.itemPositionMap()[afterItemID] else {

                    Internals.abort("Item \(afterItemID) does not exist")
                }
                let itemIndex = self.sections[itemPosition.sectionIndex].elements
                    .index(after: itemPosition.itemRelativeIndex)
                self.sections[itemPosition.sectionIndex].elements
                    .insert(removed, at: itemIndex)
            }

            mutating func update<S: Sequence>(itemIDs: S, nextStateTag: UUID) where S.Element == NSManagedObjectID {

                let itemPositionMap = self.itemPositionMap()
                for itemID in itemIDs {

                    guard let itemPosition = itemPositionMap[itemID] else {

                        continue
                    }
                    self.sections[itemPosition.sectionIndex]
                        .elements[itemPosition.itemRelativeIndex].stateTag = nextStateTag
                }
            }

            mutating func append(sectionIDs: [String], nextStateTag: UUID) {

                let newSections = sectionIDs.lazy.map({ Section(id: $0, stateTag: nextStateTag) })
                self.sections.append(contentsOf: newSections)
            }

            mutating func insert(sectionIDs: [String], before beforeSectionID: String, nextStateTag: UUID) {

                guard let sectionIndex = self.sectionIndex(of: beforeSectionID) else {

                    Internals.abort("Section \"\(beforeSectionID)\" does not exist")
                }
                let newSections = sectionIDs.lazy.map({ Section(id: $0, stateTag: nextStateTag) })
                self.sections.insert(contentsOf: newSections, at: sectionIndex)
            }

            mutating func insert(sectionIDs: [String], after afterSectionID: String, nextStateTag: UUID) {

                guard let beforeIndex = self.sectionIndex(of: afterSectionID) else {

                    Internals.abort("Section \"\(afterSectionID)\" does not exist")
                }
                let sectionIndex = self.sections.index(after: beforeIndex)
                let newSections = sectionIDs.lazy.map({ Section(id: $0, stateTag: nextStateTag) })
                self.sections.insert(contentsOf: newSections, at: sectionIndex)
            }

            mutating func remove(sectionIDs: [String]) {

                for sectionID in sectionIDs {

                    self.remove(sectionID: sectionID)
                }
            }

            mutating func move(sectionID: String, before beforeSectionID: String) {

                guard let removed = self.remove(sectionID: sectionID) else {

                    Internals.abort("Section \"\(sectionID)\" does not exist")
                }
                guard let sectionIndex = self.sectionIndex(of: beforeSectionID) else {

                    Internals.abort("Section \"\(beforeSectionID)\" does not exist")
                }
                self.sections.insert(removed, at: sectionIndex)
            }

            mutating func move(sectionID: String, after afterSectionID: String) {

                guard let removed = self.remove(sectionID: sectionID) else {

                    Internals.abort("Section \"\(sectionID)\" does not exist")
                }
                guard let beforeIndex = self.sectionIndex(of: afterSectionID) else {

                    Internals.abort("Section \"\(afterSectionID)\" does not exist")
                }
                let sectionIndex = self.sections.index(after: beforeIndex)
                self.sections.insert(removed, at: sectionIndex)
            }

            mutating func update<S: Sequence>(sectionIDs: S, nextStateTag: UUID) where S.Element == String {

                for sectionID in sectionIDs {

                    guard let sectionIndex = self.sectionIndex(of: sectionID) else {

                        continue
                    }
                    self.sections[sectionIndex].stateTag = nextStateTag
                }
            }


            // MARK: Private

            private static let zeroUUID: UUID = .init(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))

            private func sectionIndex(of sectionID: String) -> Array<Section>.Index? {

                return self.sections.firstIndex(where: { $0.id == sectionID })
            }

            @discardableResult
            private mutating func remove(itemID: NSManagedObjectID) -> Item? {

                guard let itemPosition = self.itemPositionMap()[itemID] else {

                    return nil
                }
                return self.sections[itemPosition.sectionIndex].elements
                    .remove(at: itemPosition.itemRelativeIndex)
            }

            @discardableResult
            private mutating func remove(sectionID: String) -> Section? {

                guard let sectionIndex = self.sectionIndex(of: sectionID) else {

                    return nil
                }
                return self.sections.remove(at: sectionIndex)
            }

            private func itemPositionMap() -> [NSManagedObjectID: ItemPosition] {

                return self.sections.enumerated().reduce(into: [:]) { result, section in

                    for (itemRelativeIndex, item) in section.element.elements.enumerated() {

                        result[item.id] = ItemPosition(
                            item: item,
                            itemRelativeIndex: itemRelativeIndex,
                            section: section.element,
                            sectionIndex: section.offset
                        )
                    }
                }
            }


            // MARK: - Item

            fileprivate struct Item: Identifiable, Equatable {

                var stateTag: UUID

                init(id: NSManagedObjectID, stateTag: UUID) {

                    self.id = id
                    self.stateTag = stateTag
                }

                var stateID: ItemStateID {

                    return .init(id: self.id, stateTag: self.stateTag)
                }

                func isContentEqual(to source: Item) -> Bool {

                    return self.id == source.id && self.stateTag == source.stateTag
                }

                // MARK: Identifiable

                let id: NSManagedObjectID
            }


            // MARK: - Section

            fileprivate struct Section: Identifiable, Equatable {

                var elements: [Item] = []
                var stateTag: UUID

                init(id: String, items: [Item] = [], stateTag: UUID) {
                    self.id = id
                    self.elements = items
                    self.stateTag = stateTag
                }

                init<S: Sequence>(source: Section, elements: S) where S.Element == Item {

                    self.init(id: source.id, items: Array(elements), stateTag: source.stateTag)
                }

                var stateID: SectionStateID {

                    return .init(id: self.id, stateTag: self.stateTag)
                }

                func isContentEqual(to source: Section) -> Bool {

                    return self.id == source.id && self.stateTag == source.stateTag
                }

                // MARK: Identifiable

                let id: String
            }


            // MARK: - ItemPosition

            fileprivate struct ItemPosition {

                let item: Item
                let itemRelativeIndex: Int
                let section: Section
                let sectionIndex: Int
            }
        }
    }
}


#endif
