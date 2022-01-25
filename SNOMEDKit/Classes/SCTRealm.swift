//
//  SCTRealm.swift
//  SNOMEDKit
//
//  Created by Francis Li on 12/16/21.
//

import RealmSwift

open class SCTRealm {
    public static var main: Realm!
    public static var mainURL: URL?
    public static var mainMemoryIdentifier: String? = "snomed.realm"
    public static var isMainReadOnly = false
    
    public static func configure(url: URL?, isReadOnly: Bool) {
        SCTRealm.main = nil
        SCTRealm.mainURL = url
        SCTRealm.isMainReadOnly = isReadOnly
        SCTRealm.mainMemoryIdentifier = url != nil ? nil : "snomed.realm"
    }

    public static func open() -> Realm {
        if Thread.current.isMainThread && SCTRealm.main != nil {
            if !SCTRealm.main.configuration.readOnly {
                SCTRealm.main.refresh()
            }
            return SCTRealm.main
        }
        let config = Realm.Configuration(fileURL: mainURL,
                                         inMemoryIdentifier: SCTRealm.mainMemoryIdentifier,
                                         readOnly: SCTRealm.isMainReadOnly,
                                         objectTypes: [SCTConcept.self])
        let realm = try! Realm(configuration: config)
        if Thread.current.isMainThread {
            SCTRealm.main = realm
        }
        return realm
    }
}
