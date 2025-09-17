import Cocoa
import Markdown

class SimpleTextView: NSView {
    private var textView: NSTextView!
    private var scrollView: NSScrollView!
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        // 创建滚动视图
        scrollView = NSScrollView(frame: bounds)
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        // 创建文本视图
        textView = NSTextView(frame: bounds)
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = true
        textView.backgroundColor = NSColor.clear
        textView.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        textView.textColor = NSColor.systemBlue
        textView.alignment = .left
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.translatesAutoresizingMaskIntoConstraints = false
        
        // 设置文本容器
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude)
        
        // 将文本视图添加到滚动视图
        scrollView.documentView = textView
        
        addSubview(scrollView)
        
        // 设置约束
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func loadText(_ text: String) {
        
        // 渲染Markdown为富文本
        let attributedString = renderMarkdown(text)
        
        // 设置富文本内容
        textView.textStorage?.setAttributedString(attributedString)
        
        // 调整文本容器大小
        textView.textContainer?.containerSize = NSSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude)
        
        // 强制重新布局
        textView.layoutManager?.ensureLayout(for: textView.textContainer!)
    }
    
    private func renderMarkdown(_ markdownText: String) -> NSAttributedString {
        do {
            // 使用SwiftMarkdown解析Markdown文档
            let document = Document(parsing: markdownText)
            
            // 创建自定义的Markdown渲染器
            let renderer = MarkdownToAttributedStringRenderer()
            
            // 渲染为NSAttributedString
            let attributedString = renderer.render(document: document)
            
            return attributedString
            
        } catch {
            // 如果Markdown渲染失败，返回普通文本
            let baseFont = NSFont.systemFont(ofSize: 12, weight: .medium)
            let baseColor = NSColor.systemBlue
            
            return NSAttributedString(
                string: markdownText,
                attributes: [
                    NSAttributedString.Key.font: baseFont,
                    NSAttributedString.Key.foregroundColor: baseColor
                ]
            )
        }
    }
    
    func fittingSize() -> NSSize {
        // 获取文本的富文本内容
        let attributedString = textView.textStorage ?? NSAttributedString()
        
        // 如果没有文本内容，返回最小尺寸
        guard attributedString.length > 0 else {
            return NSSize(width: 100, height: 30)
        }
        
        // 计算文本的实际尺寸 - 先不限制宽度，获取自然宽度
        let maxWidth: CGFloat = 800  // 增加最大宽度限制
        let minWidth: CGFloat = 50   // 减少最小宽度，让短文本更紧凑
        let minHeight: CGFloat = 25  // 减少最小高度
        let padding: CGFloat = 12    // 统一内边距
        
        // 方法1: 使用boundingRect获取自然尺寸
        let naturalSize = attributedString.boundingRect(
            with: NSSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading]
        ).size
        
        // 方法2: 使用NSLayoutManager进行精确计算
        let textContainer = NSTextContainer()
        textContainer.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = 0
        
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        
        let textStorage = NSTextStorage(attributedString: attributedString)
        textStorage.addLayoutManager(layoutManager)
        
        // 强制布局并获取使用的矩形
        layoutManager.ensureLayout(for: textContainer)
        let usedRect = layoutManager.usedRect(for: textContainer)
        
        // 取两种方法的较小值，确保紧凑显示
        let textWidth = min(naturalSize.width, usedRect.width)
        let textHeight = max(naturalSize.height, usedRect.height)
        
        // 计算最终尺寸，添加内边距
        let contentWidth = max(minWidth, min(textWidth + padding, maxWidth))
        let contentHeight = max(minHeight, textHeight + padding)
        
        
        return NSSize(width: contentWidth, height: contentHeight)
    }
}

// MARK: - Markdown渲染器
class MarkdownToAttributedStringRenderer {
    
    private let baseFont = NSFont.systemFont(ofSize: 12, weight: .medium)
    private let baseColor = NSColor.systemBlue
    private let headingColor = NSColor.systemBlue
    private let codeColor = NSColor.systemGray
    private let linkColor = NSColor.systemBlue
    
    func render(document: Document) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        for child in document.children {
            let childString = renderMarkupElement(child)
            result.append(childString)
        }
        
