"""
Modern Dark Theme PyGame Window with Glowing Cyan Circle
Author: Clay Wright
Date: 2026
"""

import pygame
import math
import sys

# Initialize PyGame
pygame.init()

# Constants
WINDOW_WIDTH = 800
WINDOW_HEIGHT = 600
FPS = 60

# Colors - Modern Dark Theme
COLOR_BG = (18, 18, 24)  # Deep dark blue-gray
COLOR_CYAN = (0, 255, 255)  # Pure cyan
COLOR_CYAN_DIM = (0, 200, 200)  # Dimmer cyan for glow

# Glow settings
GLOW_RADIUS = 100  # Main circle radius
GLOW_LAYERS = 20  # Number of glow layers
GLOW_INTENSITY = 15  # How far the glow extends


def create_glowing_circle(surface, center_x, center_y, radius, color, glow_layers=20):
    """
    Create a glowing circle effect using multiple concentric circles
    with decreasing alpha values.
    """
    # Create a surface with per-pixel alpha for smooth blending
    glow_surface = pygame.Surface((WINDOW_WIDTH, WINDOW_HEIGHT), pygame.SRCALPHA)
    
    # Draw glow layers from outside in (largest to smallest)
    for i in range(glow_layers, 0, -1):
        # Calculate alpha based on layer (outer layers are more transparent)
        alpha = int(255 * (i / glow_layers) * 0.5)
        
        # Calculate radius for this layer
        layer_radius = radius + (glow_layers - i) * 3
        
        # Create color with alpha
        glow_color = (*color, alpha)
        
        # Draw the circle
        pygame.draw.circle(glow_surface, glow_color, (center_x, center_y), layer_radius, 1)
    
    # Draw the main solid circle
    pygame.draw.circle(glow_surface, (*color, 255), (center_x, center_y), radius)
    
    # Draw inner highlight for extra glow effect
    highlight_radius = radius * 0.7
    highlight_color = (min(255, color[0] + 50), min(255, color[1] + 50), min(255, color[2] + 50), 180)
    pygame.draw.circle(glow_surface, highlight_color, (center_x, center_y), int(highlight_radius))
    
    # Blit the glow surface to the main surface
    surface.blit(glow_surface, (0, 0))


def draw_pulse_effect(surface, center_x, center_y, base_radius, time_offset, color):
    """
    Add a subtle pulsing effect to the glow.
    """
    pulse = math.sin(time_offset * 0.003) * 5
    current_radius = int(base_radius + pulse)
    
    # Draw pulse ring
    pulse_alpha = int(100 * (1 + math.sin(time_offset * 0.003)))
    pulse_color = (*color, pulse_alpha)
    pulse_radius = int(base_radius + 15 + pulse * 2)
    
    pulse_surface = pygame.Surface((WINDOW_WIDTH, WINDOW_HEIGHT), pygame.SRCALPHA)
    pygame.draw.circle(pulse_surface, pulse_color, (center_x, center_y), pulse_radius, 2)
    surface.blit(pulse_surface, (0, 0))
    
    return current_radius


def main():
    """Main game loop."""
    # Create window
    screen = pygame.display.set_mode((WINDOW_WIDTH, WINDOW_HEIGHT))
    pygame.display.set_caption("✨ Glowing Cyan Circle - Modern Dark Theme")
    
    # Create clock for FPS control
    clock = pygame.time.Clock()
    
    # Calculate center
    center_x = WINDOW_WIDTH // 2
    center_y = WINDOW_HEIGHT // 2
    
    # Create font for title
    font = pygame.font.Font(None, 36)
    small_font = pygame.font.Font(None, 24)
    
    # Running flag
    running = True
    start_time = pygame.time.get_ticks()
    
    print("[PyGame Window Started]")
    print("[Glowing cyan circle in center]")
    print("[Press ESC or close window to exit]")
    print("-" * 40)
    
    while running:
        # Get current time for animations
        current_time = pygame.time.get_ticks()
        elapsed = current_time - start_time
        
        # Event handling
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    running = False
        
        # Fill background with dark theme color
        screen.fill(COLOR_BG)
        
        # Draw grid pattern for modern look (subtle)
        grid_spacing = 50
        grid_color = (30, 30, 40)
        for x in range(0, WINDOW_WIDTH, grid_spacing):
            pygame.draw.line(screen, grid_color, (x, 0), (x, WINDOW_HEIGHT), 1)
        for y in range(0, WINDOW_HEIGHT, grid_spacing):
            pygame.draw.line(screen, grid_color, (0, y), (WINDOW_WIDTH, y), 1)
        
        # Draw pulsing effect ring
        draw_pulse_effect(screen, center_x, center_y, GLOW_RADIUS, elapsed, COLOR_CYAN)
        
        # Draw the main glowing circle
        current_radius = draw_pulse_effect(screen, center_x, center_y, GLOW_RADIUS, elapsed, COLOR_CYAN)
        create_glowing_circle(screen, center_x, center_y, current_radius, COLOR_CYAN, GLOW_LAYERS)
        
        # Draw title text
        title_text = font.render("Glowing Cyan Circle", True, COLOR_CYAN)
        title_rect = title_text.get_rect(center=(center_x, 50))
        screen.blit(title_text, title_rect)
        
        # Draw instructions
        instr_text = small_font.render("Press ESC to exit", True, (150, 150, 160))
        instr_rect = instr_text.get_rect(center=(center_x, WINDOW_HEIGHT - 30))
        screen.blit(instr_text, instr_rect)
        
        # Draw FPS counter
        fps_text = small_font.render(f"FPS: {int(clock.get_fps())}", True, (100, 100, 120))
        screen.blit(fps_text, (10, 10))
        
        # Update display
        pygame.display.flip()
        
        # Cap framerate
        clock.tick(FPS)
    
    # Cleanup
    pygame.quit()
    sys.exit()


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"[ERROR] {e}")
        pygame.quit()
        sys.exit(1)
