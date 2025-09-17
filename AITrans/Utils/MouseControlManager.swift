//
//  MouseControlManager.swift
//  AITrans
//
//  Created by LEO on 12/9/2568 BE.
//

import AppKit

// MARK: - MouseControlManager

/// 鼠标控制管理器
/// 负责处理窗口的鼠标交互，包括拖动、悬停效果等
class MouseControlManager: NSObject {
    
    // MARK: - Properties
    
    /// 目标窗口
    weak var targetWindow: NSWindow?
    
    /// 目标视图
    weak var targetView: NSView?
    
    /// 排除区域（如按钮区域）
    private var excludedFrames: [NSRect] = []
    
    /// 是否启用拖动
    var isDragEnabled: Bool = true
    
    /// 是否启用悬停效果
    var isHoverEnabled: Bool = true
    
    // MARK: - Initialization
    
    init(targetWindow: NSWindow? = nil, targetView: NSView? = nil) {
        self.targetWindow = targetWindow
        self.targetView = targetView
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// 设置目标窗口和视图
    func setTarget(window: NSWindow?, view: NSView?) {
        self.targetWindow = window
        self.targetView = view
    }
    
    /// 添加排除区域（如按钮区域）
    func addExcludedFrame(_ frame: NSRect) {
        excludedFrames.append(frame)
    }
    
    /// 移除排除区域
    func removeExcludedFrame(_ frame: NSRect) {
        excludedFrames.removeAll { $0 == frame }
    }
    
    /// 清除所有排除区域
    func clearExcludedFrames() {
        excludedFrames.removeAll()
    }
    
    /// 更新排除区域
    func updateExcludedFrames(_ frames: [NSRect]) {
        excludedFrames = frames
    }
    
    // MARK: - Mouse Event Handling
    
    /// 处理鼠标按下事件
    func handleMouseDown(with event: NSEvent, in view: NSView) -> Bool {
        guard isDragEnabled else { return false }
        
        let clickPoint = view.convert(event.locationInWindow, from: nil)
        
        // 检查是否点击在排除区域内
        for excludedFrame in excludedFrames {
            if excludedFrame.contains(clickPoint) {
                return false // 不处理拖动
            }
        }
        
        // 使用系统原生的窗口拖动机制
        if let window = targetWindow {
            window.performDrag(with: event)
            return true
        }
        
        return false
    }
    
    /// 处理鼠标进入事件
    func handleMouseEntered(with event: NSEvent, in view: NSView) {
        guard isHoverEnabled else { return }
        
        let mousePoint = view.convert(event.locationInWindow, from: nil)
        
        // 检查鼠标是否在排除区域内
        var isInExcludedArea = false
        for excludedFrame in excludedFrames {
            if excludedFrame.contains(mousePoint) {
                isInExcludedArea = true
                break
            }
        }
        
        // 如果不在排除区域内，显示移动光标
        if !isInExcludedArea {
            NSCursor.openHand.set()
        }
    }
    
    /// 处理鼠标离开事件
    func handleMouseExited(with event: NSEvent, in view: NSView) {
        guard isHoverEnabled else { return }
        
        // 恢复默认光标
        NSCursor.arrow.set()
    }
    
    /// 更新鼠标跟踪区域
    func updateTrackingAreas(in view: NSView) {
        // 移除旧的跟踪区域
        for trackingArea in view.trackingAreas {
            view.removeTrackingArea(trackingArea)
        }
        
        // 添加新的跟踪区域（整个视图）
        let trackingArea = NSTrackingArea(
            rect: view.bounds,
            options: [.mouseEnteredAndExited, .activeInKeyWindow],
            owner: view,
            userInfo: nil
        )
        view.addTrackingArea(trackingArea)
    }
}

// MARK: - MouseControlDelegate

/// 鼠标控制代理协议
protocol MouseControlDelegate: AnyObject {
    /// 鼠标按下事件
    func mouseDown(with event: NSEvent) -> Bool
    
    /// 鼠标进入事件
    func mouseEntered(with event: NSEvent)
    
    /// 鼠标离开事件
    func mouseExited(with event: NSEvent)
    
    /// 更新跟踪区域
    func updateTrackingAreas()
}

// MARK: - MouseControlView

/// 支持鼠标控制的视图基类
class MouseControlView: NSView {
    
    // MARK: - Properties
    
    /// 鼠标控制管理器
    private let mouseControlManager = MouseControlManager()
    
    /// 鼠标控制代理
    weak var mouseControlDelegate: MouseControlDelegate?
    
    /// 是否启用拖动
    var isDragEnabled: Bool = true {
        didSet {
            mouseControlManager.isDragEnabled = isDragEnabled
        }
    }
    
    /// 是否启用悬停效果
    var isHoverEnabled: Bool = true {
        didSet {
            mouseControlManager.isHoverEnabled = isHoverEnabled
        }
    }
    
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupMouseControl()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupMouseControl()
    }
    
    // MARK: - Setup
    
    private func setupMouseControl() {
        mouseControlManager.setTarget(window: window, view: self)
    }
    
    // MARK: - Mouse Event Overrides
    
    override func mouseDown(with event: NSEvent) {
        let handled = mouseControlManager.handleMouseDown(with: event, in: self)
        if !handled {
            mouseControlDelegate?.mouseDown(with: event)
        }
    }
    
    override func mouseEntered(with event: NSEvent) {
        mouseControlManager.handleMouseEntered(with: event, in: self)
        mouseControlDelegate?.mouseEntered(with: event)
    }
    
    override func mouseExited(with event: NSEvent) {
        mouseControlManager.handleMouseExited(with: event, in: self)
        mouseControlDelegate?.mouseExited(with: event)
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        mouseControlManager.updateTrackingAreas(in: self)
    }
    
    // MARK: - Public Methods
    
    /// 添加排除区域
    func addExcludedFrame(_ frame: NSRect) {
        mouseControlManager.addExcludedFrame(frame)
    }
    
    /// 移除排除区域
    func removeExcludedFrame(_ frame: NSRect) {
        mouseControlManager.removeExcludedFrame(frame)
    }
    
    /// 更新排除区域
    func updateExcludedFrames(_ frames: [NSRect]) {
        mouseControlManager.updateExcludedFrames(frames)
    }
    
    /// 清除所有排除区域
    func clearExcludedFrames() {
        mouseControlManager.clearExcludedFrames()
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        mouseControlManager.setTarget(window: window, view: self)
    }
}
