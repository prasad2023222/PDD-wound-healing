import json
import os
import subprocess
import time
from appium import webdriver
from appium.options.android import UiAutomator2Options
from appium.webdriver.common.appiumby import AppiumBy
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

APK_PATH   = r"C:\Users\prasa\OneDrive\Desktop\oral_health_ai_app\build\app\outputs\flutter-apk\app-debug.apk"
APPIUM_URL = "http://127.0.0.1:4723"
ADB_PATH   = r"C:\Users\prasa\AppData\Local\Android\Sdk\platform-tools\adb.exe"

def _detect_device_serial() -> str:
    try:
        out = subprocess.check_output([ADB_PATH, "devices"], text=True, timeout=10)
        devices = []
        for line in out.splitlines()[1:]:
            line = line.strip()
            if line and "offline" not in line and "unauthorized" not in line and "devices" not in line:
                parts = line.split()
                if len(parts) >= 2 and parts[1] == "device":
                    devices.append(parts[0])
        physical_devices = [d for d in devices if not d.startswith("emulator-")]
        if physical_devices:
            return physical_devices[0]
        if devices:
            return devices[0]
    except Exception:
        pass
    return "emulator-5554"

serial = _detect_device_serial()
options = UiAutomator2Options()
options.platform_name          = "Android"
options.automation_name        = "UiAutomator2"
options.device_name            = serial
options.udid                   = serial
options.app                    = APK_PATH
options.auto_grant_permissions = True
options.no_reset               = True
options.ignore_hidden_api_policy_error = True

driver = webdriver.Remote(APPIUM_URL, options=options)
wait = WebDriverWait(driver, 15)

try:
    print("App launched. Checking screen state...")
    time.sleep(3)
    
    # Try to find "Profile" tab to click
    try:
        profile_tab = wait.until(EC.presence_of_element_located((AppiumBy.ACCESSIBILITY_ID, "Profile")))
        profile_tab.click()
        print("Clicked Profile tab.")
        time.sleep(2)
    except Exception as e:
        print("Could not find Profile tab directly. Checking if we need to login or if we are already there.")
        
    # Try to find "Notifications" button
    try:
        notif_btn = wait.until(EC.presence_of_element_located((AppiumBy.ACCESSIBILITY_ID, "Notifications")))
        notif_btn.click()
        print("Clicked Notifications.")
        time.sleep(2)
    except Exception as e:
        print("Could not click Notifications. Maybe we are already on Notifications/Reminders screen?")

    # Print page source
    source = driver.page_source
    output_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "reminders_layout.xml")
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(source)
    print(f"Page source saved to {output_path}")

finally:
    driver.quit()
