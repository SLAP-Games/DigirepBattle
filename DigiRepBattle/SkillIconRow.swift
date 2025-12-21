import SwiftUI

struct SkillIconRow: View {
    let skills: [CreatureSkill]
    let iconSize: CGFloat
    var overrideNames: [String]? = nil

    var body: some View {
        let baseNames = overrideNames ?? skills.paddedSkillImageNames(maxCount: 2)
        let names = baseNames.map { assetName in
            UIImage(named: assetName) == nil ? CreatureSkill.placeholderImageName : assetName
        }

        HStack(spacing: iconSize * 0.15) {
            ForEach(Array(names.enumerated()), id: \.0) { _, name in
                Image(name)
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconSize, height: iconSize)
                    .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)
            }
        }
        .allowsHitTesting(false)
    }
}
