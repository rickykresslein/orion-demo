import Cocoa

class TabBackgroundView: NSView {
	private var visualEffectView: NSVisualEffectView!

	var isActiveTab: Bool = false {
		didSet {
			updateAppearance()
		}
	}

	var isHovered: Bool = false {
		didSet {
			updateAppearance()
		}
	}

	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)

		wantsLayer = true
		setupShadow()

		visualEffectView = NSVisualEffectView()
		visualEffectView.material = .contentBackground
		visualEffectView.state = .active
		visualEffectView.blendingMode = .withinWindow
		visualEffectView.isEmphasized = true
		visualEffectView.wantsLayer = true
		visualEffectView.layer?.cornerRadius = 4
		visualEffectView.layer?.cornerCurve = .continuous

		visualEffectView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(visualEffectView)

		NSLayoutConstraint.activate([
			visualEffectView.topAnchor.constraint(equalTo: topAnchor),
			visualEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
			visualEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),
			visualEffectView.bottomAnchor.constraint(equalTo: bottomAnchor)
		])
	}

	private func setupShadow() {
		layer?.shadowColor = NSColor.black.withAlphaComponent(0.6).cgColor
		layer?.shadowOffset = .zero
		layer?.shadowRadius = 5
		layer?.masksToBounds = false
	}

	private func updateAppearance() {
		if isActiveTab {
			visualEffectView.isHidden = false
			visualEffectView.material = .contentBackground
			visualEffectView.layer?.backgroundColor = nil
			layer?.shadowOpacity = 0.3
		} else if isHovered {
			visualEffectView.isHidden = false
			visualEffectView.material = .menu
			visualEffectView.layer?.backgroundColor = NSColor.gray.cgColor
			layer?.shadowOpacity = 0
		} else {
			visualEffectView.isHidden = true
			visualEffectView.layer?.backgroundColor = nil
			layer?.shadowOpacity = 0
		}
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidChangeEffectiveAppearance() {
		super.viewDidChangeEffectiveAppearance()
		setupShadow()
		updateAppearance()
	}
}
