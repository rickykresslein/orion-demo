import Cocoa

class TabBackgroundView: NSView {
	private var visualEffectView: NSVisualEffectView!

	var isActiveTab: Bool = false {
		didSet {
			visualEffectView.isHidden = !isActiveTab
			updateShadow()
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

	private func updateShadow() {
		layer?.shadowOpacity = isActiveTab ? 0.3 : 0
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidChangeEffectiveAppearance() {
		super.viewDidChangeEffectiveAppearance()
		setupShadow()
		updateShadow()
	}
}
