//
//  main.swift
//  Reynard
//
//  Created by Minh Ton on 1/2/26.
//

import Foundation
import GeckoView
import UIKit

let userDataMigrationReport = UserDataMigration.shared.run()
if !userDataMigrationReport.requiresBlockingRecovery {
    JITController.shared.start()
}
GeckoRuntime.main(argc: CommandLine.argc, argv: CommandLine.unsafeArgv)
