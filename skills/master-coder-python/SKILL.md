---
name: master-coder-python
description: MASTER Python development - PyQt, Tkinter, Kivy, graphics, games
license: MIT
---

# MASTER CODER: Python for Windows

## 📚 BEST GUI FRAMEWORKS (2025-2026)

| Framework | Best For | Graphics | License |
|-----------|---------|----------|--------|
| **PySide6/PyQt6** | Professional desktop apps | Qt rendering | GPL/LGPL |
| **CustomTkinter** | Modern-looking Tkinter | tkinter based | MIT |
| **Dear PyGui** | GPU-accelerated tools | GPU (ImGui) | MIT |
| **Kivy** | Mobile/touch apps | OpenGL | MIT |
| **Tkinter** | Simple scripts | Built-in | PSF |
| **Streamlit** | Data dashboards | Web-based | Apache |

## 🎨 BEST GRAPHICS & GAME LIBRARIES

| Library | Use Case | Install |
|---------|---------|---------|
| **PyGame** | 2D games | pip install pygame |
| **Pyglet** | GPU-accelerated 2D/3D | pip install pyglet |
| **Arcade** | Modern 2D games | pip install arcade |
| **Ursina** | 3D game engine | pip install ursina |
| **ModernGL** | OpenGL modern | pip install moderngl |
| **PyOpenGL** | OpenGL bindings | pip install pyopengl |
| **Kivy** | Multi-touch, mobile | pip install kivy |
| **Pyrr** | 3D math | pip install pyrr |

## 🚀 QUICK START TEMPLATES

### PySide6 Modern Application
```python
import sys
from PySide6.QtWidgets import QApplication, QMainWindow, QPushButton, QLabel
from PySide6.QtCore import Qt
from PySide6.QtGui import QLinearGradient, QPalette, QColor

app = QApplication(sys.argv)

window = QMainWindow()
window.setWindowTitle("My App")
window.setGeometry(100, 100, 800, 600)

# Modern dark theme
window.setStyleSheet("""
    QMainWindow { background-color: #1a1a2e; }
    QPushButton { 
        background-color: #00ffc8; 
        color: #1a1a2e;
        border: none;
        padding: 12px 24px;
        border-radius: 8px;
        font-weight: bold;
    }
    QPushButton:hover { background-color: #00e6b8; }
""")

# Add widgets
window.setCentralWidget(button)
window.show()
sys.exit(app.exec())
```

### CustomTkinter Modern App
```python
import customtkinter as ctk

ctk.set_appearance_mode("dark")
ctk.set_default_color_theme("cyan")

app = ctk.CTk()
app.geometry("800x600")
app.title("My App")

# Modern rounded frame
frame = ctk.CTkFrame(app, corner_radius=12)
frame.pack(pady=20, padx=20, fill="both", expand=True)

label = ctk.CTkLabel(frame, text="Welcome!", font=("Roboto", 28))
label.pack(pady=40)

# Modern button
button = ctk.CTkButton(frame, text="Click Me", corner_radius=8)
button.pack(pady=20)

app.mainloop()
```

### Dear PyGui Dashboard
```python
import dearpygui.dearpygui as dpg

dpg.create_context()
dpg.create_viewport(title='Dashboard', width=800, height=600)

with dpg.window("Main"):
    dpg.add_text("Analytics Dashboard", font_size=24)
    dpg.add_separator()
    dpg.add_button(label="Refresh Data")
    dpg.add_same_line()
    dpg.add_button(label="Export")

with dpg.plot("Performance Chart", label="Performance"):
    dpg.add_plot_legend()
    xaxis = dpg.add_plot_axis(dpg.MPlotAxis.X, label="Time")
    yaxis = dpg.add_plot_axis(dpg.MPlotAxis.Y, label="Value")
    dpg.add_line_series(xaxis, yaxis, [1, 2, 3, 4, 5], label="Metric")

dpg.setup_dearpygui()
dpg.show_viewport()
dpg.destroy_context()
```

