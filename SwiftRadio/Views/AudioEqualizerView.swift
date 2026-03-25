//
//  AudioEqualizerView.swift
//  SwiftRadio
//

import UIKit

class AudioEqualizerView: UIView {

    private let barCount = 3
    private var barLayers: [CALayer] = []
    private var isAnimating = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupBars()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutBars()
    }

    private func setupBars() {
        for _ in 0..<barCount {
            let bar = CALayer()
            bar.backgroundColor = UIColor.white.cgColor
            layer.addSublayer(bar)
            barLayers.append(bar)
        }
    }

    private func layoutBars() {
        let spacing: CGFloat = 2
        let totalSpacing = spacing * CGFloat(barCount - 1)
        let barWidth = (bounds.width - totalSpacing) / CGFloat(barCount)

        for (i, bar) in barLayers.enumerated() {
            let x = CGFloat(i) * (barWidth + spacing)
            bar.frame = CGRect(x: x, y: bounds.height * 0.5, width: barWidth, height: bounds.height * 0.5)
            bar.cornerRadius = barWidth * 0.25
        }
    }

    func startAnimating() {
        guard !isAnimating else { return }
        isAnimating = true

        for (i, bar) in barLayers.enumerated() {
            let animation = CABasicAnimation(keyPath: "bounds.size.height")
            animation.fromValue = bounds.height * 0.2
            animation.toValue = bounds.height
            animation.duration = 0.4 + Double(i) * 0.15
            animation.autoreverses = true
            animation.repeatCount = .infinity
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            bar.add(animation, forKey: "equalize")

            let posAnimation = CABasicAnimation(keyPath: "position.y")
            posAnimation.fromValue = bounds.height - bounds.height * 0.1
            posAnimation.toValue = bounds.height * 0.5
            posAnimation.duration = animation.duration
            posAnimation.autoreverses = true
            posAnimation.repeatCount = .infinity
            posAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            bar.add(posAnimation, forKey: "position")
        }
    }

    func stopAnimating() {
        guard isAnimating else { return }
        isAnimating = false
        for bar in barLayers {
            bar.removeAllAnimations()
        }
        layoutBars()
    }
}
