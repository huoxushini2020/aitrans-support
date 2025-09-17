import Cocoa
import Markdown

class CenteredTextView: NSView {
    private var textField: NSTextField!
    private var initialLocation: NSPoint = NSPoint.zero
    private var initialWindowOrigin: NSPoint = NSPoint.zero
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        // 创建NSTextField
        textField = NSTextField(frame: bounds)
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        // 配置文本字段属性
        textField.isEditable = false
        textField.isSelectable = true
        textField.isBordered = false
        textField.backgroundColor = NSColor.clear
        textField.drawsBackground = false
        
        // 设置字体和颜色 - 使用更美观专业的字体
        textField.font = createProfessionalFont()
        textField.textColor = NSColor.systemBlue
        
        // 关键：设置垂直和水平对齐 - 智能单行/多行显示
        textField.alignment = .center
        textField.cell?.wraps = true  // 启用换行（但通过宽度控制）
        textField.cell?.isScrollable = false  // 禁用滚动
        textField.maximumNumberOfLines = 0  // 允许多行显示
        
        // 设置智能换行模式：只有在宽度限制时才换行
        if let cell = textField.cell as? NSTextFieldCell {
            cell.usesSingleLineMode = false  // 禁用单行模式
            cell.wraps = true  // 启用换行
            cell.isScrollable = false  // 禁用滚动
            cell.lineBreakMode = .byWordWrapping  // 按单词换行
            cell.truncatesLastVisibleLine = false  // 禁用最后一行截断
        }
        
        // 确保文本字段能够正确显示富文本
        textField.allowsEditingTextAttributes = false
        
        // 禁用文本字段的交互功能，让鼠标事件传递给父视图
        textField.isEditable = false
        textField.isSelectable = false
        textField.allowsEditingTextAttributes = false
        
        // 减少NSTextField的内部边距
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.focusRingType = .none
        
        addSubview(textField)
        
