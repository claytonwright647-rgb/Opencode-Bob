---
name: graphics-visual
description: Best graphics, visuals, effects, and animations
license: MIT
---

# MASTER GRAPHICS & VISUALS

## 🎨 BEST GRAPHICS LIBRARIES BY LANGUAGE

### C++ Graphics
| Library | Use Case | Features |
|---------|---------|----------|
| **Qt RHI** | Cross-GPU | Vulkan, Direct3D, Metal, OpenGL |
| **DirectX 12** | Windows games | Ultimate performance |
| **Vulkan** | Low-level GPU | Modern API |
| **OpenGL** | Cross-platform | Legacy compatible |
| **Skia** | 2D rendering | Fast, Google-backed |
| **Dear ImGui** | Tools, dashboards | Immediate mode |

### C# Graphics
| Library | Use Case | Features |
|---------|---------|----------|
| **WPF DirectX** | Windows apps | Hardware accelerated |
| **SkiaSharp** | 2D anywhere | Cross-platform |
| **MonoGame** | Games | XNA successor |
| **Velaptor** | Modern 2D | GPU-based |
| **Veldrid** | Low-level | All GPUs |

### Python Graphics
| Library | Use Case | Features |
|---------|---------|----------|
| **PyGame** | 2D games | Most popular |
| **Pyglet** | 2D/3D | GPU-accelerated |
| **Arcade** | Modern 2D | Easy API |
| **Ursina** | 3D games | Pythonic |
| **SkiaSharp** | 2D | .NET from Python |

## 🚀 MODERN VISUAL EFFECTS

### 1. Glow Effect (PyGame)
```python
def draw_glow(surface, x, y, color, radius):
    """Draw element with glow"""
    for i in range(5):
        alpha = max(10, 60 - i * 12)
        r = radius + i * 6
        glow = pygame.Surface((r*2, r*2), pygame.SRCALPHA)
        pygame.draw.circle(glow, (*color, alpha), (r, r), r)
        surface.blit(glow, (x-r, y-r), special_flags=pygame.BLEND_ADD)
    
    pygame.draw.circle(surface, color, (x, y), radius)

# Usage
CYAN = (0, 255, 200)
draw_glow(screen, 400, 300, CYAN, 30)
```

### 2. Gradient Background (WPF)
```csharp
var gradient = new LinearGradientBrush(
    Color.FromRgb(26, 26, 46),
    Color.FromRgb(22, 33, 62),
    new Point(0, 0),
    new Point(1, 1));

Background = gradient;
```

### 3. Glassmorphism (Qt/QML)
```qml
Rectangle {
    anchors.fill: parent
    color: "transparent"
    
    Rectangle {
        anchors.fill: parent
        radius: 16
        color: "#2d2d44"
        opacity: 0.8
        border.radius: 16
        border.width: 1
        border.color: "#ffffff20"
    }
}
```

### 4. Particle System (PyGame)
```python
class Particle:
    def __init__(self, x, y):
        self.x, self.y = x, y
        self.vx = random.uniform(-2, 2)
        self.vy = random.uniform(-5, -1)
        self.life = 1.0
        self.color = (0, 255, 200)
    
    def update(self):
        self.x += self.vx
        self.y += self.vy
        self.vy += 0.1  # gravity
        self.life -= 0.02
    
    def draw(self, surface):
        if self.life > 0:
            size = int(8 * self.life)
            color = (*self.color, int(255 * self.life))
            pygame.draw.circle(surface, color[:3], (int(self.x), int(self.y)), size)
```

### 5. Animated Pulse (Qt)
```cpp
// In QPropertyAnimation
QPropertyAnimation *anim = new QPropertyAnimation(button, "geometry");
anim->setDuration(1000);
anim->setStartValue(QRect(100, 100, 100, 40));
anim->setEndValue(QRect(100, 100, 120, 48));
anim->setEasingCurve(QEasingCurve::InOutQuad);

// Loop
anim->setDirection(QAbstractAnimation::Backward);
anim->start();
```

