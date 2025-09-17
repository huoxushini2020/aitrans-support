//
//  AITransApp.swift
//  AITrans
//
//  Created by LEO on 12/9/2568 BE.
//

import SwiftUI

@main
struct AITransApp: App {
    @StateObject private var statusBarManager = StatusBarManager()
    
    
    init() {
        // 设置应用不在程序坞中显示图标
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.accessory)
        }
        
        // 应用初始化完成
        
        // 应用启动后显示悬浮快捷图标
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            FloatingQuickIconManager.shared.showIcon()
        }
    }
    
    var body: some Scene {
        // 应用只通过状态栏运行，不显示主窗口
        Settings {
            EmptyView()
        }
    }
    
}
