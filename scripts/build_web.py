#!/usr/bin/env python3
"""Genera la versione web di TimeLab (una sola pagina, senza le parti che servono solo all'app per Mac).

Uso:  python3 scripts/build_web.py [src/editor.html] [dist/timelab-web.html]
"""
import os, re, sys

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
src = sys.argv[1] if len(sys.argv) > 1 else os.path.join(root, 'src', 'editor.html')
out = sys.argv[2] if len(sys.argv) > 2 else os.path.join(root, 'dist', 'timelab-web.html')

s = open(src, encoding='utf-8').read()
anchor = 'kbd{'
if s.count(anchor) != 1:
    raise SystemExit('build_web: punto di inserimento CSS non trovato')
s = s.replace(anchor, "\n.btnlink{display:inline-block;padding:5px 10px;border-radius:6px;border:1px solid var(--line);"
              "background:var(--panel2);color:var(--text);text-decoration:none;font-weight:600}\n"
              ".btnlink.primary{background:var(--accent);color:#1a1a1a;border-color:var(--accent)}\n" + anchor)
# blocchi solo-app: <!--APP-->…<!--/APP-->  e  /*APP*/…/*/APP*/
s = re.sub(r'<!--APP-->.*?<!--/APP-->', '', s, flags=re.S)
s = re.sub(r'/\*APP\*/.*?/\*/APP\*/', '', s, flags=re.S)
# blocchi solo-web: <!--WEB … WEB-->  e  /*WEB … WEB*/  (vengono "scommentati")
s = s.replace('<!--WEB', '').replace('WEB-->', '').replace('/*WEB', '').replace('WEB*/', '')

os.makedirs(os.path.dirname(out), exist_ok=True)
open(out, 'w', encoding='utf-8').write(s)
print('versione web:', out, len(s), 'byte')
