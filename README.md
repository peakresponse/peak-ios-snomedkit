# SNOMEDKit

SNOMEDKit is a library for embedding SNOMED codes as a Realm database. The example application included with the library can be run on a Mac OS desktop to read SNOMED code files and generate a compacted Realm database that can be bundled into an iOS app.

## Generate a database file

1. Download SNOMED source files from UMLS (latest US edition as of time of writing):

  https://www.nlm.nih.gov/healthit/snomedct/us_edition.html

  https://www.nlm.nih.gov/research/umls/Snomed/core_subset.html

2. To run the example project, clone the repo, and run `pod install` from the Example directory first.

3. Then, open the `Example/SNOMEDKit.xcworkspace` in Xcode. Change the build target to `My Mac` and run.

4. Click on `Import` in the toolbar. Currently, it is supported to import the SNOMED CORE Problem List subset (`SNOMEDCT_CORE_SUBSET_YYYYMM.txt`) in its entirety and/or a subset (Procedure, Regime/Therapy) of the full SNOMED edition release description file (`sct2_Description_{Full|Snapshot}-en_US1000124_YYYYMMDD.txt`).

5. Wait as the file is parsed and imported into a Realm database, until the spinner disappears and the Export
option is enabled in the toolbar.

6. Click on Export, and select a destination for the Realm database file.

## Installation

1. Include ICD10Kit in your iOS app project using Swift Package Manger, referencing this repository:

  https://github.com/peakresponse/peak-ios-icd10kit

2. Add the exported Realm database file generated previously (i.e. `SNOMED.realm`) to your iOS app project.

3. Initialize the library with the Realm file, for example in your AppDelegate didFinishLaunchingWithOptions function.

  ```
  import SNOMEDKit
  ...
  class AppDelegate: UIResponder, UIApplicationDelegate {
      ...
      func application(_ application: UIApplication,
                       didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
          ...
          SCTRealm.configure(url: Bundle.main.url(forResource: "SNOMED", withExtension: "realm"), isReadOnly: true)
      }
      ...
  }
  ```

4. Use as with any Realm database model. For example, in a table view controller (see https://docs.mongodb.com/realm/sdk/swift/examples/react-to-changes/#register-a-collection-change-listener):

  ```
  import SNOMEDKit
  ...
  class CodesViewController: UITableViewController {    
      var results: Results<SCTConcept>?
      ...
      func viewDidLoad() {
        ...
        results = SCTRealm.open().objects(SCTConcept.self).sorted(byKeyPath: "name", ascending: true)
      }
      ...      
  }
  ```

## Author

Francis Li, francis@peakresponse.net

## License

SNOMEDKit  
Copyright &copy; 2025 Peak Response Inc.

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
