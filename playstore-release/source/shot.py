import json, sys, time
from playwright.sync_api import sync_playwright
OUT = sys.argv[1]
now = int(time.time()*1000)
def sess(dmin, im, isec, tgt, done, comp):
    return dict(ts=now-dmin*60000, intervalMin=im, intervalSec=isec, targetLevels=tgt,
                levelsDone=done, totalElapsed=done*(im*60+isec), completed=comp)
sessions = [sess(60*24*3, 3,13,14,14,True), sess(60*24*2, 3,13,14,9,False),
            sess(60*26, 2,0,10,10,True), sess(60*3, 3,13,14,14,True)]
def prefs(lang, dark, im=3, isec=13, lv=14, hist=True):
    p = {"flutter.lang": json.dumps(lang), "flutter.dark": json.dumps(dark),
         "flutter.intervalMin": json.dumps(im), "flutter.intervalSec": json.dumps(isec),
         "flutter.targetLevels": json.dumps(lv)}
    if hist: p["flutter.zikrSessions"] = json.dumps(json.dumps(sessions))
    return p
def run(page, name, p, action=None):
    page.goto("http://localhost:8765/")
    page.evaluate("p => { localStorage.clear(); for (const k in p) localStorage.setItem(k, p[k]); }", p)
    page.reload(); page.wait_for_timeout(6000)
    if action: action(page)
    page.screenshot(path=f"{OUT}/{name}.png")

def click(x,y,wait=1500):
    def f(page):
        page.mouse.click(x,y); page.wait_for_timeout(wait)
    return f
def seq(*fs):
    def f(page):
        for g in fs: g(page)
    return f
START=(68,642); HIST=(180,707)
with sync_playwright() as pw:
    b = pw.chromium.launch(args=["--use-gl=swiftshader","--enable-unsafe-swiftshader"])
    page = b.new_page(viewport={"width":360,"height":720}, device_scale_factor=3)
    run(page, "phone_02_light", prefs("en", False))
    run(page, "phone_03_history", prefs("en", True), click(*HIST))
    run(page, "phone_04_urdu", prefs("ur", True))
    run(page, "phone_05_complete_light", prefs("en", False, 0, 2, 3), click(*START, 8000))
    run(page, "phone_06_urdu_history_light", prefs("ur", False), click(*HIST))
    run(page, "phone_01_running", prefs("en", True, 0, 30, 14), click(*START, 75500))
    for name,(w,h) in {"tablet7":(600,960),"tablet10":(800,1280)}.items():
        page = b.new_page(viewport={"width":w,"height":h}, device_scale_factor=2)
        run(page, f"{name}_01_dark", prefs("en", True))
        run(page, f"{name}_02_light", prefs("en", False))
        run(page, f"{name}_03_urdu", prefs("ur", True))
    b.close()
