# HANDOFF.md - StarNote Project Handoff Document

> **Son Güncelleme:** 2025-02-11
> **Amaç:** Yeni chat session'ında kaldığımız yerden devam etmek için özet
> **Durum:** Dark Theme Fix & UI İyileştirmeleri - Aktif

---

## 🛠️ DEVELOPMENT SETUP: Claude Code Multi-Agent

### Kurulu Sistem
- **Claude Code CLI:** v2.1.34
- **Model:** Opus 4.6 (Claude Max)
- **Workspace:** `/mnt/c/Users/aktas/source/repos/starnote_drawing_workspace`

### 4 Agent Tanımlı (.claude/agents/)

| Agent | Model | Rol | Tools |
|-------|-------|-----|-------|
| `senior-architect` | opus | Mimari tasarım, analiz, ADR | Read, Grep, Glob, Bash |
| `flutter-developer` | sonnet | Implementation, UI, state | Read, Write, Edit, Bash, Glob, Grep |
| `qa-engineer` | sonnet | Test yazma, coverage | Read, Write, Edit, Bash, Glob, Grep |
| `code-reviewer` | opus | Kod review, quality check | Read, Grep, Glob, Bash |

### Agent Kullanımı
```bash
# Terminalde
@senior-architect [görev açıklaması]
@flutter-developer [görev açıklaması]
@qa-engineer [görev açıklaması]
@code-reviewer [görev açıklaması]

# Mevcut agent'ları görme
/agents
```

---

## 🎯 AKTİF GÖREV: UI Fix'ler (Dark Theme + UX)

### ✅ Tamamlanan (Commit: a0ca9ad)
**Commit mesajı:** `fix(theme): make Documents screen widgets dark-theme-aware`

| Fix | Dosya | Açıklama |
|-----|-------|----------|
| ✅ Issue 1 | `app_card.dart` | Theme-aware renkler |
| ✅ Issue 2-3 | `folder_card.dart` | Text/checkbox düzeltildi |
| ✅ Issue 4-6 | `document_card_helpers.dart` | Tüm helper'lar düzeltildi |
| ✅ Issue 7 | `selection_mode_header.dart` | Dark mode görünür |
| ✅ Issue 8 | `app_empty_state.dart` | Theme-aware renkler |
| ✅ Issue 9 | `documents_empty_states.dart` | Düzeltildi |
| ✅ Issue 10 | `breadcrumb_navigation.dart` | Düzeltildi |
| ✅ Issue 11 | `app_colors.dart` | outlineDark 0xFF2C2C2C |
| ✅ Tests | 3 yeni test dosyası | 49 test eklendi |

### 🔴 Tablet Test Sorunları (Yeni Bulunan)

| Sorun | Öncelik | Açıklama |
|-------|---------|----------|
| PDF Thumbnail | 🔴 Yüksek | Documents ekranında PDF kapak görüntüsü görünmüyor |
| Settings Dark Theme | 🔴 Yüksek | Ayarlar ekranında yazılar okunmuyor |

### 🟡 Bekleyen Issue'lar (12-17)

| Issue | Dosya | Açıklama |
|-------|-------|----------|
| 12 | `documents_screen.dart` | 1831 satır → 300 satır parçalara böl |
| 13 | `new_document_dialog.dart` | 451 satır → böl |
| 14 | Modal'lar | Keyboard overflow - viewInsets padding |
| 15 | Grid view | Hardcoded spacing → AppSpacing.* |
| 16 | `sidebar.dart` | colorScheme → AppColors tokens |
| 17 | List tiles | Magic numbers (52, 64) → AppSpacing.* |

---

## 📋 SIRADAKI ADIMLAR

1. **PDF Thumbnail düzelt** - @flutter-developer
2. **Settings dark theme düzelt** - @flutter-developer
3. **Tablet test tekrar** - Manuel
4. **Issue 12-17 düzelt** - @flutter-developer
5. **Code review** - @code-reviewer
6. **Final commit**

---

## 🚀 Yeni Chat'te Başlarken

```
StarNote projesine devam ediyoruz. HANDOFF.md dosyasını paylaşıyorum.

SETUP: Claude Code CLI ile multi-agent workflow kullanıyoruz.
- 4 agent tanımlı: senior-architect, flutter-developer, qa-engineer, code-reviewer
- Agent'ları @agent-name ile çağır

SON DURUM: Dark theme fix'leri (Issue 1-11) tamamlandı ve commit edildi.

AKTİF SORUNLAR (Tablet test):
1. PDF thumbnail görünmüyor (Documents ekranı)
2. Settings ekranında dark theme'da yazılar okunmuyor

BEKLEYEN:
- Issue 12-17 (file splitting, hardcoded spacing)

İLK GÖREV:
@flutter-developer Tablet testinde 2 sorun buldum:
1. Documents ekranında PDF kapak görüntüsü (thumbnail) görünmüyor
2. Settings ekranında dark tema'da yazılar okunmuyor - hardcoded renkler var
İkisini de düzelt, sonra flutter analyze çalıştır.
```

---

## 📁 Proje Yapısı (Özet)

```
starnote_drawing_workspace/
├── .claude/
│   ├── CLAUDE.md              # Proje kuralları (tüm agent'lar okur)
│   ├── agents/                # Agent tanımları
│   │   ├── senior-architect.md
│   │   ├── flutter-developer.md
│   │   ├── qa-engineer.md
│   │   └── code-reviewer.md
│   └── agent-memory/          # Agent hafızası
├── example_app/               # Ana uygulama
├── packages/
│   ├── drawing_core/          # Pure Dart çizim motoru
│   └── drawing_ui/            # Flutter widget'ları
└── docs/
    └── DESIGN_SYSTEM_MASTER_PLAN.md
```

---

## ⚠️ Önemli Kurallar

1. **Tema:** Hardcoded renk YASAK → `AppColors.*` veya `Theme.of(context).colorScheme.*`
2. **Spacing:** Hardcoded değer YASAK → `AppSpacing.*`
3. **Dosya limiti:** Max 300 satır per file
4. **Touch target:** Min 48x48dp
5. **Import:** Barrel exports kullan, relative import YASAK
6. **Test:** Her değişiklik sonrası `flutter analyze`
7. **Flutter çalıştırma (WSL):** `cmd.exe /c "flutter run"`

---

## 🛠 VS Code Workflow

### Terminal Setup
1. **Tab 1 - Claude Code:**
   ```bash
   wsl
   source ~/.bashrc
   cd /mnt/c/Users/aktas/source/repos/starnote_drawing_workspace
   claude
   ```

2. **Tab 2 - Flutter Run:**
   ```bash
   cd example_app
   cmd.exe /c "flutter run"
   ```

### Sağ Panel
- Claude Code extension kullanılabilir
- `@agent-name` syntax çalışır

---

## ✅ Önceki Tamamlanan Fazlar

### Design System (Phase 0-9) ✅
- Design tokens (colors, spacing, typography)
- Core components (buttons, inputs, feedback)
- Responsive system
- Auth screens
- Documents screen (folder system, breadcrumb)
- Settings screen
- Template selection

### Drawing Library ✅
- Phase 0-4D: Temel çizim motoru (738 test)
- Phase 4E: PDF Performans Optimizasyonu
- Phase 5A-5F: PDF Import/Export, Multi-page

---

## 📊 Test Durumu

- 738+ mevcut test
- 49 yeni dark theme testi eklendi
- flutter analyze: 17 pre-existing info/warning (bizim değişikliklerden değil)

---

*StarNote - Multi-Agent Development Workflow 🚀*
