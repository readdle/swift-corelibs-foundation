//
// Created by Andriy Druk on 08.01.2020.
//

import Foundation

public final class AvatarImageQualifier {

    public static func chooseBestImage(imageInfos: Array<ImageInfo>) -> ImageInfo? {
        let filterBad = imageInfos.filter {
            return $0.width > 0 && $0.height > 0
        }

        // Filter non square
        var filteredNonSquare = filterBad.filter {
            return $0.checkAspectRatio()
        }

        // If all images are non-square, choose best from them
        if filteredNonSquare.count == 0 {
            filteredNonSquare = filterBad
        }

        // Sort by area
        let sortedByArea = filteredNonSquare.sorted { r1, r2 -> Bool in
            let area1 = r1.width * r1.height
            let area2 = r2.width * r2.height
            return area1 < area2
        }

        // prefer result with bigger area
        return sortedByArea.last
    }
}
