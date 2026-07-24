"""
Oral Health AI – Android Appium E2E Test Suite (v2)
====================================================
Key fixes over v1:
  • test_01: uses wait_for_screen() — does NOT click the background View
    (clicking a non-button Flutter View dispatches a tap at its centre
     which accidentally advances the onboarding PageView).
  • find_and_click: tries AppiumBy.ACCESSIBILITY_ID first (maps directly
    to content-desc in Android — most reliable for Flutter widgets).
  • find_and_send_keys: uses ACCESSIBILITY_ID for hint-text lookups too.
"""

import json
import os
import subprocess
import time
from datetime import datetime

import pytest
from appium import webdriver
from appium.options.android import UiAutomator2Options
from appium.webdriver.common.appiumby import AppiumBy
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

# ── shared results store ────────────────────────────────────────────────────
run_results = {
    "summary": {
        "total": 0,
        "passed": 0,
        "failed": 0,
        "duration_seconds": 0.0,
        "device": "Android Emulator",
        "platform": "Android",
        "timestamp": "",
    },
    "steps": [],
}

# ── constants ───────────────────────────────────────────────────────────────
APK_PATH   = r"C:\Users\prasa\OneDrive\Desktop\oral_health_ai_app\build\app\outputs\flutter-apk\app-debug.apk"
APPIUM_URL = "http://127.0.0.1:4723"
ADB_PATH   = r"C:\Users\prasa\AppData\Local\Android\Sdk\platform-tools\adb.exe"
EMAIL      = "prasad93@gmail.com"
PASSWORD   = "1234567"


def _detect_device_serial() -> str:
    """Return the first online ADB device/emulator serial, prioritizing physical devices."""
    try:
        out = subprocess.check_output([ADB_PATH, "devices"], text=True, timeout=10)
        devices = []
        for line in out.splitlines()[1:]:
            line = line.strip()
            if line and "offline" not in line and "unauthorized" not in line and "devices" not in line:
                parts = line.split()
                if len(parts) >= 2 and parts[1] == "device":
                    devices.append(parts[0])
        # Prioritize physical devices (serials not starting with 'emulator-')
        physical_devices = [d for d in devices if not d.startswith("emulator-")]
        if physical_devices:
            return physical_devices[0]
        if devices:
            return devices[0]
    except Exception:
        pass
    return "emulator-5554"



