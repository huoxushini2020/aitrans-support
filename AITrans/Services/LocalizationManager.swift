//
//  LocalizationManager.swift
//  AITrans
//
//  Created by LEO on 14/9/2568 BE.
//

import Foundation

/// 本地化管理器，支持中英文切换
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    // 当前语言
    @Published var currentLanguage: Language = .english
    
    // 支持的语言
    enum Language: String, CaseIterable {
        case english = "en"
        case chinese = "zh"
        case traditionalChinese = "zh-TW"
        case spanish = "es"
        case french = "fr"
        case german = "de"
        case japanese = "ja"
        case korean = "ko"
        case thai = "th"
        case vietnamese = "vi"
        
        var displayName: String {
            switch self {
            case .english:
                return "English"
            case .chinese:
                return "简体中文"
            case .traditionalChinese:
                return "繁體中文"
            case .spanish:
                return "Español"
            case .french:
                return "Français"
            case .german:
                return "Deutsch"
            case .japanese:
                return "日本語"
            case .korean:
                return "한국어"
            case .thai:
                return "ไทย"
            case .vietnamese:
                return "Tiếng Việt"
            }
        }
        
        var nativeName: String {
            switch self {
            case .english:
                return "English"
            case .chinese:
                return "简体中文"
            case .traditionalChinese:
                return "繁體中文"
            case .spanish:
                return "Español"
            case .french:
                return "Français"
            case .german:
                return "Deutsch"
            case .japanese:
                return "日本語"
            case .korean:
                return "한국어"
            case .thai:
                return "ไทย"
            case .vietnamese:
                return "Tiếng Việt"
            }
        }
    }
    
    // 本地化字符串
    private let localizedStrings: [Language: [String: String]] = [
        .english: [
            // 通用
            "app_name": "AITrans",
            "ok": "OK",
            "cancel": "Cancel",
            "close": "Close",
            "save": "Save",
            "delete": "Delete",
            "edit": "Edit",
            "copy": "Copy",
            "paste": "Paste",
            "undo": "Undo",
            "redo": "Redo",
            "refresh": "Refresh",
            "settings": "Settings",
            "help": "Help",
            "about": "About",
            "quit": "Quit",
            "yes": "Yes",
            "no": "No",
            "loading": "Loading...",
            "error": "Error",
            "success": "Success",
            "warning": "Warning",
            "info": "Information",
            
            // 状态栏菜单
            "permission_check": "Permission Check",
            "screenshot_ocr": "Screenshot OCR",
            "translation_language": "Translation Language",
            "target_language": "Target Language",
            "interface_language": "Interface Language",
            "floating_icon": "Floating Icon",
            "launch_at_login": "Launch at Login",
            "show_floating_icon": "Show Floating Icon",
            "position": "Position",
            "bottom_right": "Bottom Right",
            "bottom_left": "Bottom Left",
            "top_right": "Top Right",
            "top_left": "Top Left",
            "quit_app": "Quit AITrans",
            
            // 语言选项
            "auto_detect": "Auto",
            "system_language": "System",
            "english": "English",
            "chinese_simplified": "Simplified Chinese",
            "chinese_traditional": "Traditional Chinese",
            "spanish": "Spanish",
            "french": "French",
            "german": "German",
            "japanese": "Japanese",
            "korean": "Korean",
            "thai": "Thai",
            "vietnamese": "Vietnamese",
            
            // 翻译相关
            "translation_failed": "Translation failed",
            "translation_success": "Translation successful",
            "translating": "Translating...",
            "no_text_detected": "No text detected, please retry",
            "screenshot_failed": "Screenshot failed",
            "ocr_failed": "OCR recognition failed",
            
            // 权限相关
            "permission_required": "Permission Required",
            "screen_recording_permission": "Screen Recording Permission",
            "accessibility_permission": "Accessibility Permission",
            "permission_description": "AITrans requires the permissions to work properly:",
            "open_system_preferences": "Open System Preferences",
            "authorized": "Yes",
            "unauthorized": "No",
            "accessibility_permission_description": "For global shortcuts and window management",
            "permission_guide_title": "Permission Setup Guide",
            "screen_recording_guide": "1. In the opened System Settings window, find 'Screen Recording' in the left sidebar\n2. Look for 'AITrans' in the application list\n3. If AITrans is not in the list, click the '+' button to add it\n4. Check the box next to 'AITrans' to enable screen recording permission\n5. Click 'Refresh Permissions' below to update the status",
            "accessibility_guide": "1. In the opened System Settings window, find 'Accessibility' in the left sidebar\n2. Look for 'AITrans' in the application list\n3. If AITrans is not in the list, click the '+' button to add it\n4. Check the box next to 'AITrans' to enable accessibility permission\n5. Click 'Refresh Permissions' below to update the status",
            "got_it": "Got it",
            "refresh_permissions": "Refresh Permissions",
            
            // AI面板
            "ai_detailed_explanation": "Extension",
            "ai_analyzing": "waitting...",
            "ai_analysis_failed": "AI analysis failed",
            "ai_provider": "AI Provider",
            "switch_ai_provider": "Switch Provider",
            
            // 窗口相关
            "pin_window": "Pin Window",
            "unpin_window": "Unpin Window",
            "take_screenshot": "Take Screenshot",
            "play_audio": "Play Audio",
            "mute_audio": "Mute Audio",
            
            // 错误信息
            "network_error": "Network connection error",
            "api_key_invalid": "API key is invalid",
            "service_unavailable": "Service temporarily unavailable",
            "unknown_error": "Unknown error occurred",
            
            // 权限提示
            "screen_recording_permission_required": "Screen Recording Permission Required",
            "screen_recording_permission_description": "Please go to System Preferences > Security & Privacy > Privacy > Screen Recording to allow AITrans to access screen recording functionality.",
            
            // OCR相关
            "ocr_processing": "Processing OCR...",
            "ocr_success": "OCR recognition successful",
            "ocr_processing_failed": "OCR processing failed",
            "please_retry_ocr": "Please retry OCR recognition",
            
            // 翻译相关
            "translation_processing": "Processing translation...",
            "please_retry_translation": "Please retry translation",
            "request_format_error": "Request content format error",
            "please_retry_later": "Please try again later or check your network connection",
            
            // AI分析相关
            "ai_processing": "processing...",
            "ai_analysis_error": "analysis error",
            "api_key_validation_failed": "API key validation failed, please check configuration",
            "provider_switch_error": "Provider switch error",
            "default_provider_saved": "Default provider saved successfully",
            "default_provider_save_failed": "Default provider save failed"
        ],
        .traditionalChinese: [
            // 通用
            "app_name": "AITrans",
            "ok": "確定",
            "cancel": "取消",
            "close": "關閉",
            "save": "保存",
            "delete": "刪除",
            "edit": "編輯",
            "copy": "複製",
            "paste": "貼上",
            "undo": "撤銷",
            "redo": "重做",
            "refresh": "刷新",
            "settings": "設置",
            "help": "幫助",
            "about": "關於",
            "quit": "退出",
            "yes": "是",
            "no": "否",
            "loading": "載入中...",
            "error": "錯誤",
            "success": "成功",
            "warning": "警告",
            "info": "信息",
            
            // 狀態欄菜單
            "permission_check": "權限檢查",
            "screenshot_ocr": "截圖識別",
            "translation_language": "翻譯語言",
            "target_language": "目標語言",
            "interface_language": "界面語言",
            "floating_icon": "懸浮快捷圖標",
            "launch_at_login": "開機時啟動",
            "show_floating_icon": "顯示懸浮圖標",
            "position": "位置",
            "bottom_right": "右下角",
            "bottom_left": "左下角",
            "top_right": "右上角",
            "top_left": "左上角",
            "quit_app": "退出 AITrans",
            
            // 語言選項
            "auto_detect": "自動檢測",
            "system_language": "系統語言",
            "english": "英語",
            "chinese_simplified": "簡體中文",
            "chinese_traditional": "繁體中文",
            "spanish": "西班牙語",
            "french": "法語",
            "german": "德語",
            "japanese": "日語",
            "korean": "韓語",
            "thai": "泰語",
            "vietnamese": "越南語",
            
            // 翻譯相關
            "translation_failed": "翻譯失敗",
            "translation_success": "翻譯成功",
            "translating": "翻譯中...",
            "no_text_detected": "未識別到文本，請重新截圖",
            "screenshot_failed": "截圖失敗",
            "ocr_failed": "OCR識別失敗",
            
            // 權限相關
            "permission_required": "需要權限",
            "screen_recording_permission": "屏幕錄製權限",
            "accessibility_permission": "輔助功能權限",
            "permission_description": "AITrans 需要以下權限才能正常工作：",
            "open_system_preferences": "打開系統偏好設置",
            "authorized": "已授權",
            "unauthorized": "未授權",
            "accessibility_permission_description": "用於全局快捷鍵和窗口管理",
            "permission_guide_title": "權限設置指引",
            "screen_recording_guide": "1. 在打開的系統設置窗口中，在左側邊欄找到「屏幕錄製」\n2. 在應用程序列表中查找「AITrans」\n3. 如果列表中沒有 AITrans，請點擊「+」按鈕添加\n4. 勾選「AITrans」旁邊的複選框以啟用屏幕錄製權限\n5. 點擊下方的「刷新權限」按鈕更新狀態",
            "accessibility_guide": "1. 在打開的系統設置窗口中，在左側邊欄找到「輔助功能」\n2. 在應用程序列表中查找「AITrans」\n3. 如果列表中沒有 AITrans，請點擊「+」按鈕添加\n4. 勾選「AITrans」旁邊的複選框以啟用輔助功能權限\n5. 點擊下方的「刷新權限」按鈕更新狀態",
            "got_it": "知道了",
            "refresh_permissions": "刷新權限",
            
            // AI面板
            "ai_detailed_explanation": "擴展",
            "ai_analyzing": "執行中...",
            "ai_analysis_failed": "AI 分析失敗",
            "ai_provider": "AI 廠商",
            "switch_ai_provider": "切換 AI 廠商",
            
            // 窗口相關
            "pin_window": "固定窗口",
            "unpin_window": "取消固定",
            "take_screenshot": "截圖",
            "play_audio": "播放音頻",
            "mute_audio": "靜音",
            
            // 錯誤信息
            "network_error": "網絡連接錯誤",
            "api_key_invalid": "API密鑰無效",
            "service_unavailable": "服務暫時不可用",
            "unknown_error": "發生未知錯誤",
            
            // 權限提示
            "screen_recording_permission_required": "需要屏幕錄製權限",
            "screen_recording_permission_description": "請在系統偏好設置 > 安全性與隱私 > 隱私 > 屏幕錄製中，允許AITrans訪問屏幕錄製功能。",
            
            // OCR相關
            "ocr_processing": "正在處理OCR...",
            "ocr_success": "OCR識別成功",
            "ocr_processing_failed": "OCR處理失敗",
            "please_retry_ocr": "請重新進行OCR識別",
            
            // 翻譯相關
            "translation_processing": "正在處理翻譯...",
            "please_retry_translation": "請重新翻譯",
            "request_format_error": "請求內容格式錯誤",
            "please_retry_later": "請稍後重試或檢查網絡連接",
            
            // AI分析相關
            "ai_processing": "AI正在處理...",
            "ai_analysis_error": "AI分析錯誤",
            "api_key_validation_failed": "API密鑰驗證失敗，請檢查配置",
            "provider_switch_error": "廠商切換錯誤",
            "default_provider_saved": "默認廠商保存成功",
            "default_provider_save_failed": "默認廠商保存失敗"
        ],
        .spanish: [
            // 通用
            "app_name": "AITrans",
            "ok": "OK",
            "cancel": "Cancelar",
            "close": "Cerrar",
            "save": "Guardar",
            "delete": "Eliminar",
            "edit": "Editar",
            "copy": "Copiar",
            "paste": "Pegar",
            "undo": "Deshacer",
            "redo": "Rehacer",
            "refresh": "Actualizar",
            "settings": "Configuración",
            "help": "Ayuda",
            "about": "Acerca de",
            "quit": "Salir",
            "yes": "Sí",
            "no": "No",
            "loading": "Cargando...",
            "error": "Error",
            "success": "Éxito",
            "warning": "Advertencia",
            "info": "Información",
            
            // 狀態欄菜單
            "permission_check": "Verificación de Permisos",
            "screenshot_ocr": "OCR de Captura",
            "translation_language": "Idioma de Traducción",
            "target_language": "Idioma Objetivo",
            "interface_language": "Idioma de Interfaz",
            "floating_icon": "Icono Flotante",
            "launch_at_login": "Iniciar al Iniciar Sesión",
            "show_floating_icon": "Mostrar Icono Flotante",
            "position": "Posición",
            "bottom_right": "Inferior Derecha",
            "bottom_left": "Inferior Izquierda",
            "top_right": "Superior Derecha",
            "top_left": "Superior Izquierda",
            "quit_app": "Salir de AITrans",
            
            // 語言選項
            "auto_detect": "Automático",
            "system_language": "Sistema",
            "english": "Inglés",
            "chinese_simplified": "Chino Simplificado",
            "chinese_traditional": "Chino Tradicional",
            "spanish": "Español",
            "french": "Francés",
            "german": "Alemán",
            "japanese": "Japonés",
            "korean": "Coreano",
            "thai": "Tailandés",
            "vietnamese": "Vietnamita",
            
            // 翻譯相關
            "translation_failed": "Traducción fallida",
            "translation_success": "Traducción exitosa",
            "translating": "Traduciendo...",
            "no_text_detected": "No se detectó texto, por favor vuelve a capturar",
            "screenshot_failed": "Captura fallida",
            "ocr_failed": "Reconocimiento OCR fallido",
            
            // 權限相關
            "permission_required": "Permiso Requerido",
            "screen_recording_permission": "Permiso de Grabación de Pantalla",
            "accessibility_permission": "Permiso de Accesibilidad",
            "permission_description": "AITrans necesita los siguientes permisos para funcionar correctamente:",
            "open_system_preferences": "Abrir Preferencias del Sistema",
            "authorized": "Autorizado",
            "unauthorized": "No Autorizado",
            "accessibility_permission_description": "Para atajos globales y gestión de ventanas",
            
            // AI面板
            "ai_detailed_explanation": "Extensión",
            "ai_analyzing": "Ejecutando...",
            "ai_analysis_failed": "Análisis AI fallido",
            "ai_provider": "Proveedor AI",
            "switch_ai_provider": "Cambiar Proveedor",
            
            // 窗口相關
            "pin_window": "Fijar Ventana",
            "unpin_window": "Desfijar Ventana",
            "take_screenshot": "Capturar Pantalla",
            "play_audio": "Reproducir Audio",
            "mute_audio": "Silenciar Audio",
            
            // 錯誤信息
            "network_error": "Error de conexión de red",
            "api_key_invalid": "Clave API inválida",
            "service_unavailable": "Servicio temporalmente no disponible",
            "unknown_error": "Error desconocido ocurrió",
            
            // 權限提示
            "screen_recording_permission_required": "Permiso de Grabación de Pantalla Requerido",
            "screen_recording_permission_description": "Por favor ve a Preferencias del Sistema > Seguridad y Privacidad > Privacidad > Grabación de Pantalla para permitir que AITrans acceda a la funcionalidad de grabación de pantalla.",
            
            // OCR相關
            "ocr_processing": "Procesando OCR...",
            "ocr_success": "Reconocimiento OCR exitoso",
            "ocr_processing_failed": "Procesamiento OCR fallido",
            "please_retry_ocr": "Por favor vuelve a intentar el reconocimiento OCR",
            
            // 翻譯相關
            "translation_processing": "Procesando traducción...",
            "please_retry_translation": "Por favor vuelve a traducir",
            "request_format_error": "Error de formato de contenido de solicitud",
            "please_retry_later": "Por favor vuelve a intentar más tarde o verifica tu conexión de red",
            
            // AI分析相關
            "ai_processing": "AI procesando...",
            "ai_analysis_error": "Error de análisis AI",
            "api_key_validation_failed": "Validación de clave API fallida, por favor verifica la configuración",
            "provider_switch_error": "Error de cambio de proveedor",
            "default_provider_saved": "Proveedor por defecto guardado exitosamente",
            "default_provider_save_failed": "Guardado de proveedor por defecto fallido"
        ],
        .french: [
            // 通用
            "app_name": "AITrans",
            "ok": "OK",
            "cancel": "Annuler",
            "close": "Fermer",
            "save": "Enregistrer",
            "delete": "Supprimer",
            "edit": "Modifier",
            "copy": "Copier",
            "paste": "Coller",
            "undo": "Annuler",
            "redo": "Refaire",
            "refresh": "Actualiser",
            "settings": "Paramètres",
            "help": "Aide",
            "about": "À propos",
            "quit": "Quitter",
            "yes": "Oui",
            "no": "Non",
            "loading": "Chargement...",
            "error": "Erreur",
            "success": "Succès",
            "warning": "Avertissement",
            "info": "Information",
            
            // 狀態欄菜單
            "permission_check": "Vérification des Permissions",
            "screenshot_ocr": "OCR de Capture",
            "translation_language": "Langue de Traduction",
            "target_language": "Langue Cible",
            "interface_language": "Langue de l'Interface",
            "floating_icon": "Icône Flottante",
            "launch_at_login": "Lancer à la Connexion",
            "show_floating_icon": "Afficher l'Icône Flottante",
            "position": "Position",
            "bottom_right": "Bas Droite",
            "bottom_left": "Bas Gauche",
            "top_right": "Haut Droite",
            "top_left": "Haut Gauche",
            "quit_app": "Quitter AITrans",
            
            // 語言選項
            "auto_detect": "Automatique",
            "system_language": "Système",
            "english": "Anglais",
            "chinese_simplified": "Chinois Simplifié",
            "chinese_traditional": "Chinois Traditionnel",
            "spanish": "Espagnol",
            "french": "Français",
            "german": "Allemand",
            "japanese": "Japonais",
            "korean": "Coréen",
            "thai": "Thaï",
            "vietnamese": "Vietnamien",
            
            // 翻譯相關
            "translation_failed": "Traduction échouée",
            "translation_success": "Traduction réussie",
            "translating": "Traduction en cours...",
            "no_text_detected": "Aucun texte détecté, veuillez recapturer",
            "screenshot_failed": "Capture échouée",
            "ocr_failed": "Reconnaissance OCR échouée",
            
            // 權限相關
            "permission_required": "Permission Requise",
            "screen_recording_permission": "Permission d'Enregistrement d'Écran",
            "accessibility_permission": "Permission d'Accessibilité",
            "permission_description": "AITrans a besoin des permissions suivantes pour fonctionner correctement :",
            "open_system_preferences": "Ouvrir les Préférences Système",
            "authorized": "Autorisé",
            "unauthorized": "Non Autorisé",
            "accessibility_permission_description": "Pour les raccourcis globaux et la gestion des fenêtres",
            
            // AI面板
            "ai_detailed_explanation": "Extension",
            "ai_analyzing": "Exécution...",
            "ai_analysis_failed": "Analyse IA échouée",
            "ai_provider": "Fournisseur IA",
            "switch_ai_provider": "Changer de Fournisseur",
            
            // 窗口相關
            "pin_window": "Épingler la Fenêtre",
            "unpin_window": "Désépingler la Fenêtre",
            "take_screenshot": "Capturer l'Écran",
            "play_audio": "Lire l'Audio",
            "mute_audio": "Couper l'Audio",
            
            // 錯誤信息
            "network_error": "Erreur de connexion réseau",
            "api_key_invalid": "Clé API invalide",
            "service_unavailable": "Service temporairement indisponible",
            "unknown_error": "Erreur inconnue survenue",
            
            // 權限提示
            "screen_recording_permission_required": "Permission d'Enregistrement d'Écran Requise",
            "screen_recording_permission_description": "Veuillez aller dans Préférences Système > Sécurité et Confidentialité > Confidentialité > Enregistrement d'écran pour permettre à AITrans d'accéder à la fonctionnalité d'enregistrement d'écran.",
            
            // OCR相關
            "ocr_processing": "Traitement OCR en cours...",
            "ocr_success": "Reconnaissance OCR réussie",
            "ocr_processing_failed": "Traitement OCR échoué",
            "please_retry_ocr": "Veuillez réessayer la reconnaissance OCR",
            
            // 翻譯相關
            "translation_processing": "Traitement de la traduction en cours...",
            "please_retry_translation": "Veuillez retraduire",
            "request_format_error": "Erreur de format de contenu de requête",
            "please_retry_later": "Veuillez réessayer plus tard ou vérifier votre connexion réseau",
            
            // AI分析相關
            "ai_processing": "IA en cours de traitement...",
            "ai_analysis_error": "Erreur d'analyse IA",
            "api_key_validation_failed": "Validation de clé API échouée, veuillez vérifier la configuration",
            "provider_switch_error": "Erreur de changement de fournisseur",
            "default_provider_saved": "Fournisseur par défaut sauvegardé avec succès",
            "default_provider_save_failed": "Sauvegarde du fournisseur par défaut échouée"
        ],
        .german: [
            // 通用
            "app_name": "AITrans",
            "ok": "OK",
            "cancel": "Abbrechen",
            "close": "Schließen",
            "save": "Speichern",
            "delete": "Löschen",
            "edit": "Bearbeiten",
            "copy": "Kopieren",
            "paste": "Einfügen",
            "undo": "Rückgängig",
            "redo": "Wiederholen",
            "refresh": "Aktualisieren",
            "settings": "Einstellungen",
            "help": "Hilfe",
            "about": "Über",
            "quit": "Beenden",
            "yes": "Ja",
            "no": "Nein",
            "loading": "Laden...",
            "error": "Fehler",
            "success": "Erfolg",
            "warning": "Warnung",
            "info": "Information",
            
            // 狀態欄菜單
            "permission_check": "Berechtigungsprüfung",
            "screenshot_ocr": "Screenshot OCR",
            "translation_language": "Übersetzungssprache",
            "target_language": "Zielsprache",
            "interface_language": "Oberflächensprache",
            "floating_icon": "Schwebendes Symbol",
            "launch_at_login": "Beim Anmelden Starten",
            "show_floating_icon": "Schwebendes Symbol anzeigen",
            "position": "Position",
            "bottom_right": "Unten Rechts",
            "bottom_left": "Unten Links",
            "top_right": "Oben Rechts",
            "top_left": "Oben Links",
            "quit_app": "AITrans beenden",
            
            // 語言選項
            "auto_detect": "Automatisch",
            "system_language": "System",
            "english": "Englisch",
            "chinese_simplified": "Vereinfachtes Chinesisch",
            "chinese_traditional": "Traditionelles Chinesisch",
            "spanish": "Spanisch",
            "french": "Französisch",
            "german": "Deutsch",
            "japanese": "Japanisch",
            "korean": "Koreanisch",
            "thai": "Thailändisch",
            "vietnamese": "Vietnamesisch",
            
            // 翻譯相關
            "translation_failed": "Übersetzung fehlgeschlagen",
            "translation_success": "Übersetzung erfolgreich",
            "translating": "Übersetzen...",
            "no_text_detected": "Kein Text erkannt, bitte erneut erfassen",
            "screenshot_failed": "Screenshot fehlgeschlagen",
            "ocr_failed": "OCR-Erkennung fehlgeschlagen",
            
            // 權限相關
            "permission_required": "Berechtigung erforderlich",
            "screen_recording_permission": "Bildschirmaufnahme-Berechtigung",
            "accessibility_permission": "Barrierefreiheits-Berechtigung",
            "permission_description": "AITrans benötigt die folgenden Berechtigungen, um ordnungsgemäß zu funktionieren:",
            "open_system_preferences": "Systemeinstellungen öffnen",
            "authorized": "Autorisiert",
            "unauthorized": "Nicht autorisiert",
            "accessibility_permission_description": "Für globale Tastenkürzel und Fensterverwaltung",
            
            // AI面板
            "ai_detailed_explanation": "Erweiterung",
            "ai_analyzing": "Ausführen...",
            "ai_analysis_failed": "KI-Analyse fehlgeschlagen",
            "ai_provider": "KI-Anbieter",
            "switch_ai_provider": "Anbieter wechseln",
            
            // 窗口相關
            "pin_window": "Fenster anheften",
            "unpin_window": "Fenster ablösen",
            "take_screenshot": "Screenshot erstellen",
            "play_audio": "Audio abspielen",
            "mute_audio": "Audio stumm schalten",
            
            // 錯誤信息
            "network_error": "Netzwerkverbindungsfehler",
            "api_key_invalid": "API-Schlüssel ungültig",
            "service_unavailable": "Service vorübergehend nicht verfügbar",
            "unknown_error": "Unbekannter Fehler aufgetreten",
            
            // 權限提示
            "screen_recording_permission_required": "Bildschirmaufnahme-Berechtigung erforderlich",
            "screen_recording_permission_description": "Bitte gehen Sie zu Systemeinstellungen > Sicherheit & Datenschutz > Datenschutz > Bildschirmaufnahme, um AITrans den Zugriff auf die Bildschirmaufnahme-Funktionalität zu ermöglichen.",
            
            // OCR相關
            "ocr_processing": "OCR wird verarbeitet...",
            "ocr_success": "OCR-Erkennung erfolgreich",
            "ocr_processing_failed": "OCR-Verarbeitung fehlgeschlagen",
            "please_retry_ocr": "Bitte OCR-Erkennung wiederholen",
            
            // 翻譯相關
            "translation_processing": "Übersetzung wird verarbeitet...",
            "please_retry_translation": "Bitte Übersetzung wiederholen",
            "request_format_error": "Anfrageinhalt-Formatfehler",
            "please_retry_later": "Bitte später erneut versuchen oder Netzwerkverbindung überprüfen",
            
            // AI分析相關
            "ai_processing": "KI wird verarbeitet...",
            "ai_analysis_error": "KI-Analysefehler",
            "api_key_validation_failed": "API-Schlüssel-Validierung fehlgeschlagen, bitte Konfiguration überprüfen",
            "provider_switch_error": "Anbieter-Wechselfehler",
            "default_provider_saved": "Standard-Anbieter erfolgreich gespeichert",
            "default_provider_save_failed": "Speichern des Standard-Anbieters fehlgeschlagen"
        ],
        .japanese: [
            // 通用
            "app_name": "AITrans",
            "ok": "OK",
            "cancel": "キャンセル",
            "close": "閉じる",
            "save": "保存",
            "delete": "削除",
            "edit": "編集",
            "copy": "コピー",
            "paste": "貼り付け",
            "undo": "元に戻す",
            "redo": "やり直し",
            "refresh": "更新",
            "settings": "設定",
            "help": "ヘルプ",
            "about": "について",
            "quit": "終了",
            "yes": "はい",
            "no": "いいえ",
            "loading": "読み込み中...",
            "error": "エラー",
            "success": "成功",
            "warning": "警告",
            "info": "情報",
            
            // 狀態欄菜單
            "permission_check": "権限チェック",
            "screenshot_ocr": "スクリーンショットOCR",
            "translation_language": "翻訳言語",
            "target_language": "対象言語",
            "interface_language": "インターフェース言語",
            "floating_icon": "フローティングアイコン",
            "launch_at_login": "ログイン時に起動",
            "show_floating_icon": "フローティングアイコンを表示",
            "position": "位置",
            "bottom_right": "右下",
            "bottom_left": "左下",
            "top_right": "右上",
            "top_left": "左上",
            "quit_app": "AITransを終了",
            
            // 語言選項
            "auto_detect": "自動検出",
            "system_language": "システム",
            "english": "英語",
            "chinese_simplified": "簡体字中国語",
            "chinese_traditional": "繁体字中国語",
            "spanish": "スペイン語",
            "french": "フランス語",
            "german": "ドイツ語",
            "japanese": "日本語",
            "korean": "韓国語",
            "thai": "タイ語",
            "vietnamese": "ベトナム語",
            
            // 翻譯相關
            "translation_failed": "翻訳に失敗しました",
            "translation_success": "翻訳が成功しました",
            "translating": "翻訳中...",
            "no_text_detected": "テキストが検出されませんでした。再キャプチャしてください",
            "screenshot_failed": "スクリーンショットに失敗しました",
            "ocr_failed": "OCR認識に失敗しました",
            
            // 權限相關
            "permission_required": "権限が必要です",
            "screen_recording_permission": "画面録画権限",
            "accessibility_permission": "アクセシビリティ権限",
            "permission_description": "AITransが正常に動作するために以下の権限が必要です：",
            "open_system_preferences": "システム環境設定を開く",
            "authorized": "承認済み",
            "unauthorized": "未承認",
            "accessibility_permission_description": "グローバルショートカットとウィンドウ管理用",
            
            // AI面板
            "ai_detailed_explanation": "拡張",
            "ai_analyzing": "実行中...",
            "ai_analysis_failed": "AI分析に失敗しました",
            "ai_provider": "AIプロバイダー",
            "switch_ai_provider": "プロバイダーを切り替え",
            
            // 窗口相關
            "pin_window": "ウィンドウを固定",
            "unpin_window": "ウィンドウの固定を解除",
            "take_screenshot": "スクリーンショットを撮る",
            "play_audio": "音声を再生",
            "mute_audio": "音声をミュート",
            
            // 錯誤信息
            "network_error": "ネットワーク接続エラー",
            "api_key_invalid": "APIキーが無効です",
            "service_unavailable": "サービスが一時的に利用できません",
            "unknown_error": "不明なエラーが発生しました",
            
            // 權限提示
            "screen_recording_permission_required": "画面録画権限が必要です",
            "screen_recording_permission_description": "システム環境設定 > セキュリティとプライバシー > プライバシー > 画面の収録で、AITransに画面録画機能へのアクセスを許可してください。",
            
            // OCR相關
            "ocr_processing": "OCRを処理中...",
            "ocr_success": "OCR認識が成功しました",
            "ocr_processing_failed": "OCR処理に失敗しました",
            "please_retry_ocr": "OCR認識を再試行してください",
            
            // 翻譯相關
            "translation_processing": "翻訳を処理中...",
            "please_retry_translation": "翻訳を再試行してください",
            "request_format_error": "リクエスト内容の形式エラー",
            "please_retry_later": "後でもう一度試すか、ネットワーク接続を確認してください",
            
            // AI分析相關
            "ai_processing": "AIを処理中...",
            "ai_analysis_error": "AI分析エラー",
            "api_key_validation_failed": "APIキーの検証に失敗しました。設定を確認してください",
            "provider_switch_error": "プロバイダー切り替えエラー",
            "default_provider_saved": "デフォルトプロバイダーが正常に保存されました",
            "default_provider_save_failed": "デフォルトプロバイダーの保存に失敗しました"
        ],
        .korean: [
            // 通用
            "app_name": "AITrans",
            "ok": "확인",
            "cancel": "취소",
            "close": "닫기",
            "save": "저장",
            "delete": "삭제",
            "edit": "편집",
            "copy": "복사",
            "paste": "붙여넣기",
            "undo": "실행 취소",
            "redo": "다시 실행",
            "refresh": "새로고침",
            "settings": "설정",
            "help": "도움말",
            "about": "정보",
            "quit": "종료",
            "yes": "예",
            "no": "아니오",
            "loading": "로딩 중...",
            "error": "오류",
            "success": "성공",
            "warning": "경고",
            "info": "정보",
            
            // 狀態欄菜單
            "permission_check": "권한 확인",
            "screenshot_ocr": "스크린샷 OCR",
            "translation_language": "번역 언어",
            "target_language": "대상 언어",
            "interface_language": "인터페이스 언어",
            "floating_icon": "플로팅 아이콘",
            "launch_at_login": "로그인 시 시작",
            "show_floating_icon": "플로팅 아이콘 표시",
            "position": "위치",
            "bottom_right": "우하단",
            "bottom_left": "좌하단",
            "top_right": "우상단",
            "top_left": "좌상단",
            "quit_app": "AITrans 종료",
            
            // 語言選項
            "auto_detect": "자동 감지",
            "system_language": "시스템",
            "english": "영어",
            "chinese_simplified": "간체 중국어",
            "chinese_traditional": "번체 중국어",
            "spanish": "스페인어",
            "french": "프랑스어",
            "german": "독일어",
            "japanese": "일본어",
            "korean": "한국어",
            "thai": "태국어",
            "vietnamese": "베트남어",
            
            // 翻譯相關
            "translation_failed": "번역 실패",
            "translation_success": "번역 성공",
            "translating": "번역 중...",
            "no_text_detected": "텍스트가 감지되지 않았습니다. 다시 캡처해 주세요",
            "screenshot_failed": "스크린샷 실패",
            "ocr_failed": "OCR 인식 실패",
            
            // 權限相關
            "permission_required": "권한 필요",
            "screen_recording_permission": "화면 녹화 권한",
            "accessibility_permission": "접근성 권한",
            "permission_description": "AITrans가 제대로 작동하려면 다음 권한이 필요합니다:",
            "open_system_preferences": "시스템 환경설정 열기",
            "authorized": "승인됨",
            "unauthorized": "미승인",
            "accessibility_permission_description": "전역 단축키 및 창 관리용",
            
            // AI面板
            "ai_detailed_explanation": "확장",
            "ai_analyzing": "실행 중...",
            "ai_analysis_failed": "AI 분석 실패",
            "ai_provider": "AI 제공업체",
            "switch_ai_provider": "제공업체 전환",
            
            // 窗口相關
            "pin_window": "창 고정",
            "unpin_window": "창 고정 해제",
            "take_screenshot": "스크린샷 찍기",
            "play_audio": "오디오 재생",
            "mute_audio": "오디오 음소거",
            
            // 錯誤信息
            "network_error": "네트워크 연결 오류",
            "api_key_invalid": "API 키가 유효하지 않습니다",
            "service_unavailable": "서비스가 일시적으로 사용할 수 없습니다",
            "unknown_error": "알 수 없는 오류가 발생했습니다",
            
            // 權限提示
            "screen_recording_permission_required": "화면 녹화 권한이 필요합니다",
            "screen_recording_permission_description": "시스템 환경설정 > 보안 및 개인 정보 보호 > 개인 정보 보호 > 화면 녹화에서 AITrans가 화면 녹화 기능에 액세스할 수 있도록 허용하세요.",
            
            // OCR相關
            "ocr_processing": "OCR 처리 중...",
            "ocr_success": "OCR 인식 성공",
            "ocr_processing_failed": "OCR 처리 실패",
            "please_retry_ocr": "OCR 인식을 다시 시도해 주세요",
            
            // 翻譯相關
            "translation_processing": "번역 처리 중...",
            "please_retry_translation": "번역을 다시 시도해 주세요",
            "request_format_error": "요청 내용 형식 오류",
            "please_retry_later": "나중에 다시 시도하거나 네트워크 연결을 확인해 주세요",
            
            // AI分析相關
            "ai_processing": "AI 처리 중...",
            "ai_analysis_error": "AI 분석 오류",
            "api_key_validation_failed": "API 키 검증 실패, 설정을 확인해 주세요",
            "provider_switch_error": "제공업체 전환 오류",
            "default_provider_saved": "기본 제공업체가 성공적으로 저장되었습니다",
            "default_provider_save_failed": "기본 제공업체 저장 실패"
        ],
        .thai: [
            // 通用
            "app_name": "AITrans",
            "ok": "ตกลง",
            "cancel": "ยกเลิก",
            "close": "ปิด",
            "save": "บันทึก",
            "delete": "ลบ",
            "edit": "แก้ไข",
            "copy": "คัดลอก",
            "paste": "วาง",
            "undo": "เลิกทำ",
            "redo": "ทำซ้ำ",
            "refresh": "รีเฟรช",
            "settings": "การตั้งค่า",
            "help": "ช่วยเหลือ",
            "about": "เกี่ยวกับ",
            "quit": "ออก",
            "yes": "ใช่",
            "no": "ไม่",
            "loading": "กำลังโหลด...",
            "error": "ข้อผิดพลาด",
            "success": "สำเร็จ",
            "warning": "คำเตือน",
            "info": "ข้อมูล",
            
            // 狀態欄菜單
            "permission_check": "ตรวจสอบสิทธิ์",
            "screenshot_ocr": "OCR ภาพหน้าจอ",
            "translation_language": "ภาษาการแปล",
            "target_language": "ภาษาปลายทาง",
            "interface_language": "ภาษาของอินเทอร์เฟซ",
            "floating_icon": "ไอคอนลอย",
            "launch_at_login": "เริ่มต้นเมื่อเข้าสู่ระบบ",
            "show_floating_icon": "แสดงไอคอนลอย",
            "position": "ตำแหน่ง",
            "bottom_right": "ล่างขวา",
            "bottom_left": "ล่างซ้าย",
            "top_right": "บนขวา",
            "top_left": "บนซ้าย",
            "quit_app": "ออกจาก AITrans",
            
            // 語言選項
            "auto_detect": "อัตโนมัติ",
            "system_language": "ระบบ",
            "english": "อังกฤษ",
            "chinese_simplified": "จีนตัวย่อ",
            "chinese_traditional": "จีนตัวเต็ม",
            "spanish": "สเปน",
            "french": "ฝรั่งเศส",
            "german": "เยอรมัน",
            "japanese": "ญี่ปุ่น",
            "korean": "เกาหลี",
            "thai": "ไทย",
            "vietnamese": "เวียดนาม",
            
            // 翻譯相關
            "translation_failed": "การแปลล้มเหลว",
            "translation_success": "การแปลสำเร็จ",
            "translating": "กำลังแปล...",
            "no_text_detected": "ไม่พบข้อความ กรุณาถ่ายภาพใหม่",
            "screenshot_failed": "การถ่ายภาพหน้าจอล้มเหลว",
            "ocr_failed": "การจดจำ OCR ล้มเหลว",
            
            // 權限相關
            "permission_required": "ต้องการสิทธิ์",
            "screen_recording_permission": "สิทธิ์การบันทึกหน้าจอ",
            "accessibility_permission": "สิทธิ์การเข้าถึง",
            "permission_description": "AITrans ต้องการสิทธิ์ต่อไปนี้เพื่อทำงานได้อย่างถูกต้อง:",
            "open_system_preferences": "เปิดการตั้งค่าระบบ",
            "authorized": "ได้รับอนุญาต",
            "unauthorized": "ไม่ได้รับอนุญาต",
            "accessibility_permission_description": "สำหรับคีย์ลัดทั่วโลกและการจัดการหน้าต่าง",
            "permission_guide_title": "คู่มือการตั้งค่าสิทธิ์",
            "screen_recording_guide": "1. ในหน้าต่างการตั้งค่าระบบที่เปิดขึ้น ให้หา 'การบันทึกหน้าจอ' ในแถบด้านซ้าย\n2. ค้นหา 'AITrans' ในรายการแอปพลิเคชัน\n3. หากไม่มี AITrans ในรายการ ให้คลิกปุ่ม '+' เพื่อเพิ่ม\n4. ติ๊กช่องถัดจาก 'AITrans' เพื่อเปิดใช้งานสิทธิ์การบันทึกหน้าจอ\n5. คลิก 'รีเฟรชสิทธิ์' ด้านล่างเพื่ออัปเดตสถานะ",
            "accessibility_guide": "1. ในหน้าต่างการตั้งค่าระบบที่เปิดขึ้น ให้หา 'การเข้าถึง' ในแถบด้านซ้าย\n2. ค้นหา 'AITrans' ในรายการแอปพลิเคชัน\n3. หากไม่มี AITrans ในรายการ ให้คลิกปุ่ม '+' เพื่อเพิ่ม\n4. ติ๊กช่องถัดจาก 'AITrans' เพื่อเปิดใช้งานสิทธิ์การเข้าถึง\n5. คลิก 'รีเฟรชสิทธิ์' ด้านล่างเพื่ออัปเดตสถานะ",
            "got_it": "เข้าใจแล้ว",
            "refresh_permissions": "รีเฟรชสิทธิ์",
            
            // AI面板
            "ai_detailed_explanation": "ส่วนขยาย",
            "ai_analyzing": "กำลังดำเนินการ...",
            "ai_analysis_failed": "การวิเคราะห์ AI ล้มเหลว",
            "ai_provider": "ผู้ให้บริการ AI",
            "switch_ai_provider": "เปลี่ยนผู้ให้บริการ",
            
            // 窗口相關
            "pin_window": "ปักหมุดหน้าต่าง",
            "unpin_window": "ยกเลิกการปักหมุดหน้าต่าง",
            "take_screenshot": "ถ่ายภาพหน้าจอ",
            "play_audio": "เล่นเสียง",
            "mute_audio": "ปิดเสียง",
            
            // 錯誤信息
            "network_error": "ข้อผิดพลาดการเชื่อมต่อเครือข่าย",
            "api_key_invalid": "คีย์ API ไม่ถูกต้อง",
            "service_unavailable": "บริการไม่พร้อมใช้งานชั่วคราว",
            "unknown_error": "เกิดข้อผิดพลาดที่ไม่ทราบ",
            
            // 權限提示
            "screen_recording_permission_required": "ต้องการสิทธิ์การบันทึกหน้าจอ",
            "screen_recording_permission_description": "กรุณาไปที่การตั้งค่าระบบ > ความปลอดภัยและความเป็นส่วนตัว > ความเป็นส่วนตัว > การบันทึกหน้าจอ เพื่ออนุญาตให้ AITrans เข้าถึงฟังก์ชันการบันทึกหน้าจอ",
            
            // OCR相關
            "ocr_processing": "กำลังประมวลผล OCR...",
            "ocr_success": "การจดจำ OCR สำเร็จ",
            "ocr_processing_failed": "การประมวลผล OCR ล้มเหลว",
            "please_retry_ocr": "กรุณาลองจดจำ OCR อีกครั้ง",
            
            // 翻譯相關
            "translation_processing": "กำลังประมวลผลการแปล...",
            "please_retry_translation": "กรุณาลองแปลอีกครั้ง",
            "request_format_error": "ข้อผิดพลาดรูปแบบเนื้อหาการร้องขอ",
            "please_retry_later": "กรุณาลองอีกครั้งในภายหลังหรือตรวจสอบการเชื่อมต่อเครือข่าย",
            
            // AI分析相關
            "ai_processing": "AI กำลังประมวลผล...",
            "ai_analysis_error": "ข้อผิดพลาดการวิเคราะห์ AI",
            "api_key_validation_failed": "การตรวจสอบคีย์ API ล้มเหลว กรุณาตรวจสอบการตั้งค่า",
            "provider_switch_error": "ข้อผิดพลาดการเปลี่ยนผู้ให้บริการ",
            "default_provider_saved": "บันทึกผู้ให้บริการเริ่มต้นสำเร็จ",
            "default_provider_save_failed": "การบันทึกผู้ให้บริการเริ่มต้นล้มเหลว"
        ],
        .vietnamese: [
            // 通用
            "app_name": "AITrans",
            "ok": "OK",
            "cancel": "Hủy",
            "close": "Đóng",
            "save": "Lưu",
            "delete": "Xóa",
            "edit": "Chỉnh sửa",
            "copy": "Sao chép",
            "paste": "Dán",
            "undo": "Hoàn tác",
            "redo": "Làm lại",
            "refresh": "Làm mới",
            "settings": "Cài đặt",
            "help": "Trợ giúp",
            "about": "Giới thiệu",
            "quit": "Thoát",
            "yes": "Có",
            "no": "Không",
            "loading": "Đang tải...",
            "error": "Lỗi",
            "success": "Thành công",
            "warning": "Cảnh báo",
            "info": "Thông tin",
            
            // 狀態欄菜單
            "permission_check": "Kiểm tra quyền",
            "screenshot_ocr": "OCR ảnh chụp màn hình",
            "translation_language": "Ngôn ngữ dịch",
            "target_language": "Ngôn ngữ đích",
            "interface_language": "Ngôn ngữ giao diện",
            "floating_icon": "Biểu tượng nổi",
            "launch_at_login": "Khởi động khi đăng nhập",
            "show_floating_icon": "Hiển thị biểu tượng nổi",
            "position": "Vị trí",
            "bottom_right": "Dưới phải",
            "bottom_left": "Dưới trái",
            "top_right": "Trên phải",
            "top_left": "Trên trái",
            "quit_app": "Thoát AITrans",
            
            // 語言選項
            "auto_detect": "Tự động",
            "system_language": "Hệ thống",
            "english": "Tiếng Anh",
            "chinese_simplified": "Tiếng Trung giản thể",
            "chinese_traditional": "Tiếng Trung phồn thể",
            "spanish": "Tiếng Tây Ban Nha",
            "french": "Tiếng Pháp",
            "german": "Tiếng Đức",
            "japanese": "Tiếng Nhật",
            "korean": "Tiếng Hàn",
            "thai": "Tiếng Thái",
            "vietnamese": "Tiếng Việt",
            
            // 翻譯相關
            "translation_failed": "Dịch thất bại",
            "translation_success": "Dịch thành công",
            "translating": "Đang dịch...",
            "no_text_detected": "Không phát hiện văn bản, vui lòng chụp lại",
            "screenshot_failed": "Chụp màn hình thất bại",
            "ocr_failed": "Nhận dạng OCR thất bại",
            
            // 權限相關
            "permission_required": "Cần quyền",
            "screen_recording_permission": "Quyền ghi màn hình",
            "accessibility_permission": "Quyền trợ năng",
            "permission_description": "AITrans cần các quyền sau để hoạt động đúng cách:",
            "open_system_preferences": "Mở tùy chọn hệ thống",
            "authorized": "Đã ủy quyền",
            "unauthorized": "Chưa ủy quyền",
            "accessibility_permission_description": "Cho phím tắt toàn cục và quản lý cửa sổ",
            
            // AI面板
            "ai_detailed_explanation": "Mở rộng",
            "ai_analyzing": "Đang thực thi...",
            "ai_analysis_failed": "Phân tích AI thất bại",
            "ai_provider": "Nhà cung cấp AI",
            "switch_ai_provider": "Chuyển nhà cung cấp",
            
            // 窗口相關
            "pin_window": "Ghim cửa sổ",
            "unpin_window": "Bỏ ghim cửa sổ",
            "take_screenshot": "Chụp màn hình",
            "play_audio": "Phát âm thanh",
            "mute_audio": "Tắt tiếng",
            
            // 錯誤信息
            "network_error": "Lỗi kết nối mạng",
            "api_key_invalid": "Khóa API không hợp lệ",
            "service_unavailable": "Dịch vụ tạm thời không khả dụng",
            "unknown_error": "Đã xảy ra lỗi không xác định",
            
            // 權限提示
            "screen_recording_permission_required": "Cần quyền ghi màn hình",
            "screen_recording_permission_description": "Vui lòng vào Tùy chọn hệ thống > Bảo mật và Quyền riêng tư > Quyền riêng tư > Ghi màn hình để cho phép AITrans truy cập chức năng ghi màn hình.",
            
            // OCR相關
            "ocr_processing": "Đang xử lý OCR...",
            "ocr_success": "Nhận dạng OCR thành công",
            "ocr_processing_failed": "Xử lý OCR thất bại",
            "please_retry_ocr": "Vui lòng thử lại nhận dạng OCR",
            
            // 翻譯相關
            "translation_processing": "Đang xử lý bản dịch...",
            "please_retry_translation": "Vui lòng thử lại bản dịch",
            "request_format_error": "Lỗi định dạng nội dung yêu cầu",
            "please_retry_later": "Vui lòng thử lại sau hoặc kiểm tra kết nối mạng",
            
            // AI分析相關
            "ai_processing": "AI đang xử lý...",
            "ai_analysis_error": "Lỗi phân tích AI",
            "api_key_validation_failed": "Xác thực khóa API thất bại, vui lòng kiểm tra cấu hình",
            "provider_switch_error": "Lỗi chuyển nhà cung cấp",
            "default_provider_saved": "Lưu nhà cung cấp mặc định thành công",
            "default_provider_save_failed": "Lưu nhà cung cấp mặc định thất bại"
        ],
        .chinese: [
            // 通用
            "app_name": "AITrans",
            "ok": "确定",
            "cancel": "取消",
            "close": "关闭",
            "save": "保存",
            "delete": "删除",
            "edit": "编辑",
            "copy": "复制",
            "paste": "粘贴",
            "undo": "撤销",
            "redo": "重做",
            "refresh": "刷新",
            "settings": "设置",
            "help": "帮助",
            "about": "关于",
            "quit": "退出",
            "yes": "是",
            "no": "否",
            "loading": "加载中...",
            "error": "错误",
            "success": "成功",
            "warning": "警告",
            "info": "信息",
            
            // 状态栏菜单
            "permission_check": "权限检查",
            "screenshot_ocr": "截图识别",
            "translation_language": "翻译语言",
            "target_language": "目标语言",
            "interface_language": "界面语言",
            "floating_icon": "悬浮快捷图标",
            "launch_at_login": "开机时启动",
            "show_floating_icon": "显示悬浮图标",
            "position": "位置",
            "bottom_right": "右下角",
            "bottom_left": "左下角",
            "top_right": "右上角",
            "top_left": "左上角",
            "quit_app": "退出 AITrans",
            
            // 语言选项
            "auto_detect": "自动检测",
            "system_language": "系统语言",
            "english": "英语",
            "chinese_simplified": "简体中文",
            "chinese_traditional": "繁体中文",
            "spanish": "西班牙语",
            "french": "法语",
            "german": "德语",
            "japanese": "日语",
            "korean": "韩语",
            "thai": "泰语",
            "vietnamese": "越南语",
            
            // 翻译相关
            "translation_failed": "翻译失败",
            "translation_success": "翻译成功",
            "translating": "翻译中...",
            "no_text_detected": "未识别到文本，请重新截图",
            "screenshot_failed": "截图失败",
            "ocr_failed": "OCR识别失败",
            
            // 权限相关
            "permission_required": "需要权限",
            "screen_recording_permission": "屏幕录制权限",
            "accessibility_permission": "辅助功能权限",
            "permission_description": "AITrans 需要以下权限才能正常工作：",
            "open_system_preferences": "打开系统偏好设置",
            "authorized": "已授权",
            "unauthorized": "未授权",
            "accessibility_permission_description": "用于全局快捷键和窗口管理",
            "permission_guide_title": "权限设置指引",
            "screen_recording_guide": "1. 在打开的系统设置窗口中，在左侧边栏找到「屏幕录制」\n2. 在应用程序列表中查找「AITrans」\n3. 如果列表中没有 AITrans，请点击「+」按钮添加\n4. 勾选「AITrans」旁边的复选框以启用屏幕录制权限\n5. 点击下方的「刷新权限」按钮更新状态",
            "accessibility_guide": "1. 在打开的系统设置窗口中，在左侧边栏找到「辅助功能」\n2. 在应用程序列表中查找「AITrans」\n3. 如果列表中没有 AITrans，请点击「+」按钮添加\n4. 勾选「AITrans」旁边的复选框以启用辅助功能权限\n5. 点击下方的「刷新权限」按钮更新状态",
            "got_it": "知道了",
            "refresh_permissions": "刷新权限",
            
            // AI面板
            "ai_detailed_explanation": "扩展",
            "ai_analyzing": "执行中...",
            "ai_analysis_failed": "AI 分析失败",
            "ai_provider": "AI 厂商",
            "switch_ai_provider": "切换 AI 厂商",
            
            // 窗口相关
            "pin_window": "固定窗口",
            "unpin_window": "取消固定",
            "take_screenshot": "截图",
            "play_audio": "播放音频",
            "mute_audio": "静音",
            
            // 错误信息
            "network_error": "网络连接错误",
            "api_key_invalid": "API密钥无效",
            "service_unavailable": "服务暂时不可用",
            "unknown_error": "发生未知错误",
            
            // 权限提示
            "screen_recording_permission_required": "需要屏幕录制权限",
            "screen_recording_permission_description": "请在系统偏好设置 > 安全性与隐私 > 隐私 > 屏幕录制中，允许AITrans访问屏幕录制功能。",
            
            // OCR相关
            "ocr_processing": "正在处理OCR...",
            "ocr_success": "OCR识别成功",
            "ocr_processing_failed": "OCR处理失败",
            "please_retry_ocr": "请重新进行OCR识别",
            
            // 翻译相关
            "translation_processing": "正在处理翻译...",
            "please_retry_translation": "请重新翻译",
            "request_format_error": "请求内容格式错误",
            "please_retry_later": "请稍后重试或检查网络连接",
            
            // AI分析相关
            "ai_processing": "AI正在处理...",
            "ai_analysis_error": "AI分析错误",
            "api_key_validation_failed": "API密钥验证失败，请检查配置",
            "provider_switch_error": "厂商切换错误",
            "default_provider_saved": "默认厂商保存成功",
            "default_provider_save_failed": "默认厂商保存失败"
        ]
    ]
    
    private init() {
        loadLanguageSetting()
    }
    
    /// 获取本地化字符串
    /// - Parameter key: 字符串键
    /// - Returns: 本地化字符串
    func localizedString(for key: String) -> String {
        return localizedStrings[currentLanguage]?[key] ?? key
    }
    
    /// 切换语言
    /// - Parameter language: 目标语言
    func setLanguage(_ language: Language) {
        currentLanguage = language
        saveLanguageSetting()
        
        // 发送语言切换通知
        NotificationCenter.default.post(
            name: NSNotification.Name("LanguageChanged"),
            object: nil,
            userInfo: ["language": language]
        )
    }
    
    /// 加载语言设置
    private func loadLanguageSetting() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "AITransAppLanguage"),
           let language = Language(rawValue: savedLanguage) {
            currentLanguage = language
        } else {
            // 默认使用英文
            currentLanguage = .english
        }
    }
    
    /// 保存语言设置
    private func saveLanguageSetting() {
        UserDefaults.standard.set(currentLanguage.rawValue, forKey: "AITransAppLanguage")
    }
    
    /// 获取当前语言的显示名称
    var currentLanguageDisplayName: String {
        return currentLanguage.displayName
    }
    
    /// 获取所有支持的语言
    var supportedLanguages: [Language] {
        return Language.allCases
    }
}