        // 设置约束，最小化上下边距，减少左右边距避免文本截断
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),  // 从8减少到4
            textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),  // 从-8减少到-4
            textField.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2)
        ])
    }
    
    // MARK: - 鼠标拖拽支持
    
    override func mouseDown(with event: NSEvent) {
        // 记录初始点击位置和窗口位置
        initialLocation = NSEvent.mouseLocation  // 使用屏幕坐标
        if let window = self.window {
            initialWindowOrigin = window.frame.origin
        }
        super.mouseDown(with: event)
    }
    
    override func mouseDragged(with event: NSEvent) {
        // 获取当前屏幕鼠标位置
        let currentLocation = NSEvent.mouseLocation
        
        // 计算偏移量
        let deltaX = currentLocation.x - initialLocation.x
        let deltaY = currentLocation.y - initialLocation.y
        
        
        // 计算新的窗口位置
        if let window = self.window {
            let newOrigin = NSPoint(
                x: initialWindowOrigin.x + deltaX,
                y: initialWindowOrigin.y + deltaY
            )
            window.setFrameOrigin(newOrigin)
        }
        
        super.mouseDragged(with: event)
    }
    
    // 确保视图可以接收鼠标事件
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
    
    // 确保视图在鼠标事件响应链中
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    func loadText(_ text: String) {
        
        // 渲染Markdown为富文本
        let attributedString = renderMarkdown(text)
        
        // 设置富文本内容
        textField.attributedStringValue = attributedString
        
        
        // 强制刷新视图和布局
        textField.needsDisplay = true
        textField.needsLayout = true
        needsDisplay = true
        needsLayout = true
        
        // 确保文本字段正确显示
        DispatchQueue.main.async { [weak self] in
            self?.textField.needsDisplay = true
            self?.needsDisplay = true
        }
    }
    
    // MARK: - 获取当前文本
    func getCurrentText() -> String? {
        let currentText = textField.stringValue
        return currentText.isEmpty ? nil : currentText
    }
    
    private func renderMarkdown(_ markdownText: String) -> NSAttributedString {
        // 简化实现：直接返回普通文本，不使用复杂的Markdown渲染
        let baseFont = createProfessionalFont()
        let baseColor = NSColor.systemBlue
        
        // 智能对齐：根据文本长度决定对齐方式
        let isMultiLine = shouldUseMultiLineAlignment(markdownText)
        let alignment: NSTextAlignment = isMultiLine ? .left : .center
        
        // 创建优化的段落样式，确保文本正确渲染
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.lineBreakMode = .byWordWrapping  // 支持换行显示
        paragraphStyle.lineSpacing = 0  // 移除行间距，避免空行
        paragraphStyle.paragraphSpacing = 0  // 段落间距为0
        paragraphStyle.paragraphSpacingBefore = 0  // 段落前间距为0
        paragraphStyle.lineHeightMultiple = 1.0  // 行高倍数
        paragraphStyle.maximumLineHeight = 0  // 最大行高
        paragraphStyle.minimumLineHeight = 0  // 最小行高
        
        let attributedString = NSAttributedString(
            string: markdownText,
            attributes: [
                NSAttributedString.Key.font: baseFont,
                NSAttributedString.Key.foregroundColor: baseColor,
                NSAttributedString.Key.paragraphStyle: paragraphStyle,
                NSAttributedString.Key.kern: 0  // 字符间距
            ]
        )
        
        return attributedString
    }
    
    /// 判断是否应该使用多行对齐（左对齐）
    private func shouldUseMultiLineAlignment(_ text: String) -> Bool {
        // 如果没有文本内容，使用居中对齐
        guard !text.isEmpty else {
            return false
        }
        
        // 使用当前字体创建临时富文本来计算宽度
        let baseFont = createProfessionalFont()
        let baseColor = NSColor.systemBlue
        
        // 创建临时段落样式（居中对齐）
        let tempParagraphStyle = NSMutableParagraphStyle()
        tempParagraphStyle.alignment = .center
        tempParagraphStyle.lineBreakMode = .byWordWrapping
        tempParagraphStyle.lineSpacing = 0
        tempParagraphStyle.paragraphSpacing = 0
        tempParagraphStyle.paragraphSpacingBefore = 0
        
        let tempAttributedString = NSAttributedString(
            string: text,
            attributes: [
                NSAttributedString.Key.font: baseFont,
                NSAttributedString.Key.foregroundColor: baseColor,
                NSAttributedString.Key.paragraphStyle: tempParagraphStyle,
                NSAttributedString.Key.kern: 0
            ]
        )
        
        // 使用更精确的文本尺寸计算
        let singleLineTextSize = tempAttributedString.boundingRect(
            with: NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading, .usesDeviceMetrics]
        ).size
        
        // 计算单行模式需要的总宽度 - 使用与fittingSize相同的边距计算
        let viewInternalPadding: CGFloat = 6  // 3 * 2 (左右各3px)
        let textFieldInternalPadding: CGFloat = 6  // NSTextField自身的内部文本边距
        let safetyMargin: CGFloat = 20  // 增加安全边距
        let totalHorizontalPadding = viewInternalPadding + textFieldInternalPadding + safetyMargin
        let singleLineRequiredWidth = singleLineTextSize.width + totalHorizontalPadding
        
        // 判断是否超出最大宽度限制
        let maxWidth: CGFloat = 1024
        let isMultiLine = singleLineRequiredWidth > maxWidth
        
        
        return isMultiLine
    }
    
    func getText() -> String {
        return textField.stringValue
    }
    
    func fittingSize() -> NSSize {
        // 获取文本的富文本内容
        let attributedString = textField.attributedStringValue
        
        // 如果没有文本内容，返回零尺寸（不显示面板）
        guard attributedString.length > 0 else {
            return NSSize(width: 0, height: 0)
        }
        
        // 优化的边距计算 - 增加最大宽度限制，确保能显示所有字符
        let maxWidth: CGFloat = 1600         // 进一步增加最大宽度限制，确保长文本能完全显示
        let minWidth: CGFloat = 0            // 最小宽度限制（允许为0，完全隐藏）
        let minHeight: CGFloat = 20          // 最小高度保证
        
        // 减少边距，避免文本截断
        let viewInternalPadding: CGFloat = 6  // 3 * 2 (左右各3px)
        let textFieldInternalPadding: CGFloat = 6  // NSTextField内部边距
        let safetyMargin: CGFloat = 80  // 大幅增加安全边距，防止截断
        
        // 总的水平边距
        let totalHorizontalPadding = viewInternalPadding + textFieldInternalPadding + safetyMargin
        
        // 垂直边距：上下约束边距
        let totalVerticalPadding: CGFloat = 4  // 2 * 2 (上下各2px)
        
        
        // 使用更精确的文本尺寸计算
        let singleLineTextSize = attributedString.boundingRect(
            with: NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading, .usesDeviceMetrics]
        ).size
        
        // 计算单行模式需要的总宽度：文本宽度 + 所有边距
        let singleLineRequiredWidth = singleLineTextSize.width + totalHorizontalPadding
        
        // 判断是否在有效宽度范围内可以保持单行
        let canFitInSingleLine = singleLineRequiredWidth <= maxWidth
        
        let finalTextSize: NSSize
        let contentWidth: CGFloat
        
        if canFitInSingleLine {
            // 可以保持单行：使用自然宽度，但确保不小于最小宽度
            contentWidth = max(minWidth, singleLineRequiredWidth)
            finalTextSize = singleLineTextSize
            
            // 为单行模式设置更宽松的宽度，确保文本不被截断
            let extraSafetyMargin: CGFloat = 200  // 大幅增加安全边距，确保长文本不被截断
            let textFieldWidth = singleLineTextSize.width + textFieldInternalPadding + extraSafetyMargin
            textField.preferredMaxLayoutWidth = textFieldWidth
            
        } else {
            // 必须换行：使用最大宽度，重新计算多行文本尺寸
            contentWidth = maxWidth
            let availableTextWidth = maxWidth - totalHorizontalPadding
            
            // 使用更精确的多行文本尺寸计算
            finalTextSize = attributedString.boundingRect(
                with: NSSize(width: availableTextWidth, height: CGFloat.greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading, .usesDeviceMetrics]
            ).size
            
            // 为多行模式设置更宽松的宽度，确保文本不被截断
            let extraSafetyMargin: CGFloat = 200  // 大幅增加安全边距，确保长文本不被截断
            textField.preferredMaxLayoutWidth = availableTextWidth + extraSafetyMargin
            
        }
        
        // 计算最终高度：文本高度 + 垂直边距
        let contentHeight = max(minHeight, finalTextSize.height + totalVerticalPadding)
        
        
        return NSSize(width: contentWidth, height: contentHeight)
    }
    
    // MARK: - 字体优化
    
    /// 创建专业美观的字体
    /// - Returns: 优化后的NSFont
    private func createProfessionalFont() -> NSFont {
        let fontSize: CGFloat = 18
        
        // 尝试使用系统推荐的专业字体，按优先级排序（粗体版本）
        let fontCandidates = [
            // SF Pro Display Bold - Apple 设计的现代专业字体粗体
            NSFont(name: "SF Pro Display Bold", size: fontSize),
            // SF Pro Text Bold - 适合正文显示的字体粗体
            NSFont(name: "SF Pro Text Bold", size: fontSize),
            // Helvetica Neue Bold - 经典专业字体粗体
            NSFont(name: "Helvetica Neue Bold", size: fontSize),
            // Avenir Next Bold - 现代几何字体粗体
            NSFont(name: "Avenir Next Bold", size: fontSize),
            // 系统字体作为备选（粗体）
            NSFont.systemFont(ofSize: fontSize, weight: .bold)
        ]
        
        // 选择第一个可用的字体
        for candidate in fontCandidates {
            if let font = candidate {
                return font
            }
        }
        
        // 如果都不可用，返回系统默认字体
        return NSFont.systemFont(ofSize: fontSize, weight: .medium)
    }
}

// MARK: - 复用SimpleTextView的Markdown渲染器（不重复定义）
