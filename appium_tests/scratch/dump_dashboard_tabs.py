"""
Dump the flt-semantics structure on the Dashboard screen to see
the real aria-label / role / text of the bottom nav tabs.
"""
import time
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.common.keys import Keys

def ac_click(driver, el):
    try:
        ActionChains(driver).move_to_element(el).click().perform()
    except Exception:
        driver.execute_script("arguments[0].click();", el)

def js_find(driver, text):
    JS = """
    const tl=arguments[0].toLowerCase().trim(); let hits=[];
    function scan(n){
        if(!n)return;
        const lbl=(n.getAttribute&&n.getAttribute('aria-label')||'').toLowerCase().trim();
        const ph=(n.getAttribute&&n.getAttribute('placeholder')||'').toLowerCase().trim();
        let ok=false;
        if(lbl===tl||ph===tl){ok=true;}
        else if(lbl.includes(tl)||ph.includes(tl)){ok=true;}
        if(!ok&&n.childNodes)for(const c of n.childNodes)
            if(c.nodeType===Node.TEXT_NODE&&c.nodeValue.toLowerCase().trim().includes(tl)){ok=true;}
        if(ok)hits.push(n);
        if(n.children)for(const c of n.children)scan(c);
        if(n.shadowRoot)scan(n.shadowRoot);
    }
    scan(document.querySelector('flutter-view')||document.body);
    return hits.length?hits[0]:null;
    """
    return driver.execute_script(JS, text)

def js_send(driver, hint, idx):
    JS = """
    function gi(r){let l=Array.from(r.querySelectorAll('input,textarea'));
    for(const e of r.querySelectorAll('*'))if(e.shadowRoot)l=l.concat(gi(e.shadowRoot));return l;}
    const inp=gi(document.querySelector('flutter-view')||document.body);
    const h=arguments[0],i=arguments[1];
    if(i!==null&&i>=0&&i<inp.length)return inp[i];
    if(h){const hl=h.toLowerCase();for(const e of inp){const p=(e.getAttribute('placeholder')||'').toLowerCase();const a=(e.getAttribute('aria-label')||'').toLowerCase();if(p.includes(hl)||a.includes(hl))return e;}}
    return inp.length?inp[0]:null;
    """
    return driver.execute_script(JS, hint, idx)

def click_el(driver, text):
    el = js_find(driver, text)
    if el:
        ac_click(driver, el)
        return True
    return False

def send_keys_el(driver, keys, hint=None, idx=None):
    inp = js_send(driver, hint, idx)
    if inp:
        ac_click(driver, inp)
        time.sleep(0.2)
        ActionChains(driver).key_down(Keys.CONTROL).send_keys("a").key_up(Keys.CONTROL).perform()
        ActionChains(driver).send_keys(keys).perform()
        return True
    return False

def page_text(driver):
    return driver.execute_script(
        "return (document.querySelector('flutter-view')||document.body).textContent||'';"
    )

def wait_page(driver, *phrases, timeout=15):
    t0 = time.time()
    while time.time()-t0 < timeout:
        txt = page_text(driver).lower()
        if any(p.lower() in txt for p in phrases): return True
        time.sleep(0.4)
    return False

chrome_options = Options()
chrome_options.add_argument("--disable-gpu")
chrome_options.add_argument("--window-size=1280,800")

driver = webdriver.Chrome(options=chrome_options)
try:
    driver.get("http://localhost:8080/?enable-semantics=true")
    WebDriverWait(driver, 30).until(EC.presence_of_element_located((By.TAG_NAME, "flt-glass-pane")))
    time.sleep(3)

    # Splash
    click_el(driver, "Track Oral Health")
    time.sleep(1.5)

    # Onboarding
    for _ in range(2):
        click_el(driver, "Next")
        time.sleep(1.2)
    click_el(driver, "Get Started")
    time.sleep(2)

    # Login (user already registered)
    send_keys_el(driver, "prasad93@gmail.com", hint="name@example.com", idx=0)
    time.sleep(0.3)
    send_keys_el(driver, "1234567", hint="********", idx=1)
    time.sleep(0.3)
    click_el(driver, "Log in")
    wait_page(driver, "Consent & Permissions", "Log symptoms", "Basic Information", "Welcome back", timeout=20)
    time.sleep(1)

    # Skip through consent / profile setup / camera if needed
    if "consent & permissions" in page_text(driver).lower():
        click_el(driver, "I Accept & Continue")
        time.sleep(2)
    if "basic information" in page_text(driver).lower():
        send_keys_el(driver, "34", hint="e.g. 35", idx=0)
        click_el(driver, "Female"); click_el(driver, "Continue"); time.sleep(1.2)
        click_el(driver, "No"); click_el(driver, "Continue"); time.sleep(1.2)
        click_el(driver, "Redness"); click_el(driver, "Continue"); time.sleep(1.2)
        click_el(driver, "Light"); click_el(driver, "1-2L"); click_el(driver, "2x")
        click_el(driver, "Continue"); time.sleep(1.2)
        click_el(driver, "Complete Setup"); time.sleep(2)
    if "oral scan" in page_text(driver).lower() or "skip" in page_text(driver).lower():
        click_el(driver, "Skip")
        time.sleep(2)

    wait_page(driver, "Log symptoms", "Hello", "Home", timeout=15)
    print("=== Dashboard reached ===")
    print("Page text snippet:", page_text(driver)[:300])

    # Dump all flt-semantics elements with aria-label or role
    dump_js = """
    let rows = [];
    function scan(node, depth) {
        if (!node) return;
        const tag = node.tagName ? node.tagName.toLowerCase() : "";
        if (tag.startsWith('flt-') || tag === 'input' || tag === 'button') {
            const lbl  = node.getAttribute && node.getAttribute('aria-label')  || '';
            const role = node.getAttribute && node.getAttribute('role')        || '';
            const id   = node.id || '';
            let txt = '';
            if (node.childNodes) {
                for (const c of node.childNodes)
                    if (c.nodeType === Node.TEXT_NODE && c.nodeValue.trim())
                        txt += c.nodeValue.trim() + ' ';
            }
            if (lbl || role || txt.trim()) {
                rows.push('  '.repeat(depth) + '<' + tag +
                    (id   ? ' id="'+id+'"'     : '') +
                    (role ? ' role="'+role+'"'  : '') +
                    (lbl  ? ' aria-label="'+lbl+'"' : '') +
                    (txt.trim() ? ' TEXT:"'+txt.trim()+'"' : '') +
                    '>');
            }
        }
        if (node.children) for (const c of node.children) scan(c, depth+1);
        if (node.shadowRoot)  scan(node.shadowRoot, depth);
    }
    scan(document.querySelector('flutter-view')||document.body, 0);
    return rows.join('\\n');
    """
    result = driver.execute_script(dump_js)
    print("\n=== SEMANTICS DUMP (dashboard) ===")
    print(result[:8000])
    print("==================================")

finally:
    driver.quit()
