#!/usr/bin/env python3
"""Test rapido dell'editor: si apre senza errori, ogni banco audio e luci genera lo script per QLab,
i comandi programmati si traducono passando da un banco all'altro.

Requisiti:  pip install playwright  &&  python3 -m playwright install chromium
Uso:        python3 tests/smoke.py            (oppure  python3 tests/smoke.py dist/timelab-web.html)
"""
import os, sys
from playwright.sync_api import sync_playwright

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
page_path = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else os.path.join(root, 'src', 'editor.html'))
fails = []

def check(cond, msg):
    print(('  ok   ' if cond else '  FAIL ') + msg)
    if not cond: fails.append(msg)

with sync_playwright() as p:
    chrome = os.environ.get('CHROME')  # facoltativo: percorso di un Chrome già installato
    b = p.chromium.launch(executable_path=chrome) if chrome else p.chromium.launch()
    pg = b.new_page(viewport={'width': 1280, 'height': 800})
    errors = []
    pg.on('pageerror', lambda e: errors.append(str(e)))
    pg.goto('file://' + page_path)
    pg.wait_for_timeout(600)
    check(pg.title() == 'TimeLab', 'titolo della pagina')

    # una sequenza con comandi audio e luci
    pg.evaluate("""()=>{ const s=document.getElementById('profile'); s.value='x32'; s.dispatchEvent(new Event('change'));
      const l=document.getElementById('lxProfile'); l.value='chamsys'; l.dispatchEvent(new Event('change'));
      addMarker(1,[{t:'Canali:3',op:'close'},{t:'Bus:2',op:'open'},{t:'DCA:1',op:'close'},{t:lxKey('go',1),op:'open'}]); }""")

    profiles = pg.evaluate("()=>Object.keys(PROFILES).filter(k=>k!=='none')")
    for pid in profiles:
        r = pg.evaluate("""(p)=>{ const s=document.getElementById('profile'); s.value=p; s.dispatchEvent(new Event('change'));
            try{ const scr=buildPoolScript(); return {ok:true,len:scr.length,targets:targets.length}; }catch(e){ return {ok:false,err:String(e)}; } }""", pid)
        check(r['ok'], 'banco audio %-10s script generato %s' % (pid, r.get('len', r.get('err'))))

    # ritorno al banco di partenza: i comandi originali devono tornare tutti validi
    r = pg.evaluate("""()=>{ const s=document.getElementById('profile'); s.value='x32'; s.dispatchEvent(new Event('change'));
        return st.markers[0].actions.filter(a=>!isLxKey(a.t)).map(a=>tmap[a.t]?tmap[a.t].label:'? '+a.t); }""")
    check(all(not x.startswith('?') for x in r), 'traduzione andata e ritorno: ' + ', '.join(r))

    for lx in pg.evaluate("()=>Object.keys(LX_PROFILES).filter(k=>k!=='none')"):
        r = pg.evaluate("""(p)=>{ const l=document.getElementById('lxProfile'); l.value=p; l.dispatchEvent(new Event('change'));
            const t=lxTarget(lxKey('go',1)); let scr=''; try{ scr=buildPoolScript(); }catch(e){ return {ok:false,err:String(e)}; }
            return {ok:!!t, info:t&&t.info}; }""", lx)
        check(r['ok'], 'banco luci  %-10s GO = %s' % (lx, r.get('info', r.get('err'))))

    check(not errors, 'nessun errore JavaScript' + ('' if not errors else ': ' + ' | '.join(errors)))
    b.close()

print('\n%s' % ('TUTTO OK' if not fails else '%d PROBLEMI' % len(fails)))
sys.exit(1 if fails else 0)