// MARK: - 便捷访问方法
extension LocalizationManager {
    /// 获取本地化字符串的便捷方法
    static func localized(_ key: String) -> String {
        return shared.localizedString(for: key)
    }
}

// MARK: - 常用字符串的便捷访问
extension LocalizationManager {
    var appName: String { localizedString(for: "app_name") }
    var ok: String { localizedString(for: "ok") }
    var cancel: String { localizedString(for: "cancel") }
    var close: String { localizedString(for: "close") }
    var quit: String { localizedString(for: "quit") }
    var settings: String { localizedString(for: "settings") }
    var help: String { localizedString(for: "help") }
    var about: String { localizedString(for: "about") }
    var loading: String { localizedString(for: "loading") }
    var error: String { localizedString(for: "error") }
    var success: String { localizedString(for: "success") }
    var warning: String { localizedString(for: "warning") }
    var info: String { localizedString(for: "info") }
    
    // 翻译相关
    var translationFailed: String { localizedString(for: "translation_failed") }
    var translationSuccess: String { localizedString(for: "translation_success") }
    var translating: String { localizedString(for: "translating") }
    var noTextDetected: String { localizedString(for: "no_text_detected") }
    
    // 权限相关
    var permissionRequired: String { localizedString(for: "permission_required") }
    var screenRecordingPermission: String { localizedString(for: "screen_recording_permission") }
    var accessibilityPermission: String { localizedString(for: "accessibility_permission") }
    var permissionDescription: String { localizedString(for: "permission_description") }
    var openSystemPreferences: String { localizedString(for: "open_system_preferences") }
    var authorized: String { localizedString(for: "authorized") }
    var unauthorized: String { localizedString(for: "unauthorized") }
    var accessibilityPermissionDescription: String { localizedString(for: "accessibility_permission_description") }
    
