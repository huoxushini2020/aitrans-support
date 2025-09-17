//
//  PermissionCheckWindow.swift
//  AITrans
//
//  Created by LEO on 12/9/2568 BE.
//

import AppKit
import CoreGraphics

// MARK: - 权限检查窗口
class PermissionCheckWindow: NSWindow {
    
    private var mainContentView: NSView!
    private var titleLabel: NSTextField!
    private var descriptionLabel: NSTextField!
    private var screenRecordingStatusView: PermissionStatusView!
    private var accessibilityStatusView: PermissionStatusView!
    private var launchAtLoginCheckbox: NSButton!
    private var openSettingsButton: NSButton!
    private var closeButton: NSButton!
    
    // 本地化管理器
    private let localizationManager = LocalizationManager.shared
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        setupWindow()
        setupContentView()
        setupLocalizationObserver()
        checkPermissions()
    }
    
    convenience init() {
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let windowSize = NSSize(width: 500, height: 400)
        let windowOrigin = NSPoint(
            x: screenFrame.midX - windowSize.width / 2 + 400, // 向右偏移400pt
            y: screenFrame.midY - windowSize.height / 2
        )
        
        self.init(
            contentRect: NSRect(origin: windowOrigin, size: windowSize),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupWindow() {
        title = LocalizationManager.localized("permission_check")
        isReleasedWhenClosed = false
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // 设置窗口样式
        titlebarAppearsTransparent = true
        titleVisibility = .visible
        isMovableByWindowBackground = true
        
        // 设置背景色
        backgroundColor = NSColor.controlBackgroundColor
    }
    
    private func setupContentView() {
        mainContentView = NSView()
        mainContentView.wantsLayer = true
        mainContentView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        mainContentView.layer?.cornerRadius = 12
        mainContentView.layer?.masksToBounds = true
        
        self.contentView = mainContentView
        
        setupSubviews()
        setupConstraints()
    }
    
    private func setupSubviews() {
        // 创建标题标签
        titleLabel = NSTextField()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.isEditable = false
        titleLabel.isBordered = false
        titleLabel.backgroundColor = NSColor.clear
        titleLabel.font = NSFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = NSColor.labelColor
        titleLabel.stringValue = "🔒 \(LocalizationManager.localized("permission_check"))"
        titleLabel.alignment = .center
        mainContentView.addSubview(titleLabel)
        
        // 创建描述标签
        descriptionLabel = NSTextField()
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.isEditable = false
        descriptionLabel.isBordered = false
        descriptionLabel.backgroundColor = NSColor.clear
        descriptionLabel.font = NSFont.systemFont(ofSize: 14)
        descriptionLabel.textColor = NSColor.secondaryLabelColor
        descriptionLabel.stringValue = LocalizationManager.localized("permission_description")
        descriptionLabel.alignment = .center
        mainContentView.addSubview(descriptionLabel)
        
        // 创建屏幕录制权限状态视图
        screenRecordingStatusView = PermissionStatusView(
            title: LocalizationManager.localized("screen_recording_permission"),
            description: "",
            iconName: "camera.fill",
            permissionType: .screenRecording
        )
        screenRecordingStatusView.translatesAutoresizingMaskIntoConstraints = false
        mainContentView.addSubview(screenRecordingStatusView)
        
        // 创建辅助功能权限状态视图
        accessibilityStatusView = PermissionStatusView(
            title: LocalizationManager.localized("accessibility_permission"),
            description: "",
            iconName: "accessibility.fill",
            permissionType: .accessibility
        )
        accessibilityStatusView.translatesAutoresizingMaskIntoConstraints = false
        mainContentView.addSubview(accessibilityStatusView)
        
        // 创建启动时登录复选框
        launchAtLoginCheckbox = NSButton()
        launchAtLoginCheckbox.translatesAutoresizingMaskIntoConstraints = false
        launchAtLoginCheckbox.setButtonType(.switch)
        launchAtLoginCheckbox.title = LocalizationManager.localized("launch_at_login")
        launchAtLoginCheckbox.target = self
        launchAtLoginCheckbox.action = #selector(launchAtLoginChanged)
        launchAtLoginCheckbox.font = NSFont.systemFont(ofSize: 14)
        mainContentView.addSubview(launchAtLoginCheckbox)
        
        // 创建打开设置按钮
        openSettingsButton = NSButton()
        openSettingsButton.translatesAutoresizingMaskIntoConstraints = false
        openSettingsButton.title = LocalizationManager.localized("open_system_preferences")
        openSettingsButton.target = self
        openSettingsButton.action = #selector(openSystemPreferences)
        openSettingsButton.bezelStyle = .rounded
        openSettingsButton.controlSize = .large
        mainContentView.addSubview(openSettingsButton)
        
        // 创建关闭按钮
        closeButton = NSButton()
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.title = LocalizationManager.localized("close")
        closeButton.target = self
        closeButton.action = #selector(closeWindow)
        closeButton.bezelStyle = .rounded
        closeButton.controlSize = .large
        mainContentView.addSubview(closeButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // 标题标签约束
            titleLabel.topAnchor.constraint(equalTo: mainContentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: mainContentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: mainContentView.trailingAnchor, constant: -20),
            
            // 描述标签约束
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            descriptionLabel.leadingAnchor.constraint(equalTo: mainContentView.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: mainContentView.trailingAnchor, constant: -20),
            
            // 屏幕录制权限状态视图约束
            screenRecordingStatusView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 30),
            screenRecordingStatusView.leadingAnchor.constraint(equalTo: mainContentView.leadingAnchor, constant: 20),
            screenRecordingStatusView.trailingAnchor.constraint(equalTo: mainContentView.trailingAnchor, constant: -20),
            
            // 辅助功能权限状态视图约束
            accessibilityStatusView.topAnchor.constraint(equalTo: screenRecordingStatusView.bottomAnchor, constant: 20),
            accessibilityStatusView.leadingAnchor.constraint(equalTo: mainContentView.leadingAnchor, constant: 20),
            accessibilityStatusView.trailingAnchor.constraint(equalTo: mainContentView.trailingAnchor, constant: -20),
            
            // 启动时登录复选框约束
            launchAtLoginCheckbox.topAnchor.constraint(equalTo: accessibilityStatusView.bottomAnchor, constant: 25),
            launchAtLoginCheckbox.leadingAnchor.constraint(equalTo: mainContentView.leadingAnchor, constant: 20),
            launchAtLoginCheckbox.trailingAnchor.constraint(equalTo: mainContentView.trailingAnchor, constant: -20),
            
            // 打开设置按钮约束
            openSettingsButton.topAnchor.constraint(equalTo: launchAtLoginCheckbox.bottomAnchor, constant: 25),
            openSettingsButton.centerXAnchor.constraint(equalTo: mainContentView.centerXAnchor),
            openSettingsButton.widthAnchor.constraint(equalToConstant: 200),
            
            // 关闭按钮约束
            closeButton.topAnchor.constraint(equalTo: openSettingsButton.bottomAnchor, constant: 15),
            closeButton.centerXAnchor.constraint(equalTo: mainContentView.centerXAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 100),
            closeButton.bottomAnchor.constraint(lessThanOrEqualTo: mainContentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func checkPermissions() {
        // 检查屏幕录制权限
        let screenRecordingPermission = CGPreflightScreenCaptureAccess()
        screenRecordingStatusView.updateStatus(isGranted: screenRecordingPermission)
        
        // 检查辅助功能权限
        let accessibilityPermission = AXIsProcessTrusted()
        accessibilityStatusView.updateStatus(isGranted: accessibilityPermission)
        
        // 初始化启动时登录复选框状态
        launchAtLoginCheckbox.state = isLaunchAtLoginEnabled() ? .on : .off
        
        // 更新标题栏图标
        updateTitleIcon()
    }
    
    /// 更新标题栏图标
    private func updateTitleIcon() {
        let screenRecordingPermission = CGPreflightScreenCaptureAccess()
        let accessibilityPermission = AXIsProcessTrusted()
        
        // 如果有任何权限未授权，显示黄色警告图标
        if !screenRecordingPermission || !accessibilityPermission {
            titleLabel.stringValue = "⚠️ \(LocalizationManager.localized("permission_check"))"
        } else {
            titleLabel.stringValue = "🔒 \(LocalizationManager.localized("permission_check"))"
        }
    }
    
    @objc private func openSystemPreferences() {
        // 打开系统偏好设置
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc private func closeWindow() {
        close()
    }
    
    @objc private func launchAtLoginChanged() {
        setLaunchAtLogin(launchAtLoginCheckbox.state == .on)
    }
    
    func showWindow() {
        makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    /// 刷新权限状态（当用户从系统设置返回时调用）
    @objc func refreshPermissions() {
        checkPermissions()
    }
    
    // MARK: - 启动时登录管理
    
    /// 检查是否启用了启动时登录
    private func isLaunchAtLoginEnabled() -> Bool {
        // 使用 UserDefaults 存储状态，因为 SMLoginItemSetEnabled 需要 Helper App
        return UserDefaults.standard.bool(forKey: "LaunchAtLogin")
    }
    
    /// 设置启动时登录
    private func setLaunchAtLogin(_ enabled: Bool) {
        // 存储状态到 UserDefaults
        UserDefaults.standard.set(enabled, forKey: "LaunchAtLogin")
        
        // 使用 AppleScript 来配置登录项
        configureLoginItemWithAppleScript(enabled: enabled)
        
        print("启动时登录状态已设置为: \(enabled)")
    }
    
    /// 使用 AppleScript 配置登录项
    private func configureLoginItemWithAppleScript(enabled: Bool) {
        let appPath = Bundle.main.bundlePath
        
        let script: String
        if enabled {
            script = """
            tell application "System Events"
                try
                    make login item at end with properties {path:"\(appPath)", hidden:false}
                on error
                    -- 如果已经存在，忽略错误
                end try
            end tell
            """
        } else {
            script = """
            tell application "System Events"
                set loginItems to login items
                repeat with loginItem in loginItems
                    if path of loginItem is "\(appPath)" then
                        delete loginItem
                    end if
                end repeat
            end tell
            """
        }
        
        executeAppleScript(script: script)
    }
    
    /// 执行 AppleScript
    private func executeAppleScript(script: String) {
        let appleScript = NSAppleScript(source: script)
        var error: NSDictionary?
        appleScript?.executeAndReturnError(&error)
        
        if let error = error {
            print("AppleScript 执行错误: \(error)")
        } else {
            print("AppleScript 执行成功")
        }
    }
    
    // MARK: - 本地化支持
    
    /// 设置本地化观察者
    private func setupLocalizationObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageChanged),
            name: NSNotification.Name("LanguageChanged"),
            object: nil
        )
        
        // 添加权限刷新通知监听
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshPermissions),
            name: NSNotification.Name("RefreshPermissions"),
            object: nil
        )
    }
    
    /// 语言切换处理
    @objc private func languageChanged() {
        DispatchQueue.main.async {
            self.updateLocalizedTexts()
        }
    }
    
    /// 更新本地化文本
    private func updateLocalizedTexts() {
        // 更新窗口标题
        title = localizationManager.permissionCheck
        
        // 更新标题标签
        titleLabel.stringValue = "🔒 \(localizationManager.permissionCheck)"
        
        // 更新描述标签
        descriptionLabel.stringValue = localizationManager.permissionDescription
        
        // 更新按钮文本
        openSettingsButton.title = localizationManager.openSystemPreferences
        closeButton.title = localizationManager.close
        
        // 更新启动时登录复选框文本
        launchAtLoginCheckbox.title = localizationManager.launchAtLogin
        
        // 更新权限状态视图
        screenRecordingStatusView.updateLocalizedTexts(
            title: localizationManager.screenRecordingPermission,
            description: ""
        )
        
        accessibilityStatusView.updateLocalizedTexts(
            title: localizationManager.accessibilityPermission,
            description: ""
        )
        
        // 更新设置按钮文本
        screenRecordingStatusView.updateSettingsButtonText()
        accessibilityStatusView.updateSettingsButtonText()
    }
}

