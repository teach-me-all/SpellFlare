//
//  ShareSheetView.swift
//  spelling-bee iOS App
//
//  SwiftUI wrapper for UIActivityViewController to present share sheets.
//

import SwiftUI
import UIKit

struct ShareSheetView: UIViewControllerRepresentable {
    let activityItems: [Any]
    var onDismiss: (() -> Void)?

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        controller.completionWithItemsHandler = { _, _, _, _ in
            onDismiss?()
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Share Sheet Data (for presenting from AppState)

struct ShareSheetData: Identifiable {
    let id = UUID()
    let activityItems: [Any]
}
