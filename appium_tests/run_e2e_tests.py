import subprocess
import time
import os
import sys

# Configure Android SDK Environment Variables dynamically
os.environ["ANDROID_HOME"] = r"C:\Users\prasa\AppData\Local\Android\Sdk"
os.environ["ANDROID_SDK_ROOT"] = r"C:\Users\prasa\AppData\Local\Android\Sdk"
sdk_tools = os.path.join(os.environ["ANDROID_HOME"], "platform-tools")
sdk_emulator = os.path.join(os.environ["ANDROID_HOME"], "emulator")
os.environ["PATH"] = sdk_tools + os.pathsep + sdk_emulator + os.pathsep + os.environ.get("PATH", "")

import requests
from generate_excel_report import create_excel_report

# Global Paths
ADB_PATH = r"C:\Users\prasa\AppData\Local\Android\Sdk\platform-tools\adb.exe"
EMULATOR_PATH = r"C:\Users\prasa\AppData\Local\Android\Sdk\emulator\emulator.exe"
ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APK_PATH = os.path.join(ROOT_DIR, "build", "app", "outputs", "flutter-apk", "app-debug.apk")

BACKEND_DIR = os.path.join(ROOT_DIR, "backend")
BACKEND_PYTHON = os.path.join(BACKEND_DIR, "venv", "Scripts", "python.exe")

PIP_PYTEST = os.path.join(ROOT_DIR, "appium_tests", "venv", "Scripts", "pytest.exe")
TEST_RESULTS_MOBILE = os.path.join(ROOT_DIR, "appium_tests", "test_results_mobile.json")
TEST_RESULTS_WEB = os.path.join(ROOT_DIR, "appium_tests", "test_results_web.json")
EXCEL_REPORT_PATH = os.path.join(ROOT_DIR, "appium_tests", "reports", "test_analysis_report.xlsx")

def get_running_devices():
    if not os.path.exists(ADB_PATH):
        print(f"Error: ADB not found at {ADB_PATH}")
        return []
    res = subprocess.run([ADB_PATH, "devices"], capture_output=True, text=True)
    lines = res.stdout.strip().split("\n")[1:]
    devices = []
    for line in lines:
        line = line.strip()
        if line and "device" in line and "offline" not in line and "unauthorized" not in line and "devices" not in line:
            parts = line.split()
            if len(parts) >= 2 and parts[1] == "device":
                devices.append(parts[0])
    # Prioritize physical devices (serials not starting with 'emulator-')
    physical_devices = [d for d in devices if not d.startswith("emulator-")]
    if physical_devices:
        return physical_devices
    return devices


def start_emulator():
    devices = get_running_devices()
    if devices:
        print(f"Active Android device detected: {devices[0]}")
        subprocess.run([ADB_PATH, "-s", devices[0], "reverse", "tcp:8000", "tcp:8000"])
        print("ADB reverse forwarding 8000 -> 8000 established.")
        return devices[0]
        
    if not os.path.exists(EMULATOR_PATH):
        print(f"Error: Emulator executable not found at {EMULATOR_PATH}")
        sys.exit(1)
        
    print("Launching Pixel_6 Emulator in background...")
    subprocess.Popen([EMULATOR_PATH, "-avd", "Pixel_6", "-netdelay", "none", "-netspeed", "full"])
    
    t0 = time.time()
    booted = False
    while time.time() - t0 < 60:
        time.sleep(3)
        res = subprocess.run([ADB_PATH, "shell", "getprop", "sys.boot_completed"], capture_output=True, text=True)
        if res.stdout.strip() == "1":
            print("Pixel_6 Emulator booted successfully.")
            booted = True
            break
            
    if not booted:
        print("Warning: Android Emulator boot check timed out. Proceeding...")
        
    time.sleep(5)  # Allow UI to stabilize
    devices = get_running_devices()
    if devices:
        subprocess.run([ADB_PATH, "-s", devices[0], "reverse", "tcp:8000", "tcp:8000"])
        print("ADB reverse forwarding 8000 -> 8000 established.")
    
    return devices[0] if devices else None


def start_appium_server():
    print("Checking Appium Server...")
    try:
        res = requests.get("http://127.0.0.1:4723/status", timeout=2)
        if res.status_code == 200:
            print("Appium Server is already running on port 4723.")
            return None
    except Exception:
        pass

    print("Starting Appium Server...")
    appium_log_path = os.path.join(ROOT_DIR, "appium_tests", "appium_server.log")
    appium_log = open(appium_log_path, "w", encoding="utf-8")
    appium_proc = subprocess.Popen(["npx", "appium"], shell=True, stdout=appium_log, stderr=appium_log)
    
    t0 = time.time()
    while time.time() - t0 < 25:
        try:
            res = requests.get("http://127.0.0.1:4723/status", timeout=2)
            if res.status_code == 200:
                print("Appium Server responds on port 4723.")
                return appium_proc
        except Exception:
            pass
        time.sleep(1.5)
        
    print("Warning: Appium server check timed out. Proceeding...")
    return appium_proc

def check_apk():
    if not os.path.exists(APK_PATH):
        print(f"APK file not found at: {APK_PATH}")
        print("Compiling Flutter APK (debug mode)...")
        res = subprocess.run(["flutter", "build", "apk", "--debug"], cwd=ROOT_DIR, shell=True)
        if res.returncode != 0:
            print("Error: Flutter compilation failed.")
            sys.exit(1)
    print("Android APK verified.")

