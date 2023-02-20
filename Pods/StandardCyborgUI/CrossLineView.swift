class CrossLineView: UIView {
    override func draw(_ rect: CGRect) {
        // Set the stroke color and line width
        UIColor.red.setStroke()
        let lineWidth: CGFloat = 3.0
        
        // Create a path for the vertical line
        let path = UIBezierPath()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.lineWidth = lineWidth
        path.stroke()
        
        // Create a path for the horizontal line
        let path2 = UIBezierPath()
        path2.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path2.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path2.lineWidth = lineWidth
        path2.stroke()
    }
}