### 6. Shimmer Loading Effect (CSS-like in Python)
```python
def draw_shimmer(surface, rect, progress):
    """Animated shimmer effect"""
    x = rect.x + (rect.width * progress)
    shimmer = pygame.Surface((40, rect.height), pygame.SRCALPHA)
    pygame.draw.line(shimmer, (255,255,255,100), (0,0), (0,40))
    pygame.draw.line(shimmer, (255,255,255,0), (20,0), (40,40))
    surface.blit(shimmer, (x - 20, rect.y))
```

## 🎨 BEST COLOR PALETTES

### Cyberpunk Neon
```python
NEON_PALETTE = {
    'bg': '#0d0d1a',
    'bg_elevated': '#1a1a2e',
    'cyan': '#00ffc8',
    'magenta': '#ff00ff',
    'yellow': '#ffe600',
    'purple': '#7b2cbf',
}
```

### Modern Dark
```python
MODERN_DARK = {
    'bg': '#1a1a2e',
    'bg_card': '#2d2d44',
    'bg_hover': '#3d3d54',
    'accent': '#00ffc8',
    'text': '#ffffff',
    'text_muted': '#a0a0b0',
}
```

### Gradient Presets
```python
GRADIENTS = {
    'sunset': ['#ff6b6b', '#feca57', '#48dbfb'],
    'ocean': ['#1a1a2e', '#3d5a80', '#98c1d9'],
    'aurora': ['#00ffc8', '#7b2cbf', '#3a0ca3'],
    'fire': ['#ff6b35', '#f7931e', '#ffc72c'],
}
```

## 🖼️ TEXTURE & SHADER EFFECTS

### Post-Processing (PyGame)
```python
def apply_bloom(surface, radius=10):
    """Simple bloom effect"""
    # Blur by scaling
    small = pygame.transform.scale(surface, (surface.get_width()//4, surface.get_height()//4))
    return pygame.transform.scale(small, surface.get_size())

def apply_scanlines(surface):
    """CRT scanline effect"""
    result = surface.copy()
    for y in range(0, surface.get_height(), 4):
        pygame.draw.line(result, (0,0,0,30), (0,y), (surface.get_width(), y))
    return result
```

### GLSL Shader (Qt)
```glsl
# Vertex
#version 430
layout(location = 0) in vec2 position;
layout(location = 1) in vec2 texCoord;
out vec2 vTexCoord;

# Fragment  
#version 430
in vec2 vTexCoord;
uniform sampler2D texture0;
uniform float time;
out vec4 fragColor;

void main() {
    vec2 uv = vTexCoord;
    uv.y += sin(time + uv.x * 10.0) * 0.01;
    fragColor = texture(texture0, uv);
}
```

## 🎬 ANIMATION BEST PRACTICES

| Animation | Duration | Easing |
|-----------|----------|--------|
| Button hover | 150ms | Ease-out |
| Card expand | 300ms | Ease-in-out |
| Modal show | 250ms | Back-out |
| Page transition | 400ms | Ease-in-out |
| Loading spinner | 1000ms | Linear loop |

## 📐 LAYOUTS

### Modern Card (Universal)
```python
card_style = {
    'background': '#2d2d44',
    'border_radius': 12,
    'padding': 16,
    'margin': 8,
    'shadow': {
        'blur': 20,
        'offset': (0, 4),
        'color': '#00000040'
    }
}
```

### Responsive Grid
```python
GRID = {
    'desktop': {'columns': 4, 'min_width': 300},
    'tablet': {'columns': 2, 'min_width': 200},
    'mobile': {'columns': 1, 'min_width': 150}
}
```

## 🛠️ TOOLS

- **Figma**: UI Design
- **Krita**: Graphics editing
- **Inkscape**: Vector graphics
- **OBS Studio**: Screen capture