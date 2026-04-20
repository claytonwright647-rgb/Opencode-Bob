---
name: master-coder-csharp
description: MASTER C# Windows development - WPF, WinForms, MAUI, Avalonia, graphics
license: MIT
---

# MASTER CODER: C# for Windows

## 📚 BEST GUI FRAMEWORKS (2025-2026)

| Framework | Best For | Windows Support | Graphics |
|----------|---------|-------------|----------|
| **WPF** | Desktop apps, data visualization | Excellent (DirectX) | Hardware accelerated |
| **WinUI 3** | Modern Windows 11 apps | Excellent | Fluent Design |
| **.NET MAUI** | Cross-platform mobile/desktop | Good (WinUI3) | Native |
| **Avalonia** | Cross-platform (Linux/Mac) | Good | Skia |
| **WinForms** | Legacy quick tools | Good | GDI+ |
| **Uno Platform** | Web + Mobile + Desktop | Excellent | All |

## 🎨 BEST GRAPHICS & VISUALS

| Library | Use Case | NuGet |
|---------|---------|------|
| **SkiaSharp** | 2D graphics anywhere | SkiaSharp |
| **SharpDX** | DirectX wrapper | SharpDX |
| **Veldrid** | Low-level GPU | Veldrid |
| **MonoGame** | Game engine | MonoGame |
| **Velaptor** | Modern 2D | Velaptor |
| **Eto.Forms** | Cross-platform UI | Eto.Forms |

## 🚀 QUICK START TEMPLATES

### WPF Application
```csharp
using System.Windows;

public partial class MainWindow : Window {
    public MainWindow() {
        InitializeComponent();
        DataContext = new MainViewModel();
    }
}
```

### WPF with Custom Graphics (XAML)
```xml
<Window x:Class="MyApp.MainWindow"
    Title="My App" Width="800" Height="600"
    Background="#1a1a2e">
    
    <Grid>
        <!-- Modern card with shadow -->
        <Border Background="#2d2d44" 
               CornerRadius="12"
               Margin="20"
               Effect="{StaticResource CardShadow}">
            <StackPanel Margin="20">
                <TextBlock Text="Welcome"
                         FontSize="28"
                         Foreground="White"/>
            </StackPanel>
        </Border>
    </Grid>
</Window>
```

### WPF with SkiaSharp Rendering
```csharp
using SkiaSharp;
using System.Windows.Controls;
using System.Windows.Media;

public class SkiaCanvas : Image {
    private SKBitmap _bitmap;
    
    protected override void OnRender(DrawingContext dc) {
        base.OnRender(dc);
        
        using var surface = SKSurface.Create(new SKImageInfo(800, 600));
        var canvas = surface.Canvas;
        
        // Dark background
        canvas.Clear(SKColor.Parse("#1a1a2e"));
        
        // Gradient circle with glow
        using var paint = new SKPaint {
            IsAntialias = true,
            Color = SKColor.Parse("#00ffc8").WithAlpha(180),
            MaskFilter = SKMaskFilter.CreateBlur(SKBlurStyle.Normal, 20)
        };
        canvas.DrawCircle(400, 300, 80, paint);
    }
}
```

### .NET MAUI Application
```csharp
public class App : Application {
    protected override Window CreateWindow(IContainerProvider c) =>
        new MainWindow();
}

public class MainWindow : Window {
    public MainWindow() {
        Title = "My App";
        Background = new SolidColorBrush(Color.Parse("#1a1a2e"));
        
        Content = new VerticalStackLayout {
            new Label { Text = "Hello World" }
        };
    }
}
```

### Avalonia Cross-Platform
```csharp
public partial class App : Application {
    public override void Initialize() => 
        AvaloniaXamlLoader.Load(this);
}

public partial class MainView : UserControl {
    public MainView() {
        Content = new Border {
            Background = new SolidColorBrush(Color.Parse("#1a1a2e")),
            Child = new TextBlock {
                Text = "Cross-Platform!",
                FontSize = 28
            }
        };
    }
}
```

## 🎨 MODERN WPF STYLES

### App.xaml Resources
```xml
<Application.Resources>
    <Style x:Key="CardStyle" TargetType="Border">
        <Setter Property="Background" Value="#2d2d44"/>
        <Setter Property="CornerRadius" Value="12"/>
        <Setter Property="Padding" Value="16"/>
        <Setter Property="Effect">
            <Setter.Value>
                <DropShadowEffect BlurRadius="20" Color="Black" Opacity="0.3"/>
            </Setter.Value>
        </Setter>
    </Style>
    
    <Style x:Key="ModernButton" TargetType="Button">
        <Setter Property="Background" Value="#00ffc8"/>
        <Setter Property="Foreground" Value="#1a1a2e"/>
        <Setter Property="FontWeight" Value="SemiBold"/>
        <Setter Property="Padding" Value="20,12"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="Button">
                    <Border Background="{TemplateBinding Background}"
                            CornerRadius="8"
                            Padding="{TemplateBinding Padding}">
                        <ContentPresenter HorizontalAlignment="Center"/>
                    </Border>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>
</Application.Resources>
```

## 📦 MUST-HAVE NUGET PACKAGES

```powershell
# Install essential packages
dotnet add package SkiaSharp
dotnet add package SkiaSharp.Views.WPF
dotnet add package CommunityToolkit.Mvvm
dotnet add package Microsoft.Extensions.DependencyInjection
dotnet add package Serilog
```

## 🔗 RESOURCES

- WPF Docs: https://learn.microsoft.com/dotnet/wpf/
- MAUI Docs: https://docs.microsoft.com/dotnet/maui/
- Avalonia: https://avaloniaui.net/
- SkiaSharp: https://github.com/mono/SkiaSharp
- dotnet add: https://www.nuget.org/