---
name: master-coder-cpp
description: MASTER C++ Windows development - Qt, Win32, DirectX, graphics
license: MIT
---

# MASTER CODER: C++ for Windows

## 📚 BEST GUI FRAMEWORKS (2025-2026)

| Framework | Best For | Windows Support | License |
|----------|---------|-------------|----------|
| **Qt 6** | Professional desktop apps, cross-platform | Excellent (Win10/11) | GPL/Commercial |
| **Dear ImGui** | Game tools, dashboards, immediate mode | Excellent | MIT |
| **WUI** | Lightweight native apps | Excellent (XP-11) | MIT |
| **wxWidgets** | Native look apps | Excellent | wxWindows |
| **FLTK** | Simple lightweight apps | Good | LGPL |
| **Win32/MFC** | Windows-only legacy | Native | Microsoft |

## 🎨 BEST GRAPHICS LIBRARIES

| Library | Use Case | Features |
|---------|---------|----------|
| **Qt RHI** | Cross-GPU rendering | Vulkan, Direct3D, Metal, OpenGL |
| **DirectX 12** | Windows games | Ultimate performance |
| **OpenGL** | Cross-platform | WebGL compatible |
| **Vulkan** | Modern GPU | Low-level control |
| **Skia** | 2D rendering | Google-backed |
| **SDL2** | Game foundation | Simple, powerful |

## 🚀 QUICK START TEMPLATES

### Qt 6 Application
```cpp
#include <QApplication>
#include <QWidget>
#include <QPushButton>

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);
    QWidget window;
    window.setWindowTitle("My App");
    window.setGeometry(100, 100, 400, 300);
    
    QPushButton button("Click Me", &window);
    button.setGeometry(150, 120, 100, 40);
    QObject::connect(&button, &QPushButton::clicked, [](){
        qDebug() << "Clicked!";
    });
    
    window.show();
    return app.exec();
}
```

### Qt with Custom Graphics
```cpp
#include <QPainter>
#include <QWidget>

class Canvas : public QWidget {
protected:
    void paintEvent(QPaintEvent*) override {
        QPainter painter(this);
        // Draw gradient background
        QLinearGradient gradient(0, 0, width(), height());
        gradient.setColorAt(0, QColor("#1a1a2e"));
        gradient.setColorAt(1, QColor("#16213e"));
        painter.fillRect(rect(), gradient);
        
        // Draw circle with glow
        painter.setPen(Qt::NoPen);
        painter.setBrush(QColor(0, 255, 200, 150));
        painter.drawEllipse(width()/2 - 50, height()/2 - 50, 100, 100);
    }
};
```

### Dear ImGui Integration
```cpp
#include <imgui.h>
#include <imgui_impl_win32.h>
#include <windows.h>

// In your WinMain:
// 1. Create window with Win32
// 2. ImGui::CreateContext()
// 3. ImGui_ImplWin32_Init(hwnd)
// 4. Render loop with ImGui_ImplWin32_NewFrame()
```

## 🎯 WINDOWS SPECIFIC

### Win32 API (Modern)
```cpp
#include <windows.h>

// Create window class
WNDCLASSA wc = {};
wc.lpfnWndProc = WindowProc;
wc.hInstance = GetModuleHandleA(NULL);
wc.lpszClassName = "MyWindow";
RegisterClassA(&wc);

// Create window
CreateWindowA("MyWindow", "Title", 
    WS_OVERLAPPEDWINDOW, 100, 100, 800, 600,
    NULL, NULL, wc.hInstance, NULL);
```

### Direct3D 12 Setup
```dx
1. Create D3D12Device
2. Create Command Queue
3. Create Swap Chain
4. Create Render Targets
5. Create Root Signature
6. Create Pipeline State
7. Execute Draw Commands
```

## 📦 MUST-HAVE LIBS

```
choco install qt
choco install ninja
vcpkg install qt6
vcpkg install sdl2
vcpkg install boost
```

## 🎨 VISUALS BEST PRACTICES

### Modern UI Tips
1. Dark theme by default (#1a1a2e background)
2. Accent colors: cyan (#00ffc8), purple (#7b2cbf)
3. Rounded corners (8-16px radius)
4. Subtle shadows
5. Smooth animations (60 FPS)
6. Glassmorphism where supported
7. Custom fonts (Inter, Roboto)

### Graphics Pipeline
```
CPU → Update → Submit Commands → GPU → Present → SwapChain → Display
```

## 🔗 RESOURCES

- Qt Docs: https://doc.qt.io/qt-6/
- Dear ImGui: https://github.com/ocornut/imgui
- DirectX SDK: https://learn.microsoft.com/windows/directx/
- vcpkg: https://github.com/microsoft/vcpkg