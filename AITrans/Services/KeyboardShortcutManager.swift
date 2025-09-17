//
//  KeyboardShortcutManager.swift
//  AITrans
//
//  Created by LEO on 15/9/2568 BE.
//

import AppKit
import KeyboardShortcuts

/// 键盘快捷键管理器
class KeyboardShortcutManager: ObservableObject {
    static let shared = KeyboardShortcutManager()
    
    private init() {
        setupShortcuts()
    }
    
    /// 设置快捷键
    private func setupShortcuts() {
        // 设置截图快捷键为 Shift+Command+S
        KeyboardShortcuts.onKeyUp(for: .screenshot) {
            print("🟢 KeyboardShortcutManager: 检测到截图快捷键 Shift+Command+S")
            self.handleScreenshotShortcut()
        }
    }
    
    /// 处理截图快捷键
    private func handleScreenshotShortcut() {
        print("🟢 KeyboardShortcutManager: 执行截图操作")
        
        // 使用统一的截图服务
        ScreenshotService.shared.startScreenshotCapture(source: .keyboardShortcut)
    }
    
    /// 启用快捷键
    func enableShortcuts() {
        print("🟢 KeyboardShortcutManager: 启用快捷键")
        // KeyboardShortcuts 会自动处理启用
    }
    
    /// 禁用快捷键
    func disableShortcuts() {
        print("🔴 KeyboardShortcutManager: 禁用快捷键")
        // KeyboardShortcuts 会自动处理禁用
    }
}

// MARK: - 快捷键定义扩展
extension KeyboardShortcuts.Name {
    /// 截图快捷键
    static let screenshot = Self("screenshot", default: .init(.s, modifiers: [.command, .shift]))
}
