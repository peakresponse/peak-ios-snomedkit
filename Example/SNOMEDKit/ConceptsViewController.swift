//
//  ViewController.swift
//  SNOMEDKit
//
//  Created by Francis Li on 12/16/2021.
//  Copyright (c) 2021 Francis Li. All rights reserved.
//

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
        for item in navigationItem.rightBarButtonItems ?? [] {
            item.isEnabled = true
        }
    }

    @IBAction func importPressed() {
        let picker = UIDocumentPickerViewController(documentTypes: [String(kUTTypeText)], in: .open)
        picker.delegate = self
        present(picker, animated: true)
    }

    @IBAction func openPressed() {
        let picker = UIDocumentPickerViewController(documentTypes: [String(kUTTypeItem)], in: .open)
        picker.delegate = self
        present(picker, animated: true)
    }

    @IBAction func exportPressed() {
        showSpinner()
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let realm = SCTRealm.open()
            let documentDirectory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask,
                                                                 appropriateFor: nil, create: false)
            let url = documentDirectory?.appendingPathComponent( "snomed.realm")
            if let url = url {
                do {
                    try realm.writeCopy(toFile: url, encryptionKey: nil)
                    DispatchQueue.main.async { [weak self] in
                        let picker = UIDocumentPickerViewController(url: url, in: .moveToService)
                        picker.shouldShowFileExtensions = true
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
