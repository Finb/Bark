//
//  BKColor.swift
//  Bark
//
//  Created by huangfeng on 2021/10/22.
//  Copyright © 2021 Fin. All rights reserved.
//

import UIKit

class BKColor: NSObject {
    enum grey {
        public static let base = UIColor(named: "grey_base")!
        public static let darken1 = UIColor(named: "grey_darken1")!
        public static let darken2 = UIColor(named: "grey_darken2")!
        public static let darken3 = UIColor(named: "grey_darken3")!
        public static let darken4 = UIColor(named: "grey_darken4")!
        public static let lighten1 = UIColor(named: "grey_lighten1")!
        public static let lighten2 = UIColor(named: "grey_lighten2")!
        public static let lighten3 = UIColor(named: "grey_lighten3")!
        public static let lighten4 = UIColor(named: "grey_lighten4")!
        public static let lighten5 = UIColor(named: "grey_lighten5")!
    }

    enum blue {
        public static let base = UIColor(named: "blue_base")!
        public static let darken1 = UIColor(named: "blue_darken1")!
        public static let darken5 = UIColor(named: "blue_darken5")!
    }

    enum lightBlue {
        public static let darken3 = UIColor(named: "lightBlue_darken3")!
    }

    public static let white = UIColor(named: "white")!
    
    public static let black = UIColor(named: "black")!

    enum background {
        public static let primary = UIColor(named: "background")!
        public static let secondary = UIColor(named: "background_seconday")!
    }

    enum home {
        public static let legacyButton = UIColor(named: "home_legacy_button")!
        public static let legacyBorder = UIColor(named: "home_legacy_border")!
        
        public static let legacyAccentBlue = UIColor(named: "home_accent_blue")!
        public static let legacyAccentTeal = UIColor(named: "home_accent_teal")!
        public static let legacyAccentOrange = UIColor(named: "home_accent_orange")!
        
        public static let codePanel = UIColor(named: "home_code_panel")!
        public static let divider = UIColor(named: "home_divider")!
    }
}