    // 状态栏菜单
    var permissionCheck: String { localizedString(for: "permission_check") }
    var screenshotOCR: String { localizedString(for: "screenshot_ocr") }
    var translationLanguage: String { localizedString(for: "translation_language") }
    var targetLanguage: String { localizedString(for: "target_language") }
    var interfaceLanguage: String { localizedString(for: "interface_language") }
    var floatingIcon: String { localizedString(for: "floating_icon") }
    var launchAtLogin: String { localizedString(for: "launch_at_login") }
    var showFloatingIcon: String { localizedString(for: "show_floating_icon") }
    var position: String { localizedString(for: "position") }
    var bottomRight: String { localizedString(for: "bottom_right") }
    var bottomLeft: String { localizedString(for: "bottom_left") }
    var topRight: String { localizedString(for: "top_right") }
    var topLeft: String { localizedString(for: "top_left") }
    var quitApp: String { localizedString(for: "quit_app") }
    
    // 语言选项
    var autoDetect: String { localizedString(for: "auto_detect") }
    var systemLanguage: String { localizedString(for: "system_language") }
    var english: String { localizedString(for: "english") }
    var chineseSimplified: String { localizedString(for: "chinese_simplified") }
    var chineseTraditional: String { localizedString(for: "chinese_traditional") }
    var spanish: String { localizedString(for: "spanish") }
    var french: String { localizedString(for: "french") }
    var german: String { localizedString(for: "german") }
    var japanese: String { localizedString(for: "japanese") }
    var korean: String { localizedString(for: "korean") }
    var thai: String { localizedString(for: "thai") }
    var vietnamese: String { localizedString(for: "vietnamese") }
    
    // AI面板
    var aiDetailedExplanation: String { localizedString(for: "ai_detailed_explanation") }
    var aiAnalyzing: String { localizedString(for: "ai_analyzing") }
    var aiAnalysisFailed: String { localizedString(for: "ai_analysis_failed") }
    var aiProvider: String { localizedString(for: "ai_provider") }
    var switchAIProvider: String { localizedString(for: "switch_ai_provider") }
    
    // 窗口相关
    var pinWindow: String { localizedString(for: "pin_window") }
    var unpinWindow: String { localizedString(for: "unpin_window") }
    var takeScreenshot: String { localizedString(for: "take_screenshot") }
    var playAudio: String { localizedString(for: "play_audio") }
    var muteAudio: String { localizedString(for: "mute_audio") }
    
    // 错误信息
    var networkError: String { localizedString(for: "network_error") }
    var apiKeyInvalid: String { localizedString(for: "api_key_invalid") }
    var serviceUnavailable: String { localizedString(for: "service_unavailable") }
    var unknownError: String { localizedString(for: "unknown_error") }
}