        return result
    }
    
    private func renderMarkupElement(_ element: any Markup) -> NSAttributedString {
        switch element {
        case let paragraph as Paragraph:
            return renderParagraph(paragraph)
        case let heading as Heading:
            return renderHeading(heading)
        case let codeBlock as CodeBlock:
            return renderCodeBlock(codeBlock)
        case let list as UnorderedList:
            return renderUnorderedList(list)
        case let list as OrderedList:
            return renderOrderedList(list)
        case let text as Text:
            return renderText(text)
        case let emphasis as Emphasis:
            return renderEmphasis(emphasis)
        case let strong as Strong:
            return renderStrong(strong)
        case let inlineCode as InlineCode:
            return renderInlineCode(inlineCode)
        case let link as Link:
            return renderLink(link)
        case is LineBreak:
            return NSAttributedString(string: "\n")
        case is SoftBreak:
            return NSAttributedString(string: " ")
        default:
            // 对于未处理的元素，递归处理其子元素
            let result = NSMutableAttributedString()
            for child in element.children {
                result.append(renderMarkupElement(child))
            }
            return result
        }
    }
    
    private func renderParagraph(_ paragraph: Paragraph) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        for child in paragraph.children {
            result.append(renderMarkupElement(child))
        }
        
        result.append(NSAttributedString(string: "\n\n"))
        return result
    }
    
    private func renderHeading(_ heading: Heading) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        let fontSize: CGFloat = {
            switch heading.level {
            case 1: return 18
            case 2: return 16
            case 3: return 14
            default: return 12
            }
        }()
        
        let headingFont = NSFont.systemFont(ofSize: fontSize, weight: .bold)
        
        for child in heading.children {
            let childString = renderMarkupElement(child)
            let mutableChild = NSMutableAttributedString(attributedString: childString)
            mutableChild.addAttributes([
                .font: headingFont,
                .foregroundColor: headingColor
            ], range: NSRange(location: 0, length: mutableChild.length))
            result.append(mutableChild)
        }
        
        result.append(NSAttributedString(string: "\n\n"))
        return result
    }
    
    private func renderCodeBlock(_ codeBlock: CodeBlock) -> NSAttributedString {
        let codeFont = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        let backgroundColor = NSColor.controlBackgroundColor
        
        let result = NSMutableAttributedString(
            string: codeBlock.code + "\n\n",
            attributes: [
                .font: codeFont,
                .foregroundColor: codeColor,
                .backgroundColor: backgroundColor
            ]
        )
        
        return result
    }
    
    private func renderUnorderedList(_ list: UnorderedList) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        for item in list.children {
            if let listItem = item as? ListItem {
                result.append(NSAttributedString(string: "• "))
                for child in listItem.children {
                    result.append(renderMarkupElement(child))
                }
            }
        }
        
        result.append(NSAttributedString(string: "\n"))
        return result
    }
    
    private func renderOrderedList(_ list: OrderedList) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        for (index, item) in list.children.enumerated() {
            if let listItem = item as? ListItem {
                result.append(NSAttributedString(string: "\(index + 1). "))
                for child in listItem.children {
                    result.append(renderMarkupElement(child))
                }
            }
        }
        
        result.append(NSAttributedString(string: "\n"))
        return result
    }
    
    private func renderText(_ text: Text) -> NSAttributedString {
        return NSAttributedString(
            string: text.string,
            attributes: [
                .font: baseFont,
                .foregroundColor: baseColor
            ]
        )
    }
    
    private func renderEmphasis(_ emphasis: Emphasis) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        for child in emphasis.children {
            let childString = renderMarkupElement(child)
            let mutableChild = NSMutableAttributedString(attributedString: childString)
            mutableChild.addAttributes([
                .font: NSFont.systemFont(ofSize: 12, weight: .medium).withTraits(.italic)
            ], range: NSRange(location: 0, length: mutableChild.length))
            result.append(mutableChild)
        }
        
        return result
    }
    
    private func renderStrong(_ strong: Strong) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        for child in strong.children {
            let childString = renderMarkupElement(child)
            let mutableChild = NSMutableAttributedString(attributedString: childString)
            mutableChild.addAttributes([
                .font: NSFont.systemFont(ofSize: 12, weight: .bold)
            ], range: NSRange(location: 0, length: mutableChild.length))
            result.append(mutableChild)
        }
        
        return result
    }
    
    private func renderInlineCode(_ inlineCode: InlineCode) -> NSAttributedString {
        let codeFont = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        let backgroundColor = NSColor.controlBackgroundColor
        
        return NSAttributedString(
            string: inlineCode.code,
            attributes: [
                .font: codeFont,
                .foregroundColor: codeColor,
                .backgroundColor: backgroundColor
            ]
        )
    }
    
    private func renderLink(_ link: Link) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        for child in link.children {
            let childString = renderMarkupElement(child)
            let mutableChild = NSMutableAttributedString(attributedString: childString)
            mutableChild.addAttributes([
                .foregroundColor: linkColor,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ], range: NSRange(location: 0, length: mutableChild.length))
            
            if let destination = link.destination {
                mutableChild.addAttribute(.link, value: destination, range: NSRange(location: 0, length: mutableChild.length))
            }
            
            result.append(mutableChild)
        }
        
        return result
    }
}

// MARK: - NSFont扩展
extension NSFont {
    func withTraits(_ traits: NSFontDescriptor.SymbolicTraits) -> NSFont {
        let descriptor = fontDescriptor.withSymbolicTraits(traits)
        return NSFont(descriptor: descriptor, size: pointSize) ?? self
    }
}
