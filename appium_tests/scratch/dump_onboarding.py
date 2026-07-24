"""
Dump accessible elements on the Android Onboarding screen via Appium.
Saves the full page source XML for analysis.
"""
import time
import os
from appium import webdriver
from appium.options.android import UiAutomator2Options
from selenium.webdriver.common.by import By

APK_PATH = r"C:\Users\prasa\OneDrive\Desktop\oral_health_ai_app\build\app\outputs\flutter-apk\app-debug.apk"
APPIUM_URL = "http://127.0.0.1:4723"

options = UiAutomator2Options()
options.platform_name        = "Android"
options.automation_name      = "UiAutomator2"
options.device_name          = "emulator-5554"
options.udid                 = "emulator-5554"
options.app                  = APK_PATH
options.auto_grant_permissions = True
options.no_reset             = False
options.full_reset           = True
options.new_command_timeout  = 120

print("Starting Appium session...")
driver = webdriver.Remote(APPIUM_URL, options=options)
driver.implicitly_wait(2)

try:
    time.sleep(5)  # Splash screen

    print("\n=== PAGE SOURCE (Splash/Onboarding) ===")
    src = driver.page_source
    
    out_dir = os.path.dirname(os.path.abspath(__file__))
    out_path = os.path.join(out_dir, "..", "reports", "onboarding_page_source.xml")
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(src)
    print(f"Page source saved to: {out_path}")

    # Print all elements that are clickable or have content-desc
    print("\n=== CLICKABLE / LABELLED ELEMENTS ===")
    all_els = driver.find_elements(By.XPATH, "//*[@clickable='true' or string-length(@content-desc)>0 or string-length(@text)>0]")
    for el in all_els:
        try:
            cd   = el.get_attribute("content-desc") or ""
            txt  = el.get_attribute("text") or ""
            cls  = el.get_attribute("className") or ""
            clk  = el.get_attribute("clickable") or ""
            bnd  = el.get_attribute("bounds") or ""
            if cd or txt:
                print(f"  class={cls:<45} clickable={clk:<5} content-desc={cd!r:<30} text={txt!r:<30} bounds={bnd}")
        except Exception:
            pass

    time.sleep(2)
    print("\n=== Checking for 'Next' button variants ===")
    for label in ["Next", "next", "NEXT", "→", "Continue", "Get Started", "Skip", "Skip for now"]:
        els = driver.find_elements(By.XPATH, f'//*[@content-desc="{label}" or @text="{label}"]')
        if els:
            print(f"  FOUND: {label!r} -> {len(els)} element(s), class={els[0].get_attribute('className')}")
        else:
            print(f"  NOT FOUND: {label!r}")

finally:
    driver.quit()
    print("\nSession closed.")
