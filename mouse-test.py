# Mouse movement test
import pyautogui
import time
import sys

print("=" * 50)
print("MOUSE MOVEMENT TEST")
print("=" * 50)

# Get screen size
width, height = pyautogui.size()
print(f"Screen size: {width} x {height}")

# Get current position
current = pyautogui.position()
print(f"Starting position: ({current.x}, {current.y})")
print()

# Very visible movement - corners
corners = [
    (100, 100),
    (width - 100, 100),
    (width - 100, height - 100),
    (100, height - 100),
    (width // 2, height // 2),
]

print("Moving through screen corners...")
for i, (x, y) in enumerate(corners):
    pyautogui.moveTo(x, y, duration=0.2)
    print(f"  Corner {i+1}: ({x}, {y})")
    time.sleep(0.3)

# Final position
final = pyautogui.position()
print()
print(f"Final position: ({final.x}, {final.y})")
print("=" * 50)
print("TEST COMPLETE - You should have seen the mouse move!")
print("=" * 50)