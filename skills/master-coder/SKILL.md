---
name: master-coder
description: MASTER coder - choose best language/framework for any task
license: MIT
---

# MASTER CODER - Complete Development Guide

## 🎯 QUICK DECISION MATRIX

| Task | Best Language | Best Framework |
|------|--------------|---------------|
| Windows Desktop App | **C#** | WPF (best graphics) |
| Cross-platform Desktop | **C#** | Avalonia or Uno |
| Mobile + Desktop | **C#** | .NET MAUI |
| Game / Graphics | **C++** | Qt + Skia or ImGui |
| Quick Script Tool | **Python** | PySimpleGUI or CustomTkinter |
| Professional Python App | **Python** | PySide6 |
| Data Dashboard | **Python** | Streamlit |
| Android/iOS App | **Python** | Kivy |
| High Performance | **C++** | Qt + DirectX |
| Game Engine | **C++** | Custom engine + SDL2 |

## 🎨 VISUALS & GRAPHICS BEST

### Color Palette (Modern Dark Theme)
```
Background:      #1a1a2e (deep navy)
Card:          #2d2d44 (elevated)
Accent Cyan:   #00ffc8
Accent Purple:  #7b2cbf
Text:          #ffffff
Text Muted:    #a0a0b0
Success:      #00e676
Warning:      #ffab00
Error:        #ff5252
```

### Fonts
- **Headers**: Inter Bold, Roboto Bold
- **Body**: Inter Regular
- **Code**: JetBrains Mono, Fira Code

### Visual Effects
```python
def modern_card():
    return {
        'background': '#2d2d44',
        'border_radius': 12,
        'padding': 16,
        'shadow_blur': 20,
        'shadow_color': 'black30'
    }

def glow_effect(color, intensity=1.0):
    return {
        'blur': 20 * intensity,
        'color': (*color, int(150 * intensity)),
    }
```

## 🚀 BEST PRACTICES BY LANGUAGE

### C++
- Use Qt 6 for GUIs (best balance of power/ease)
- Use Dear ImGui for game tools
- Use DirectX 12 for games (not OpenGL)
- Use vcpkg for package management

### C# 
- Use WPF for Windows-only (best graphics)
- Use .NET MAUI for cross-platform
- Use SkiaSharp for custom rendering
- Use CommunityToolkit.Mvvm for MVVM

### Python
- Use CustomTkinter for quick modern UIs
- Use PySide6 for professional apps
- Use Streamlit for data dashboards
- Use Pygame for 2D games
- Use ursina for 3D (easiest)

## 📁 PROJECT STRUCTURE

```
project/
├── src/
│   ├── main.py           # Entry point
│   ├── ui/             # UI components
│   ├── core/          # Business logic
│   └── assets/         # Images, fonts
├── tests/
├── docs/
├── README.md
└── requirements.txt    # or pyproject.toml
```

## 🛠️ ESSENTIAL TOOLS

### Windows Development
| Tool | Use |
|------|-----|
| Visual Studio 2022 | C++/C# IDE |
| VS Code | Python/General |
| .NET 8 | C# runtime |
| Qt Creator | Qt development |
| vcpkg | C++ packages |
| Rider | Cross-platform .NET |

### Python Tools
| Tool | Use |
|------|-----|
| uv | Fast package manager |
| black | Formatter |
| ruff | Linter |
| mypy | Type checker |
| pytest | Testing |
| nox | Automation |

## 🎓 LEARNING PATHS

### Beginner → Pro: C++
```
1. C++ basics ( pointers, memory)
2. STL containers
3. Qt basics (widgets, signals)
4. Qt graphics (QPainter)
5. DirectX 12 or Vulkan
6. Build custom engine
```

### Beginner → Pro: C#
```
1. C# basics
2. WPF basics (XAML, bindings)
3. MVVM pattern
4. Custom controls (Styles, Templates)
5. SkiaSharp graphics
6. Custom rendering
```

### Beginner → Pro: Python
```
1. Python basics
2. Tkinter basics
3. CustomTkinter modern UI
4. PySide6 professional
5. PyGame basics
6. Custom graphics (PyGame + effects)
```

## 🔗 KEY RESOURCES

| Resource | URL |
|---------|-----|
| Qt 6 Docs | doc.qt.io/qt-6 |
| WPF Docs | learn.microsoft.com/dotnet/wpf |
| PySide Docs | doc.qt.io/qt-6/pyside |
| PyGame | pygame.org/docs/ |
| Streamlit | docs.streamlit.io |
| vcpkg | github.com/microsoft/vcpkg |