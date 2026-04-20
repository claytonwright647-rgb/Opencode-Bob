"""Direct Windows API mouse movement"""
import ctypes
import time
import sys

user32 = ctypes.windll.user32

print("Testing Windows API mouse movement...")

# Get current position
class POINT(ctypes.Structure):
    _fields_ = [("x", ctypes.c_long), ("y", ctypes.c_long)]

pt = POINT()
user32.GetCursorPos(ctypes.byref(pt))
print(f"Current: ({pt.x}, {pt.y})")

# Move to corners quickly - using direct API
print("\nMoving to top-left...")
user32.SetCursorPos(200, 200)

time.sleep(0.3)

print("Moving to top-right...")
user32.SetCursorPos(1720, 200)

time.sleep(0.3)

print("Moving to bottom-right...")
user32.SetCursorPos(1720, 880)

time.sleep(0.3)

print("Moving to bottom-left...")
user32.SetCursorPos(200, 880)

time.sleep(0.3)

print("Moving to center...")
user32.SetCursorPos(960, 540)

# Final check
user32.GetCursorPos(ctypes.byref(pt))
print(f"\nFinal: ({pt.x}, {pt.y})")
print("Done!")