def start_backend():
    print("Checking FastAPI Backend...")
    try:
        res = requests.get("http://127.0.0.1:8000/", timeout=2)
        if res.status_code == 200:
            print("FastAPI Backend is already running on port 8000.")
            return None
    except Exception:
        pass

    print("Starting FastAPI Backend...")
    backend_proc = subprocess.Popen([BACKEND_PYTHON, "-m", "uvicorn", "app.main:app", "--port", "8000"], cwd=BACKEND_DIR)
    
    t0 = time.time()
    while time.time() - t0 < 20:
        try:
            res = requests.get("http://127.0.0.1:8000/", timeout=2)
            if res.status_code == 200:
                print("FastAPI Backend responded successfully.")
                return backend_proc
        except Exception:
            pass
        time.sleep(1)
        
    print("Warning: FastAPI Backend startup check timed out. Proceeding...")
    return backend_proc

def start_web_server():
    print("Checking Flutter Web Server...")
    try:
        res = requests.get("http://localhost:8080", timeout=2)
        if res.status_code == 200:
            print("Web Server is already running on port 8080.")
            return None
    except Exception:
        pass

    print("Building Flutter Web App...")
    subprocess.run(["flutter", "build", "web"], cwd=ROOT_DIR, shell=True)
    
    print("Starting Python static Web Server on port 8080...")
    web_proc = subprocess.Popen([sys.executable, "-m", "http.server", "8080", "--directory", "build/web"], cwd=ROOT_DIR)
    
    t0 = time.time()
    while time.time() - t0 < 45:
        try:
            res = requests.get("http://localhost:8080", timeout=2)
            if res.status_code == 200:
                print("Flutter Web Server responded successfully.")
                return web_proc
        except Exception:
            pass
        time.sleep(2)
        
    print("Warning: Flutter Web Server startup check timed out. Proceeding...")
    return web_proc

def run_mobile_tests():
    print("\n----------------------------------------------------")
    print("RUNNING MOBILE TESTS (ANDROID EMULATOR)")
    print("----------------------------------------------------")
    test_script = os.path.join(ROOT_DIR, "appium_tests", "mobile", "test_oral_health_app.py")
    res = subprocess.run([PIP_PYTEST, test_script, "-v", "--tb=short"], cwd=ROOT_DIR)
    return res.returncode

def run_web_tests():
    print("\n----------------------------------------------------")
    print("RUNNING WEB TESTS (CHROME BROWSER)")
    print("----------------------------------------------------")
    test_script = os.path.join(ROOT_DIR, "appium_tests", "web", "test_oral_health_web.py")
    res = subprocess.run([PIP_PYTEST, test_script, "-v", "--tb=short"], cwd=ROOT_DIR)
    return res.returncode

def main():
    print("====================================================")
    print("ORAL HEALTH AI - WEB & MOBILE E2E APPIUM SUITE RUNNER")
    print("====================================================")
    
    # 1. Start backend server
    backend_proc = start_backend()
    
    # 2. Check and compile APK
    check_apk()
    
    # 3. Start Android emulator
    device = start_emulator()
    if not device:
        print("Error: No active Android emulator or device discovered.")
        if backend_proc:
            backend_proc.terminate()
        sys.exit(1)
        
    # 4. Start Appium server
    appium_proc = start_appium_server()
    
    # 5. Start Flutter Web server
    web_proc = start_web_server()
    
    mobile_exit_code = 0
    web_exit_code = 0
    
    try:
        # Run Mobile Appium Tests
        mobile_exit_code = run_mobile_tests()
    except Exception as e:
        print(f"Exception during Mobile E2E test run: {e}")
        mobile_exit_code = 1
        
    try:
        # Run Web WebDriver/Appium Tests
        web_exit_code = run_web_tests()
    except Exception as e:
        print(f"Exception during Web E2E test run: {e}")
        web_exit_code = 1
        
    finally:
        # Teardown processes
        print("\nShutting down all test servers...")
        if appium_proc:
            print("Stopping Appium Server...")
            appium_proc.terminate()
            appium_proc.wait()
            
        if web_proc:
            print("Stopping Flutter Web Server...")
            web_proc.terminate()
            web_proc.wait()
            
        if backend_proc:
            print("Stopping FastAPI Backend...")
            backend_proc.terminate()
            backend_proc.wait()
            
    # Generate Excel Report
    print("\nGenerating combined Excel analysis report...")
    try:
        try:
            create_excel_report(TEST_RESULTS_MOBILE, TEST_RESULTS_WEB, EXCEL_REPORT_PATH)
            saved_path = EXCEL_REPORT_PATH
        except PermissionError:
            fallback_path = EXCEL_REPORT_PATH.replace(".xlsx", "_v2.xlsx")
            print(f"Warning: {EXCEL_REPORT_PATH} is currently open/locked. Saving fallback report to {fallback_path}")
            create_excel_report(TEST_RESULTS_MOBILE, TEST_RESULTS_WEB, fallback_path)
            saved_path = fallback_path
            
        print("====================================================")
        print("TEST RUN COMPLETED.")
        print(f"Excel Report Saved: {saved_path}")
        print("====================================================")
    except Exception as e:
        print(f"Failed to generate Excel report: {e}")
        
    # Set final code: if any suite failed, exit code is non-zero
    overall_exit_code = mobile_exit_code or web_exit_code
    sys.exit(overall_exit_code)

if __name__ == "__main__":
    main()
