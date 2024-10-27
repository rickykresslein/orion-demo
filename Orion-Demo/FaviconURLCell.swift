import AppKit

class FaviconURLCell: NSTextFieldCell {
	var favicon: NSImage?

	override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
		let textRect = adjustedFrame(toVerticallyCenterText: cellFrame)
		super.drawInterior(withFrame: textRect, in: controlView)

		if let favicon = favicon {
			let imageSize = NSSize(width: 16, height: 16)
			let imageRect = NSRect(x: cellFrame.origin.x, y: cellFrame.origin.y + (cellFrame.size.height - imageSize.height) / 2, width: imageSize.width, height: imageSize.height)
			favicon.draw(in: imageRect)
		}
	}

	override func select(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, start selStart: Int, length selLength: Int) {
		let textRect = adjustedFrame(toVerticallyCenterText: rect)
		super.select(withFrame: textRect, in: controlView, editor: textObj, delegate: delegate, start: selStart, length: selLength)
	}

	override func drawFocusRingMask(withFrame cellFrame: NSRect, in controlView: NSView) {
		let textRect = adjustedFrame(toVerticallyCenterText: cellFrame)
		super.drawFocusRingMask(withFrame: textRect, in: controlView)
	}

	override func focusRingMaskBounds(forFrame cellFrame: NSRect, in controlView: NSView) -> NSRect {
		return adjustedFrame(toVerticallyCenterText: cellFrame)
	}

	private func adjustedFrame(toVerticallyCenterText rect: NSRect) -> NSRect {
		var titleRect = super.titleRect(forBounds: rect)
		titleRect.origin.x += (favicon != nil) ? 20 : 0
		titleRect.size.width -= (favicon != nil) ? 20 : 0
		return titleRect
	}
}
