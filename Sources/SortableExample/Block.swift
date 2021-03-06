//
//  SwiftUIView.swift
//  
//
//  Created by Damiaan on 06/07/2020.
//

import SwiftUI

public struct Block: View {
	let number: Int
	let color: Color

	public init(number: Int, color: Color) {
		self.number = number
		self.color = color
	}

	public var body: some View {
		Text("\(number)")
			.font(.system(size: 25))
			.fixedSize()
			.padding()
			.background(color)
			.foregroundColor(.white)
			.cornerRadius(4)
	}
}

struct Block_Previews: PreviewProvider {
    static var previews: some View {
		Block(number: 8, color: .orange)
    }
}