// MARK: - 权限状态视图
class PermissionStatusView: NSView {
    
    private var iconImageView: NSImageView!
    private var titleLabel: NSTextField!
    private var descriptionLabel: NSTextField!
    private var statusLabel: NSTextField!
    private var statusIndicator: NSView!
    private var settingsButton: NSButton!
    
    // 权限类型枚举
    enum PermissionType {
        case screenRecording
        case accessibility
        
        var settingsURL: String {
            switch self {
            case .screenRecording:
                return "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
            case .accessibility:
                return "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
            }
        }
    }
    
    private var permissionType: PermissionType = .screenRecording
    
    init(title: String, description: String, iconName: String, permissionType: PermissionType = .screenRecording) {
        super.init(frame: .zero)
        self.permissionType = permissionType
        setupView(title: title, description: description, iconName: iconName)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView(title: "", description: "", iconName: "")
    }
    
    private func setupView(title: String, description: String, iconName: String) {
        wantsLayer = true
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        layer?.cornerRadius = 8
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.separatorColor.cgColor
        
        // 创建图标
        iconImageView = NSImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.image = NSImage(systemSymbolName: iconName, accessibilityDescription: title)
        iconImageView.image?.isTemplate = true
        iconImageView.contentTintColor = NSColor.controlTextColor
        addSubview(iconImageView)
        
        // 创建标题标签
        titleLabel = NSTextField()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.isEditable = false
        titleLabel.isBordered = false
        titleLabel.backgroundColor = NSColor.clear
        titleLabel.font = NSFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = NSColor.labelColor
        titleLabel.stringValue = title
        addSubview(titleLabel)
        
        // 创建描述标签（仅当描述不为空时）
        if !description.isEmpty {
            descriptionLabel = NSTextField()
            descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
            descriptionLabel.isEditable = false
            descriptionLabel.isBordered = false
            descriptionLabel.backgroundColor = NSColor.clear
            descriptionLabel.font = NSFont.systemFont(ofSize: 12)
            descriptionLabel.textColor = NSColor.secondaryLabelColor
            descriptionLabel.stringValue = description
            addSubview(descriptionLabel)
        }
        
        // 创建状态指示器
        statusIndicator = NSView()
        statusIndicator.translatesAutoresizingMaskIntoConstraints = false
        statusIndicator.wantsLayer = true
        statusIndicator.layer?.cornerRadius = 6
        addSubview(statusIndicator)
        
        // 创建状态标签
        statusLabel = NSTextField()
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.isEditable = false
        statusLabel.isBordered = false
        statusLabel.backgroundColor = NSColor.clear
        statusLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        statusLabel.alignment = .center
        addSubview(statusLabel)
        
        // 创建设置按钮
        settingsButton = NSButton()
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.title = LocalizationManager.localized("settings")
        settingsButton.target = self
        settingsButton.action = #selector(openSettings)
        settingsButton.bezelStyle = .rounded
        settingsButton.controlSize = .small
        settingsButton.isHidden = true // 默认隐藏，只有在权限未授权时才显示
        addSubview(settingsButton)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        var constraints: [NSLayoutConstraint] = []
        
        // 设置固定高度约束，确保所有权限面板高度一致
        constraints.append(
            heightAnchor.constraint(equalToConstant: 60)
        )
        
        // 图标约束
        constraints.append(contentsOf: [
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        // 标题标签约束 - 垂直居中对齐
        constraints.append(contentsOf: [
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusIndicator.leadingAnchor, constant: -8)
        ])
        
        // 描述标签约束（仅当描述标签存在时）
        if let descriptionLabel = descriptionLabel {
            constraints.append(contentsOf: [
                descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
                descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
                descriptionLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusIndicator.leadingAnchor, constant: -8),
                descriptionLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -12)
            ])
        } else {
            // 如果没有描述标签，让标题标签的底部约束到视图底部
            constraints.append(
                titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -12)
            )
        }
        
        // 状态指示器约束
        constraints.append(contentsOf: [
            statusIndicator.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15),
            statusIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
            statusIndicator.widthAnchor.constraint(equalToConstant: 12),
            statusIndicator.heightAnchor.constraint(equalToConstant: 12)
        ])
        
        // 状态标签约束 - 垂直居中对齐
        constraints.append(contentsOf: [
            statusLabel.trailingAnchor.constraint(equalTo: statusIndicator.leadingAnchor, constant: -8),
            statusLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            statusLabel.widthAnchor.constraint(equalToConstant: 60)
        ])
        
        // 设置按钮约束
        constraints.append(contentsOf: [
            settingsButton.trailingAnchor.constraint(equalTo: statusLabel.leadingAnchor, constant: -8),
            settingsButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            settingsButton.widthAnchor.constraint(equalToConstant: 60),
            settingsButton.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        NSLayoutConstraint.activate(constraints)
    }
    
    func updateStatus(isGranted: Bool) {
        if isGranted {
            statusIndicator.layer?.backgroundColor = NSColor.systemGreen.cgColor
            statusLabel.stringValue = LocalizationManager.localized("authorized")
            statusLabel.textColor = NSColor.systemGreen
            // 更新图标为正常状态
            iconImageView.image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "Authorized")
            iconImageView.contentTintColor = NSColor.systemGreen
            // 隐藏设置按钮
            settingsButton.isHidden = true
        } else {
            statusIndicator.layer?.backgroundColor = NSColor.systemRed.cgColor
            statusLabel.stringValue = LocalizationManager.localized("unauthorized")
            statusLabel.textColor = NSColor.systemRed
            // 更新图标为黄色警告状态
            iconImageView.image = NSImage(systemSymbolName: "exclamationmark.triangle.fill", accessibilityDescription: "Warning")
            iconImageView.contentTintColor = NSColor.systemYellow
            // 显示设置按钮
            settingsButton.isHidden = false
        }
    }
    
    /// 更新本地化文本
    func updateLocalizedTexts(title: String, description: String) {
        titleLabel.stringValue = title
        if let descriptionLabel = descriptionLabel {
            descriptionLabel.stringValue = description
        }
    }
    
    /// 打开设置按钮点击事件
    @objc private func openSettings() {
        // 打开系统设置页面
        if let url = URL(string: permissionType.settingsURL) {
            NSWorkspace.shared.open(url)
        }
        
        // 显示操作指引
        showPermissionGuide()
    }
    
    /// 显示权限设置指引
    private func showPermissionGuide() {
        let alert = NSAlert()
        alert.messageText = LocalizationManager.localized("permission_guide_title")
        
        let guideText = getPermissionGuideText()
        alert.informativeText = guideText
        
        alert.addButton(withTitle: LocalizationManager.localized("got_it"))
        alert.addButton(withTitle: LocalizationManager.localized("refresh_permissions"))
        
        let response = alert.runModal()
        
        if response == .alertSecondButtonReturn {
            // 用户点击了"刷新权限"按钮
            refreshPermissions()
        }
    }
    
    /// 获取权限设置指引文本
    private func getPermissionGuideText() -> String {
        switch permissionType {
        case .screenRecording:
            return LocalizationManager.localized("screen_recording_guide")
        case .accessibility:
            return LocalizationManager.localized("accessibility_guide")
        }
    }
    
    /// 刷新权限状态
    private func refreshPermissions() {
        // 通知父窗口刷新权限状态
        NotificationCenter.default.post(
            name: NSNotification.Name("RefreshPermissions"),
            object: nil
        )
    }
    
    /// 更新设置按钮文本
    func updateSettingsButtonText() {
        settingsButton.title = LocalizationManager.localized("settings")
    }
}