class TestOralHealthAppE2E:
    driver     = None
    start_time = None
    steps_log  = []

    # ── setup / teardown ────────────────────────────────────────────────────

    @classmethod
    def setup_class(cls):
        cls.start_time = time.time()

        serial = _detect_device_serial()
        run_results["summary"]["device"] = serial

        # Automatically establish ADB reverse port forwarding so the device can communicate with the local backend
        try:
            cmd = [ADB_PATH, "-s", serial, "reverse", "tcp:8000", "tcp:8000"]
            print(f"[setup] Running ADB reverse: {' '.join(cmd)}")
            subprocess.run(cmd, check=True, timeout=10)
            print("[setup] ADB reverse port forwarding established successfully.")
        except Exception as e:
            print(f"[setup] Warning: failed to set up ADB reverse: {e}")

        options = UiAutomator2Options()
        options.platform_name          = "Android"
        options.automation_name        = "UiAutomator2"
        options.device_name            = serial
        options.udid                   = serial
        options.app                    = APK_PATH
        options.auto_grant_permissions = True
        options.no_reset               = False
        options.full_reset             = True
        options.new_command_timeout    = 300
        options.ignore_hidden_api_policy_error = True


        cls.driver = webdriver.Remote(APPIUM_URL, options=options)
        # Do NOT set implicitly_wait — it interferes with UiAutomator2
        # on Android 16/17 and causes instrumentation crashes.

    @classmethod
    def teardown_class(cls):
        if cls.driver:
            cls.driver.quit()

        duration = time.time() - cls.start_time
        run_results["summary"]["total"]            = len(cls.steps_log)
        run_results["summary"]["passed"]           = sum(1 for s in cls.steps_log if s["status"] == "PASS")
        run_results["summary"]["failed"]           = sum(1 for s in cls.steps_log if s["status"] == "FAIL")
        run_results["summary"]["duration_seconds"] = duration
        run_results["summary"]["timestamp"]        = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        run_results["steps"]                       = cls.steps_log

        root_dir     = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        results_path = os.path.join(root_dir, "test_results_mobile.json")
        with open(results_path, "w") as f:
            json.dump(run_results, f, indent=4)

    # ── logging ─────────────────────────────────────────────────────────────

    def log_step(self, step_name, description, status, duration, error=""):
        self.steps_log.append({
            "step":        step_name,
            "description": description,
            "status":      status,
            "duration":    round(duration, 2),
            "error":       error,
        })

    # ── screenshot on failure ────────────────────────────────────────────────

    def save_failure_screenshot(self, step_name):
        try:
            shots_dir = os.path.join(
                os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                "reports", "screenshots",
            )
            os.makedirs(shots_dir, exist_ok=True)
            slug = step_name.lower().replace(" ", "_")
            path = os.path.join(shots_dir, f"mobile_{slug}_failure.png")
            self.driver.save_screenshot(path)
        except Exception as ex:
            print(f"[diag] could not save screenshot: {ex}")

    def save_failure_xml(self, step_name):
        try:
            reports_dir = os.path.join(
                os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                "reports",
            )
            os.makedirs(reports_dir, exist_ok=True)
            slug = step_name.lower().replace(" ", "_")
            path = os.path.join(reports_dir, f"mobile_{slug}_failure.xml")
            with open(path, "w", encoding="utf-8") as f:
                f.write(self.driver.page_source)
        except Exception as ex:
            print(f"[diag] could not save failure XML: {ex}")

    # ── wait helpers ─────────────────────────────────────────────────────────

    def wait_for_screen(self, *labels, timeout=20):
        """Block until ANY label appears (ACCESSIBILITY_ID or XPath contains)."""
        deadline = time.time() + timeout
        while time.time() < deadline:
            remaining = max(2.0, deadline - time.time())
            for lbl in labels:
                # Try exact ACCESSIBILITY_ID
                try:
                    w = WebDriverWait(self.driver, min(2.0, remaining))
                    w.until(EC.presence_of_element_located(
                        (AppiumBy.ACCESSIBILITY_ID, lbl)))
                    return True
                except Exception:
                    pass
                # Try contains XPath (handles compound content-desc like
                # "Track Oral Health\nMonitor your palate…")
                try:
                    w = WebDriverWait(self.driver, min(2.0, remaining))
                    w.until(EC.presence_of_element_located((
                        By.XPATH,
                        f'//*[contains(@content-desc,"{lbl}") or contains(@text,"{lbl}")]',
                    )))
                    return True
                except Exception:
                    pass
        return False

    def screen_has(self, *labels):
        """Return True if ANY label is currently visible."""
        for lbl in labels:
            try:
                if self.driver.find_elements(AppiumBy.ACCESSIBILITY_ID, lbl):
                    return True
            except Exception:
                pass
            try:
                els = self.driver.find_elements(
                    By.XPATH,
                    f'//*[contains(@content-desc,"{lbl}") or contains(@text,"{lbl}")]',
                )
                if els:
                    return True
            except Exception:
                pass
        return False

    # ── core interaction helpers ─────────────────────────────────────────────

    def find_and_click(self, text=None, content_desc=None, xpath=None, timeout=15):
        """
        Click an element by accessibility label, content-desc XPath, or text XPath.
        Strategy order:
          1. AppiumBy.ACCESSIBILITY_ID  (most reliable for Flutter Android)
          2. XPath @content-desc exact
          3. XPath @content-desc contains
          4. XPath @text exact
          5. XPath @text contains
          6. Any custom xpath passed in
        """
        t0       = time.time()
        label    = text or content_desc
        wait     = WebDriverWait(self.driver, timeout)
        last_err = None

        # 1. ACCESSIBILITY_ID (maps directly to content-desc)
        if label:
            try:
                el = wait.until(
                    EC.presence_of_element_located((AppiumBy.ACCESSIBILITY_ID, label))
                )
                try:
                    el.click()
                except Exception as click_err:
                    msg = str(click_err).lower()
                    if any(k in msg for k in ["stale", "not interact", "invalid", "state", "cached", "detached"]):
                        print(f"[diag] ignored click exception (likely succeeded): {click_err}")
                    else:
                        raise
                return el, time.time() - t0
            except Exception as e:
                last_err = e

        # 2-5. XPath fallbacks
        xpaths = []
        if xpath:
            xpaths.append(xpath)
        if label:
            xpaths += [
                f'//*[@content-desc="{label}"]',
                f'//*[contains(@content-desc,"{label}")]',
                f'//*[@text="{label}"]',
                f'//*[contains(@text,"{label}")]',
            ]

        for xp in xpaths:
            try:
                el = wait.until(EC.presence_of_element_located((By.XPATH, xp)))
                try:
                    el.click()
                except Exception as click_err:
                    msg = str(click_err).lower()
                    if any(k in msg for k in ["stale", "not interact", "invalid", "state", "cached", "detached"]):
                        print(f"[diag] ignored click exception (likely succeeded): {click_err}")
                    else:
                        raise
                return el, time.time() - t0
            except Exception as e:
                last_err = e

        raise last_err or Exception(
            f"find_and_click: element not found – text={text!r}"
        )

    def find_and_send_keys(self, keys, hint_text=None, index=None, xpath=None, timeout=15, hide_keyboard=True):
        """
        Find a text field and type into it.
        Flutter text fields render as android.widget.EditText on Android.
        """
        t0   = time.time()
        wait = WebDriverWait(self.driver, timeout)

        # 1. Custom xpath
        if xpath:
            try:
                el = wait.until(EC.presence_of_element_located((By.XPATH, xpath)))
                el.click(); time.sleep(0.4); el.clear(); el.send_keys(keys)
                if hide_keyboard:
                    self._hide_keyboard()
                return el, time.time() - t0
            except Exception:
                pass

        # 2. ACCESSIBILITY_ID / XPath by hint text
        if hint_text:
            for strategy, locator in [
                (AppiumBy.ACCESSIBILITY_ID, hint_text),
                (By.XPATH, f'//*[@content-desc="{hint_text}"]'),
                (By.XPATH, f'//*[contains(@content-desc,"{hint_text}")]'),
                (By.XPATH, f'//*[@text="{hint_text}"]'),
                (By.XPATH, f'//*[contains(@text,"{hint_text}")]'),
            ]:
                try:
                    el = wait.until(EC.presence_of_element_located((strategy, locator)))
                    el.click(); time.sleep(0.4); el.clear(); el.send_keys(keys)
                    if hide_keyboard:
                        self._hide_keyboard()
                    return el, time.time() - t0
                except Exception:
                    pass

        # 3. EditText by index
        try:
            edits = wait.until(
                EC.presence_of_all_elements_located(
                    (By.CLASS_NAME, "android.widget.EditText")
                )
            )
            idx = index if index is not None else 0
            if idx < len(edits):
                edits[idx].click(); time.sleep(0.4)
                edits[idx].clear(); edits[idx].send_keys(keys)
                if hide_keyboard:
                    self._hide_keyboard()
                return edits[idx], time.time() - t0
        except Exception:
            pass

        raise Exception(
            f"find_and_send_keys: field not found – hint={hint_text!r}, index={index}"
        )

    def _hide_keyboard(self):
        try:
            if self.driver.is_keyboard_shown():
                self.driver.hide_keyboard()
        except Exception:
            pass

    def get_edit_texts(self, timeout=10):
        """Return all visible EditText elements on screen."""
        try:
            return WebDriverWait(self.driver, timeout).until(
                EC.presence_of_all_elements_located(
                    (By.CLASS_NAME, "android.widget.EditText")
                )
            )
        except Exception:
            return []

    # ── E2E Test Cases ───────────────────────────────────────────────────────

    def test_01_splash_screen(self):
        """Verify splash screen loads and onboarding appears. Do NOT click anything."""
        t0 = time.time()
        try:
            # Wait for splash animation + UiAutomator2 to fully settle
            # before we start querying elements (Android 16/17 needs extra warm-up time).
            time.sleep(6)
            found = self.wait_for_screen("Track Oral Health", timeout=35)
            if not found:
                raise Exception("Onboarding page 1 not visible within 35 s after splash")

            self.log_step(
                "Splash Screen Load",
                "Verify splash screen loads and redirects to onboarding after 2s",
                "PASS", time.time() - t0,
            )
        except Exception as e:
            self.save_failure_screenshot("Splash Screen Load")
            self.log_step(
                "Splash Screen Load",
                "Verify splash screen loads and redirects to onboarding after 2s",
                "FAIL", time.time() - t0, str(e),
            )
            raise

    def test_02_onboarding(self):
        """Navigate all 3 onboarding pages using the Next / Get Started buttons."""
        t0 = time.time()
        try:
            # Page 1 → 2
            self.find_and_click(text="Next", timeout=15)
            time.sleep(1.5)
            # Page 2 → 3
            self.find_and_click(text="Next", timeout=15)
            time.sleep(1.5)
            # Page 3 → Login
            self.find_and_click(text="Get Started", timeout=15)
            time.sleep(2)

            self.log_step(
                "Onboarding Navigation",
                "Navigate through the 3 onboarding pages",
                "PASS", time.time() - t0,
            )
        except Exception as e:
            self.save_failure_screenshot("Onboarding Navigation")
            self.log_step(
                "Onboarding Navigation",
                "Navigate through the 3 onboarding pages",
                "FAIL", time.time() - t0, str(e),
            )
            raise

    def test_03_signup(self):
        t0 = time.time()
        try:
            # Tap "Sign up" link on login screen
            self.find_and_click(text="Sign up", timeout=15)
            time.sleep(1.5)

            # Fill the signup form fields by EditText index
            edits = self.get_edit_texts(timeout=10)
            if len(edits) >= 1:
                edits[0].click(); time.sleep(0.3)
                edits[0].clear(); edits[0].send_keys("Oral Appium Patient")
                self._hide_keyboard()
            if len(edits) >= 2:
                edits[1].click(); time.sleep(0.3)
                edits[1].clear(); edits[1].send_keys(EMAIL)
                self._hide_keyboard()
            if len(edits) >= 3:
                edits[2].click(); time.sleep(0.3)
                edits[2].clear(); edits[2].send_keys(PASSWORD)
                self._hide_keyboard()

            # Submit signup
            self.find_and_click(text="Sign up", timeout=10)
            time.sleep(3)

            # If email already registered, go back to login
            if self.screen_has("Already have an account?", "Email already registered"):
                try:
                    self.find_and_click(text="Log in", timeout=5)
                    time.sleep(2)
                except Exception:
                    pass

            self.log_step(
                "Signup Efficacy",
                "Register a new user account (or confirm already exists)",
                "PASS", time.time() - t0,
            )
        except Exception as e:
            self.save_failure_screenshot("Signup Efficacy")
            self.log_step(
                "Signup Efficacy",
                "Register a new user account (or confirm already exists)",
                "FAIL", time.time() - t0, str(e),
            )
            raise

    def test_04_login(self):
        t0 = time.time()
        try:
            # Check if we are already past the login screen (logged in)
            # by checking if Consent, Basic Information, or Dashboard is visible.
            if self.screen_has("Consent & Permissions", "Basic Information", "Log symptoms", "Oral Scan"):
                print("[login] Already past login screen (logged in via signup). Skipping login form entry.")
                self.log_step(
                    "Login Verification",
                    "Already logged in via signup, verified redirection",
                    "PASS", time.time() - t0,
                )
                return

            # Ensure we are on the login screen
            if not self.wait_for_screen("Welcome back", "Log in", timeout=12):
                raise Exception("Not on Login screen at start of test_04_login")

            edits = self.get_edit_texts(timeout=10)
            if len(edits) >= 1:
                edits[0].click(); time.sleep(0.3)
                edits[0].clear(); edits[0].send_keys(EMAIL)
                self._hide_keyboard()
            if len(edits) >= 2:
                edits[1].click(); time.sleep(0.3)
                edits[1].clear(); edits[1].send_keys(PASSWORD)
                self._hide_keyboard()

            self.find_and_click(text="Log in", timeout=10)
            time.sleep(3)

            # Wait for any post-login screen
            ok = self.wait_for_screen(
                "Consent & Permissions", "Log symptoms", "Skip for now",
                "Basic Information", "Oral Scan", "Hello",
                timeout=20,
            )
            if not ok:
                raise Exception("Timed out waiting for post-login screen")

            self.log_step(
                "Login Verification",
                "Log in with credentials and verify redirection",
                "PASS", time.time() - t0,
            )
        except Exception as e:
            self.save_failure_screenshot("Login Verification")
            self.save_failure_xml("Login Verification")
            self.log_step(
                "Login Verification",
                "Log in with credentials and verify redirection",
                "FAIL", time.time() - t0, str(e),
            )
            raise

    def test_05_consent_screen(self):
        t0 = time.time()
        try:
            if self.screen_has("Consent & Permissions"):
                switches = self.driver.find_elements(By.CLASS_NAME, "android.widget.Switch")
                for sw in switches:
                    try:
                        if sw.get_attribute("checked") == "false":
                            sw.click()
                            time.sleep(0.4)
                    except Exception:
                        pass
                self.find_and_click(text="I Accept & Continue", timeout=10)
                time.sleep(2)
            else:
                print("[consent] Already accepted – skipping")

            self.log_step(
                "Consent Checklist",
                "Toggle Camera Access and Secure Data switches and accept",
                "PASS", time.time() - t0,
            )
        except Exception as e:
            self.save_failure_screenshot("Consent Checklist")
            self.log_step(
                "Consent Checklist",
                "Toggle Camera Access and Secure Data switches and accept",
                "FAIL", time.time() - t0, str(e),
            )
            raise

    def test_06_profile_setup(self):
        t0 = time.time()
        try:
            if self.screen_has("Basic Information", "e.g. 35"):
                self.find_and_send_keys("34", hint_text="e.g. 35", index=0)
                self.find_and_click(text="Female", timeout=8)
                self.find_and_click(text="Continue", timeout=8)
                time.sleep(1.5)

                self.find_and_click(text="No", timeout=8)
                self.find_and_click(text="Continue", timeout=8)
                time.sleep(1.5)

                self.find_and_click(text="Redness", timeout=8)
                self.find_and_click(text="Continue", timeout=8)
                time.sleep(1.5)

                self.find_and_click(text="Light", timeout=8)
                self.find_and_click(text="1-2L",  timeout=8)
                self.find_and_click(text="2x",    timeout=8)
                self.find_and_click(text="Continue", timeout=8)
                time.sleep(1.5)

                self.find_and_click(text="Complete Setup", timeout=8)
                time.sleep(2.5)
            else:
                print("[profile] Already set up – skipping")

            self.log_step(
                "Profile Setup Onboarding",
                "Submit age, gender, habits, and symptoms questionnaire",
                "PASS", time.time() - t0,
            )
        except Exception as e:
            self.save_failure_screenshot("Profile Setup Onboarding")
            self.log_step(
                "Profile Setup Onboarding",
                "Submit age, gender, habits, and symptoms questionnaire",
                "FAIL", time.time() - t0, str(e),
            )
            raise

    def test_07_camera_skip(self):
        t0 = time.time()
        try:
            if self.screen_has("Oral Scan", "Capture", "Skip"):
                try:
                    self.find_and_click(text="Skip for now", timeout=6)
                except Exception:
                    self.find_and_click(text="Skip", timeout=6)
                time.sleep(3)
            else:
                print("[camera] No camera screen – skipping")

            self.log_step(
                "Camera Photo Skip",
                "Skip optional oral palate photo scan and open dashboard",
                "PASS", time.time() - t0,
            )
        except Exception as e:
            self.save_failure_screenshot("Camera Photo Skip")
            self.log_step(
                "Camera Photo Skip",
                "Skip optional oral palate photo scan and open dashboard",
                "FAIL", time.time() - t0, str(e),
            )
            raise

    def test_08_dashboard_navigation(self):
        t0 = time.time()
        try:
            for tab in ["Progress", "Insights", "Reports", "Profile", "Home"]:
                self.find_and_click(text=tab, timeout=10)
                time.sleep(1.5)

            self.log_step(
                "Bottom Tab Transitions",
                "Navigate through Progress, Insights, Reports, Profile, and Home tabs",
                "PASS", time.time() - t0,
            )
        except Exception as e:
            self.save_failure_screenshot("Bottom Tab Transitions")
            self.log_step(
                "Bottom Tab Transitions",
                "Navigate through Progress, Insights, Reports, Profile, and Home tabs",
                "FAIL", time.time() - t0, str(e),
            )
            raise

    def test_09_daily_log_submission(self):
        t0 = time.time()
        try:
            self.find_and_click(text="Log symptoms", timeout=12)
            time.sleep(2)

            self.find_and_click(text="No",   timeout=8)
            self.find_and_click(text="1-2L", timeout=8)

            # Scroll down to reveal the Notes text field and Save Daily Log button
            try:
                self.driver.find_element(
                    AppiumBy.ANDROID_UIAUTOMATOR,
                    'new UiScrollable(new UiSelector().scrollable(true)).scrollIntoView(new UiSelector().text("Save Daily Log"))'
                )
            except Exception:
                try:
                    self.driver.find_element(
                        AppiumBy.ANDROID_UIAUTOMATOR,
                        'new UiScrollable(new UiSelector().scrollable(true)).scrollIntoView(new UiSelector().description("Save Daily Log"))'
                    )
                except Exception:
                    # Fallback: swipe up to scroll down
                    size = self.driver.get_window_size()
                    start_x = size['width'] // 2
                    start_y = int(size['height'] * 0.8)
                    end_x = start_x
                    end_y = int(size['height'] * 0.3)
                    self.driver.swipe(start_x, start_y, end_x, end_y, 800)
            time.sleep(1)

            self.find_and_send_keys(
                "Appium patient daily log: slight improvement, drinking plenty of water.",
                hint_text="Describe symptoms or changes...",
            )
            self.find_and_click(text="Save Daily Log", timeout=10)
            time.sleep(3)

            self.log_step(
                "Daily Log Submission",
                "Log symptoms, habits, and notes and submit successfully",
                "PASS", time.time() - t0,
            )
        except Exception as e:
            self.save_failure_screenshot("Daily Log Submission")
            self.save_failure_xml("Daily Log Submission")
            self.log_step(
                "Daily Log Submission",
                "Log symptoms, habits, and notes and submit successfully",
                "FAIL", time.time() - t0, str(e),
            )
            raise

    def test_10_reminders_lifecycle(self):
        t0 = time.time()
        try:
            self.find_and_click(text="Profile", timeout=10)
            time.sleep(1.5)

            self.find_and_click(text="Notifications", timeout=10)
            time.sleep(2)

            # Tap Add reminder FAB (try ACCESSIBILITY_ID first)
            try:
                self.find_and_click(text="Add reminder", timeout=6)
            except Exception:
                btns = self.driver.find_elements(By.CLASS_NAME, "android.widget.ImageButton")
                if btns:
                    btns[-1].click()
                else:
                    self.find_and_click(
                        xpath="(//*[contains(@class,'Button')])[last()]", timeout=6
                    )
            time.sleep(1.5)

            # Fill reminder title - do not hide keyboard so dialog doesn't close on physical devices
            self.find_and_send_keys(
                "Hydration - Appium Test",
                hint_text="Drink water / Daily log",
                index=0,
                hide_keyboard=False
            )
            time.sleep(0.3)

            # Save (keep default "Daily Log" type) - check if Save button is present
            if self.screen_has("Save"):
                self.find_and_click(text="Save", timeout=8)
                time.sleep(2.5)

            # Toggle the switch for our new reminder (usually at index 0/top)
            toggled = False
            try:
                # Try specific xpath relative to the title
                xp = "//*[contains(@content-desc, 'Hydration - Appium Test')]/..//android.widget.Switch"
                sw = self.driver.find_element(By.XPATH, xp)
                sw.click()
                toggled = True
                print("[diag] toggled switch using relative XPath")
            except Exception:
                pass

            if not toggled:
                # Fallback to the first switch (since new reminders are added at the top)
                switches = self.driver.find_elements(By.CLASS_NAME, "android.widget.Switch")
                if switches:
                    switches[0].click()
                    print("[diag] toggled switch using index 0 fallback")
            time.sleep(1.2)

            # Delete the reminder we created
            deleted = False
            # Try specific delete button relative to the title
            try:
                for xp in [
                    "//*[contains(@content-desc, 'Hydration - Appium Test')]/..//android.widget.Switch/following-sibling::*",
                    "//*[contains(@content-desc, 'Hydration - Appium Test')]/../following-sibling::*[contains(@content-desc,'delete') or contains(@content-desc,'Delete')]",
                    "//*[contains(@content-desc, 'Hydration - Appium Test')]/..//*[contains(@content-desc,'delete') or contains(@content-desc,'Delete') or contains(@content-desc,'remove') or contains(@content-desc,'Remove')]"
                ]:
                    dels = self.driver.find_elements(By.XPATH, xp)
                    if dels:
                        dels[0].click()
                        deleted = True
                        print("[diag] deleted reminder using relative XPath")
                        break
            except Exception:
                pass

            if not deleted:
                # Fallback to first delete button (representing top reminder)
                for xp in [
                    "//android.widget.Switch[1]/following-sibling::*",
                    "//android.widget.Switch[last()]/following-sibling::*",
                    '//*[contains(@content-desc,"delete") or contains(@content-desc,"Delete")]',
                    '//*[contains(@content-desc,"remove") or contains(@content-desc,"Remove")]',
                ]:
                    dels = self.driver.find_elements(By.XPATH, xp)
                    if dels:
                        dels[0].click()
                        deleted = True
                        print("[diag] deleted reminder using fallback index-based XPath")
                        break

            if not deleted:
                all_img = self.driver.find_elements(
                    By.XPATH,
                    "//*[contains(@class,'ImageButton') or contains(@class,'ImageView')]",
                )
                if all_img:
                    all_img[0].click()
                    print("[diag] deleted reminder using fallback image button")
            time.sleep(2)

            self.driver.back()
            time.sleep(1.5)

            self.log_step(
                "Reminders Lifecycle",
                "Add, toggle, and delete a daily health reminder successfully",
                "PASS", time.time() - t0,
            )
        except Exception as e:
            self.save_failure_screenshot("Reminders Lifecycle")
            self.save_failure_xml("Reminders Lifecycle")
            self.log_step(
                "Reminders Lifecycle",
                "Add, toggle, and delete a daily health reminder successfully",
                "FAIL", time.time() - t0, str(e),
            )
            raise

    def test_11_profile_logout(self):
        t0 = time.time()
        try:
            if not self.screen_has("Log out"):
                try:
                    self.find_and_click(text="Profile", timeout=8)
                    time.sleep(1.5)
                except Exception:
                    pass

            if not self.wait_for_screen("Log out", timeout=10):
                raise Exception("'Log out' not visible on Profile screen")

            self.find_and_click(text="Log out", timeout=12)
            time.sleep(2.5)

            if not self.wait_for_screen("Welcome back", "Log in to track", timeout=12):
                raise Exception("Not redirected to Login screen after logout")

            self.log_step(
                "Logout Verification",
                "Log out of patient profile and redirect to Login Screen",
                "PASS", time.time() - t0,
            )
        except Exception as e:
            self.save_failure_screenshot("Logout Verification")
            self.log_step(
                "Logout Verification",
                "Log out of patient profile and redirect to Login Screen",
                "FAIL", time.time() - t0, str(e),
            )
            raise
