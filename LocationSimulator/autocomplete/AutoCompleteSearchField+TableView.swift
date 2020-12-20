//
//  AutoCompleteTextField+TableView.swift
//  LocationSimulator
//
//  Created by fancymax on 15/12/12.
//  Modified by David Klopp on 11/08/19.
//  Copyright © 2015年 fancy. All rights reserved.
//  Copyright © 2019 David Klopp. All rights reserved.
//

import Foundation
import AppKit

// MARK: - NSTableCellView
class AutoCompleteTableCellView: NSTableCellView {
    var match: Match?

    func setHighlighted(_ highlighted: Bool) {
        guard let match = match, let attrStr = self.textField!.attributedStringValue as NSAttributedString? else {
            return
        }

        // change the required attributes
        let isDarkMode = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") != nil
        let muAttrStr = NSMutableAttributedString(attributedString: attrStr)
        let end: Int = match.text.count + match.detail.count
        muAttrStr.removeAttribute(NSAttributedString.Key.foregroundColor, range: NSRange(location: 0, length: end))
        if !highlighted {
            muAttrStr.addAttribute(NSAttributedString.Key.foregroundColor,
                                   value: isDarkMode ? NSColor.white : NSColor.black,
                                   range: NSRange(location: 0, length: match.text.count))
            muAttrStr.addAttribute(NSAttributedString.Key.foregroundColor,
                                   value: NSColor.gray,
                                   range: NSRange(location: match.text.count+1, length: match.detail.count))
        } else {
            muAttrStr.addAttribute(NSAttributedString.Key.foregroundColor,
                                   value: NSColor.white,
                                   range: NSRange(location: 0, length: match.text.count))
            muAttrStr.addAttribute(NSAttributedString.Key.foregroundColor,
                                   value: NSColor.white,
                                   range: NSRange(location: match.text.count+1, length: match.detail.count))
        }
        self.textField!.attributedStringValue = muAttrStr
    }
}

// MARK: - NSTableRowView
class AutoCompleteTableRowView: NSTableRowView {

    override func drawSelection(in dirtyRect: NSRect) {
        if self.selectionHighlightStyle != .none {
            let selectionRect = self.bounds.insetBy(dx: 0.5, dy: 0.5)
            if #available(OSX 10.14, *) {
                NSColor.selectedContentBackgroundColor.setStroke()
                NSColor.selectedContentBackgroundColor.setFill()
            } else {
                NSColor.alternateSelectedControlColor.setStroke()
                NSColor.alternateSelectedControlColor.setFill()
            }
            let selectionPath = NSBezierPath(roundedRect: selectionRect, xRadius: 0.0, yRadius: 0.0)
            selectionPath.fill()
            selectionPath.stroke()
        }
    }

    override func drawBackground(in dirtyRect: NSRect) {
        // update the textfields inside the tableview selection color
        if self.selectionHighlightStyle != .none,
            let cellView = self.view(atColumn: 0) as? AutoCompleteTableCellView {
            cellView.setHighlighted(self.isSelected)
        }
    }

    override var interiorBackgroundStyle: NSView.BackgroundStyle {
        return self.isSelected ? NSView.BackgroundStyle.emphasized : NSView.BackgroundStyle.normal
    }
}

// MARK: - NSTableViewDelegate
extension AutoCompleteSearchField: NSTableViewDelegate {

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        return AutoCompleteTableRowView()
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "cell"),
                                          owner: self) as? AutoCompleteTableCellView

        if cellView == nil {
            let cellFrame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: tableView.rowHeight)
            cellView = AutoCompleteTableCellView(frame: cellFrame)
            cellView?.identifier = NSUserInterfaceItemIdentifier(rawValue: "cell")

            let textField = NSTextField(frame: .zero)
            textField.autoresizingMask = [.height, .width]
            textField.isBezeled = false
            textField.drawsBackground = false
            textField.isEditable = false
            textField.isSelectable = false
            textField.maximumNumberOfLines = 2

            cellView?.textField = textField
            cellView?.addSubview(textField)
        }

        let match = matches![row]

        // change the attributed string
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingTail
        let str = match.text + (match.detail.isEmpty ? "" : ("\n" + match.detail))
        let mutableAttriStr = NSMutableAttributedString(string: str)

        mutableAttriStr.addAttribute(NSAttributedString.Key.paragraphStyle,
                                     value: paragraphStyle,
                                     range: NSRange(location: 0, length: match.text.count))
        mutableAttriStr.addAttribute(NSAttributedString.Key.font,
                                     value: NSFont.systemFont(ofSize: NSFont.systemFontSize),
                                     range: NSRange(location: 0, length: match.text.count))
        mutableAttriStr.addAttribute(NSAttributedString.Key.font,
                                     value: NSFont.systemFont(ofSize: NSFont.labelFontSize),
                                     range: NSRange(location: match.text.count + 1, length: match.detail.count))
        mutableAttriStr.addAttribute(NSAttributedString.Key.paragraphStyle,
                                     value: paragraphStyle,
                                     range: NSRange(location: match.text.count + 1, length: match.detail.count))

        // Center the textfield inside the view
        let textHeight = mutableAttriStr.size().height
        var frame = CGRect(x: 0, y: 0, width: self.frame.width, height: textHeight)
        frame.origin.y = (CGFloat(tableView.rowHeight)-textHeight)/2.0
        cellView!.textField!.frame = frame

        cellView!.textField!.attributedStringValue = mutableAttriStr
        cellView!.match = match

        return cellView
    }
}

// MARK: - NSTableViewDataSource

extension AutoCompleteSearchField: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        if self.matches == nil {
            return 0
        }
        return self.matches!.count
    }
}
