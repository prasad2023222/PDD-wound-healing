import time
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By

def main():
    chrome_options = Options()
    chrome_options.add_argument("--disable-gpu")
    chrome_options.add_argument("--window-size=1280,800")
    chrome_options.add_argument("--headless")
    
    driver = webdriver.Chrome(options=chrome_options)
    try:
        driver.get("http://localhost:8080/?enable-semantics=true")
        time.sleep(5)  # Let it load to splash/onboarding
        
        # We need to navigate past splash and onboarding to login screen
        # Click "Track Oral Health"
        # Click Next, Next, Get Started
        print("Navigating to login screen...")
        
        # Click Track Oral Health
        driver.execute_script("""
            function clickText(txt) {
                const els = document.querySelectorAll('*');
                for (const el of els) {
                    if (el.textContent && el.textContent.includes(txt)) {
                        el.click();
                        return true;
                    }
                }
                return false;
            }
            clickText("Track Oral Health");
        """)
        time.sleep(2)
        
        # Click Next, Next, Get Started
        for _ in range(2):
            driver.execute_script('// Find any element containing Next and click\nconst els = document.querySelectorAll("*"); for(const el of els){ if(el.textContent === "Next"){ el.click(); break; } }')
            time.sleep(1.5)
            
        driver.execute_script('const els = document.querySelectorAll("*"); for(const el of els){ if(el.textContent === "Get Started"){ el.click(); break; } }')
        time.sleep(2)
        
        print("At login screen. Dumping elements under flutter-view:")
        
        dump_js = """
        const view = document.querySelector('flutter-view') || document.body;
        
        function serialize(el, depth=0) {
            let res = "";
            const indent = "  ".repeat(depth);
            const tag = el.tagName.toLowerCase();
            const id = el.id ? ` id="${el.id}"` : "";
            const cls = el.className ? ` class="${el.className}"` : "";
            const label = el.getAttribute('aria-label') || '';
            const placeholder = el.getAttribute('placeholder') || '';
            const role = el.getAttribute('role') || '';
            const text = el.textContent || '';
            
            let attrs = "";
            if (label) attrs += ` aria-label="${label}"`;
            if (placeholder) attrs += ` placeholder="${placeholder}"`;
            if (role) attrs += ` role="${role}"`;
            
            // Only list relevant semantic tags or inputs
            if (tag.startsWith('flt-') || tag === 'input' || tag === 'textarea' || tag === 'button') {
                res += `${indent}<${tag}${id}${cls}${attrs}>`;
                let hasText = false;
                for (const child of el.childNodes) {
                    if (child.nodeType === Node.TEXT_NODE && child.nodeValue.trim()) {
                        res += ` TEXT: "${child.nodeValue.trim()}"`;
                        hasText = true;
                    }
                }
                res += "\\n";
            }
            
            for (const child of el.children) {
                res += serialize(child, depth + 1);
            }
            return res;
        }
        return serialize(view);
        """
        result = driver.execute_script(dump_js)
        print(result)
        
    finally:
        driver.quit()

if __name__ == "__main__":
    main()
