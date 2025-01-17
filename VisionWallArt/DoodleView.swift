//
//  DoodleView.swift
//  VisionWallArt
//
//  Created by Иван Чернокнижников on 22.03.2024.
//

import SwiftUI

struct DoodleView: View {
    
    @Environment(ViewModel.self) private var viewModel
    @Environment(\.dismissWindow) private var dismissWindow
    var body: some View {
        VStack {
            DrawingView()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(20)
                .padding()
            Button("Done") {
                dismissWindow(id: "doodle_canvas")
                viewModel.flowState = .projectingFlying
            }
            Spacer()
        }
    }
}

struct DrawingView: UIViewRepresentable {
    
    func makeUIView(context: Context) -> DrawingUIView {
        let view = DrawingUIView()
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
    }
    
    
}

class DrawingUIView: UIView {
    private var path = UIBezierPath()
    private var strokeWidth: CGFloat = 5.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        path.lineWidth = strokeWidth
        backgroundColor = .clear
    }
    
    override func draw(_ rect: CGRect) {
        UIColor.black.setStroke()
        path.stroke()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        path.move(to: touch.location(in: self))
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        path.addLine(to: touch.location(in: self))
        setNeedsDisplay()
    }
}

#Preview {
    DoodleView()
}
