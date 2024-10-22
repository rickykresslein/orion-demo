import Cocoa

class URLTextField: NSTextField {
	let lockImageView = NSImageView()
	private var padding: CGFloat = 4

	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		setupTextField()
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		setupTextField()
	}

	private func setupTextField() {
		let cell = URLTextFieldCell(textCell: "")
		self.cell = cell
		self.isEditable = true
		self.isSelectable = true
		self.isBordered = true
		self.isBezeled = true
		self.bezelStyle = .squareBezel
		setupLockIcon()
	}

	private func setupLockIcon() {
		lockImageView.image = NSImage(systemSymbolName: "lock.fill", accessibilityDescription: nil)
		lockImageView.isHidden = true
		addSubview(lockImageView)
	}

	override func layout() {
		super.layout()
		let iconSize = bounds.height - (padding * 2)
		lockImageView.frame = NSRect(x: padding, y: padding, width: iconSize, height: iconSize)
		if let cell = self.cell as? URLTextFieldCell {
			cell.iconWidth = lockImageView.isHidden ? 0 : iconSize
//			cell.alignment = .center
			cell.usesSingleLineMode = true
		}
	}

	func updateLockIcon(for urlString: String) {
		let isHttps = urlString.lowercased().hasPrefix("https://")
		lockImageView.isHidden = !isHttps
		if let cell = self.cell as? URLTextFieldCell {
			cell.iconWidth = isHttps ? (bounds.height - (padding * 2)) : 0
		}
		needsLayout = true
	}
}

class URLTextFieldCell: NSTextFieldCell {
	var iconWidth: CGFloat = 0

	var mIsEditingOrSelecting:Bool = false

	// Center text vertically
	func adjustedFrame(toVerticallyCenterText rect: NSRect) -> NSRect {
		var titleRect = super.titleRect(forBounds: rect)

		let minimumHeight = self.cellSize(forBounds: rect).height + 5
		titleRect.origin.y += (titleRect.height - minimumHeight) / 2
		titleRect.size.height = minimumHeight
		titleRect.origin.x += iconWidth

		return titleRect
	}

	override func edit(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, event: NSEvent?) {
		super.edit(withFrame: adjustedFrame(toVerticallyCenterText: rect), in: controlView, editor: textObj, delegate: delegate, event: event)
	}

	override func select(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, start selStart: Int, length selLength: Int) {
		super.select(withFrame: adjustedFrame(toVerticallyCenterText: rect), in: controlView, editor: textObj, delegate: delegate, start: selStart, length: selLength)
	}

	override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
		super.drawInterior(withFrame: adjustedFrame(toVerticallyCenterText: cellFrame), in: controlView)
	}

	override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
		super.draw(withFrame: cellFrame, in: controlView)
	}
}
