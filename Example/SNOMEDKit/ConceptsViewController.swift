//
//  ViewController.swift
//  SNOMEDKit
//
//  Created by Francis Li on 12/16/2021.
//  Copyright (c) 2021 Francis Li. All rights reserved.
//

import MobileCoreServices
import UIKit
import RealmSwift
import SNOMEDKit

class ConceptsViewController: UITableViewController, UIDocumentPickerDelegate {
    var results: Results<SCTConcept>?
    var notificationToken: NotificationToken?

    deinit {
        notificationToken?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        performQuery()
    }

    func performQuery() {
        notificationToken?.invalidate()
        notificationToken = nil
        let realm = SCTRealm.open()
        results = realm.objects(SCTConcept.self).sorted(by: [
            SortDescriptor(keyPath: "name", ascending: true)
        ])
        if realm.configuration.readOnly {
            tableView.reloadData()
        } else {
            notificationToken = results?.observe { [weak self] (changes) in
                self?.didObserveRealmChanges(changes)
            }
        }
    }

    func didObserveRealmChanges(_ changes: RealmCollectionChange<Results<SCTConcept>>) {
        switch changes {
        case .initial:
            tableView.reloadData()
        case .update(_, let deletions, let insertions, let modifications):
            tableView.beginUpdates()
            tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
            tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
            tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .automatic)
            tableView.endUpdates()
        case .error(let error):
            print(error)
        }
    }

    func showSpinner() {
        for item in navigationItem.leftBarButtonItems ?? [] {
            item.isEnabled = false
        }
        for item in navigationItem.rightBarButtonItems ?? [] {
            item.isEnabled = false
        }
        var spinner: UIActivityIndicatorView
        if #available(iOS 13.0, *) {
            spinner = UIActivityIndicatorView(activityIndicatorStyle: .medium)
        } else {
            spinner = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        }
        spinner.startAnimating()
        navigationItem.leftBarButtonItems?.append(UIBarButtonItem(customView: spinner))
    }

    func hideSpinner() {
        _ = navigationItem.leftBarButtonItems?.popLast()
        for item in navigationItem.leftBarButtonItems ?? [] {
            item.isEnabled = true
        }
        for item in navigationItem.rightBarButtonItems ?? [] {
            item.isEnabled = true
        }
    }

    @IBAction func importPressed() {
        var picker: UIDocumentPickerViewController!
        if #available(iOS 14, *) {
            picker = UIDocumentPickerViewController(forOpeningContentTypes: [.text])
        } else {
            picker = UIDocumentPickerViewController(documentTypes: [kUTTypeText as String], in: .open)
        }
        picker.delegate = self
        present(picker, animated: true)
    }

    @IBAction func openPressed() {
        var picker: UIDocumentPickerViewController!
        if #available(iOS 14, *) {
            picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
        } else {
            picker = UIDocumentPickerViewController(documentTypes: [kUTTypeItem as String], in: .open)
        }
        picker.delegate = self
        present(picker, animated: true)
    }

    @IBAction func exportPressed() {
        showSpinner()
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let realm = SCTRealm.open()
            let fileManager = FileManager.default
            let documentDirectory = try? fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let url = documentDirectory?.appendingPathComponent( "SNOMED.realm")
            if let url = url {
                if fileManager.fileExists(atPath: url.path) {
                    try? fileManager.removeItem(at: url)
                }
                do {
                    try realm.writeCopy(toFile: url, encryptionKey: nil)
                    DispatchQueue.main.async { [weak self] in
                        let picker = UIDocumentPickerViewController(url: url, in: .moveToService)
                        if #available(iOS 13.0, *) {
                            picker.shouldShowFileExtensions = true
                        }
                        self?.present(picker, animated: true)
                    }
                } catch {
                    // noop
                }
            }
            DispatchQueue.main.async { [weak self] in
                self?.hideSpinner()
            }
        }
    }

    func openRealm(from url: URL) {
        showSpinner()
        SCTRealm.configure(url: url, isReadOnly: true)
        performQuery()
        hideSpinner()
    }

    // MARK: - UIDocumentPickerDelegate

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let url = urls[0]
        if url.pathExtension.lowercased() == "txt" {
            showSpinner()
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let realm = SCTRealm.open()
                if url.path.contains("SNOMEDCT_CORE_SUBSET_") {
                    url.read { (line, _) in
                        let cols = line.split(separator: "|", omittingEmptySubsequences: false)
                        if String(cols[7]) == "False" {
                            let concept = SCTConcept()
                            concept.id = String(cols[0])
                            var name = String(cols[1])
                            if name.hasPrefix("'") && name.hasSuffix("'") {
                                name = String(name[name.index(name.startIndex, offsetBy: 1)...name.index(name.endIndex, offsetBy: -2)])
                                name = name.replacingOccurrences(of: "''", with: "'")
                            }
                            concept.name = name
                            try! realm.write {
                                realm.add(concept, update: .modified)
                            }
                        }
                    }
                } else if url.path.contains("sct2_Description_") {
                    // pull in the procedure and regime/therapy concept FSNs
                    url.read { (line, _) in
                        let cols = line.split(separator: "\t", omittingEmptySubsequences: false)
                        if String(cols[2]) == "1", String(cols[6]) == "900000000000003001" {
                            let concept = SCTConcept()
                            concept.id = String(cols[4])
                            let name = String(cols[7])
                            if name.hasSuffix(" (procedure)") || name.hasSuffix(" (regime/therapy)") {
                                concept.name = name
                                try! realm.write {
                                    realm.add(concept, update: .modified)
                                }
                            }
                        }
                    }
                    // check against the concepts file for deactivation and remove
                    let newUrl = URL(fileURLWithPath: url.path.replacingOccurrences(of: "sct2_Description_", with: "sct2_Concept_").replacingOccurrences(of: "-en_", with: "_"))
                    newUrl.read { (line, _) in
                        let cols = line.split(separator: "\t", omittingEmptySubsequences: false)
                        if String(cols[2]) == "0" {
                            let id = String(cols[0])
                            if let concept = realm.object(ofType: SCTConcept.self, forPrimaryKey: id) {
                                try! realm.write {
                                    realm.delete(concept)
                                }
                            }
                        }
                    }
                }
                DispatchQueue.main.async { [weak self] in
                    self?.hideSpinner()
                }
            }
        } else if url.pathExtension == "realm" {
            openRealm(from: url)
        }
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Concept", for: indexPath)
        if let concept = results?[indexPath.row] {
            cell.textLabel?.text = "\(concept.id): \(concept.name)"
        }
        return cell
    }
}
