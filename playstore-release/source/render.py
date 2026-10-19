import sys
from urllib.parse import urlencode
from playwright.sync_api import sync_playwright
D, OUT = sys.argv[1], sys.argv[2]
frames = [
 ("01","phone_01_running","dark","An interval timer made for zikr","Each level ends with a gentle beep",""),
 ("02","phone_02_light","light","Set the interval and the levels","Total duration is worked out for you",""),
 ("03","phone_03_history","dark","Every session, remembered","Completed and stopped sessions are saved",""),
 ("04","phone_04_urdu","dark","مکمل اردو، دائیں سے بائیں","انگریزی اور اردو دونوں زبانیں","1"),
 ("05","phone_05_complete_light","light","Know when you are done","A clear finish after the last level",""),
 ("06","phone_06_urdu_history_light","light","پچھلے سیشنز اردو میں","ہلکا اور گہرا تھیم","1"),
]
with sync_playwright() as pw:
    b = pw.chromium.launch()
    p = b.new_page(viewport={"width":1024,"height":500})
    p.goto(f"file://{D}/feature.html"); p.wait_for_timeout(2500)
    p.screenshot(path=f"{OUT}/feature-graphic-1024x500.png")
    p = b.new_page(viewport={"width":1080,"height":1920})
    for n,img,theme,t,s,ur in frames:
        q = dict(img=f"{img}.png",theme=theme,t=t,s=s)
        if ur: q["ur"]="1"
        p.goto(f"file://{D}/frame.html?"+urlencode(q)); p.wait_for_timeout(2500)
        p.screenshot(path=f"{OUT}/{n}.png")
    b.close()
