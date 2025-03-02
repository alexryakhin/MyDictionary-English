//
//  SnackModel.swift
//  PureBite
//
//  Created by Aleksandr Riakhin on 10/7/24.
//
import SwiftUISnackbar
import SwiftUI

struct SnackModel {
    var title: String
    var text: String? = nil
    var style: SnackbarStyle = .default
    var actionText: String? = nil
    var dismissOnTap: Bool = true
    var dismissAfter: Double? = 4
    var extraBottomPadding: CGFloat = 0
    var action: (() -> Void)? = nil
}