### PyGame with Modern Graphics
```python
import pygame
from pygame import gfxdraw
import math

pygame.init()
screen = pygame.display.set_mode((800, 600), pygame.HWSURFACE | pygame.DOUBLEBUF)
clock = pygame.time.Clock()

# Colors
DARK_BG = (26, 26, 46)
CYAN = (0, 255, 200)
PURPLE = (123, 44, 191)

def draw_circle_glow(surface, x, y, radius, color):
    """Draw circle with glow effect"""
    # Glow layers
    for i in range(5):
        alpha = 50 - i * 10
        r = radius + i * 8
        s = pygame.Surface((r*2, r*2), pygame.SRCALPHA)
        pygame.draw.circle(s, (*color, alpha), (r, r), r)
        surface.blit(s, (x-r, y-r), special_flags=pygame.BLEND_ADD)
    # Main circle
    pygame.draw.circle(surface, color, (x, y), radius)

# Main loop
running = True
while running:
    dt = clock.tick(60) / 1000
    
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
    
    # Clear with gradient effect
    screen.fill(DARK_BG)
    
    # Draw glowing elements
    draw_circle_glow(screen, 400, 300, 40, CYAN)
    
    pygame.display.flip()

pygame.quit()
```

### Kivy Mobile App
```python
from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.button import Button
from kivy.lang import Builder

#KV language (declarative UI)
Builder.load_string('''
<MyWidget>:
    BoxLayout:
        orientation: 'vertical'
        padding: 20
        Button:
            text: 'Tap Me!'
            font_size: 24
            background_color: (0, 1, 0.8, 1)
            size_hint_y: None
            height: '60dp'
''')

class MyWidget(BoxLayout):
    pass

class MyApp(App):
    def build(self):
        return MyWidget()

MyApp().run()
```

### Streamlit Data Dashboard
```python
import streamlit as st
import pandas as pd
import plotly.express as px

st.set_page_config(page_title="Dashboard", layout="wide")

st.title("📊 Analytics Dashboard")

# Data
df = pd.DataFrame({
    'Category': ['A', 'B', 'C', 'D'],
    'Values': [25, 40, 30, 55]
})

# Charts
col1, col2 = st.columns(2)

with col1:
    st.metric("Total Users", "1,234", "+12%")
    fig = px.bar(df, x='Category', y='Values', title="Sales")
    st.plotly_chart(fig, use_container_width=True)

with col2:
    st.metric("Revenue", "$45.2K", "+8%")
    fig2 = px.pie(df, values='Values', names='Category', title="Distribution")
    st.plotly_chart(fig2, use_container_width=True)

# Run with: streamlit run app.py
```

## 🎨 VISUALS BEST PRACTICES

### Modern Color Palette
```python
# Dark theme colors
COLORS = {
    'bg_dark': '#1a1a2e',
    'bg_card': '#2d2d44',
    'accent_cyan': '#00ffc8',
    'accent_purple': '#7b2cbf',
    'text_white': '#ffffff',
    'text_gray': '#a0a0b0',
    'success': '#00e676',
    'warning': '#ffab00',
    'error': '#ff5252',
}
```

### Graphics Effects
```python
def add_glow(surface, x, y, color, radius=20):
    """Add glow effect to element"""
    for i in range(3):
        alpha = 60 - i * 20
        r = radius + i * 10
        s = pygame.Surface((r*2, r*2), pygame.SRCALIAS)
        pygame.draw.circle(s, (*color, alpha), (r, r), r)
        surface.blit(s, (x-r, y-r), special_flags=pygame.BLEND_ADD)

def draw_gradient_rect(surface, rect, color1, color2):
    """Draw gradient fill"""
    pygame.draw.rect(surface, color1, rect)
```

## 📦 MUST-HAVE PIP PACKAGES

```bash
pip install PySide6
pip install customtkinter
pip install dearpygui
pip install pygame
pip install arcade
pip install kivy
pip install streamlit
pip install plotly
pip install pandas
pip install numpy
```

## 🔗 RESOURCES

- PySide Docs: https://doc.qt.io/qt-6/
- CustomTkinter: https://github.com/TomSchimansky/CustomTkinter
- Dear PyGui: https://github.com/ocornut/imgui
- PyGame: https://www.pygame.org/
- Streamlit: https://streamlit.io/
- Kivy: https://kivy.org/