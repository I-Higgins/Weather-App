//
//  CustomViews.swift
//  Weather App
//
//  Created by Isaac Higgins on 29/11/23.
//

import SwiftUI

struct WhiteText: View {
    let text: String
    let size: CGFloat
    
    init(_ text: String, size: CGFloat) {
        self.text = text
        self.size = size
    }
    
    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .medium, design: .default))
            .foregroundStyle(.white)
    }
}
