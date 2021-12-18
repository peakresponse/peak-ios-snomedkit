//
//  SCTConcept.swift
//  SNOMEDKit
//
//  Created by Francis Li on 12/16/21.
//

import RealmSwift

open class SCTConcept: Object {
    @Persisted(primaryKey: true) open var id: String
    @Persisted open var name: String
}
