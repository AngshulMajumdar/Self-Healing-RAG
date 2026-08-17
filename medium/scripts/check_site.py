from html.parser import HTMLParser
from pathlib import Path
import re, sys

ROOT = Path(__file__).resolve().parents[1]
HTML = ROOT / "index.html"

class Parser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.refs=[]
        self.alts=[]
    def handle_starttag(self, tag, attrs):
        d=dict(attrs)
        if tag == 'img':
            self.refs.append(d.get('src',''))
            self.alts.append(d.get('alt',''))
        if tag == 'link' and d.get('rel') == 'stylesheet':
            self.refs.append(d.get('href',''))

p=Parser(); p.feed(HTML.read_text())
missing=[]
for ref in p.refs:
    if not ref or re.match(r'^[a-z]+://', ref):
        continue
    path=(ROOT/ref).resolve()
    if not path.exists(): missing.append(ref)
empty_alt=[i for i,a in enumerate(p.alts,1) if not a.strip()]
tex=sorted((ROOT/'tikz').glob('fig*.tex'))
png=sorted((ROOT/'assets/figures').glob('fig*.png'))
print(f"HTML images: {len(p.alts)}")
print(f"TikZ figures: {len(tex)}")
print(f"Compiled PNGs: {len(png)}")
print(f"Missing local refs: {missing}")
print(f"Empty image alt text: {empty_alt}")
if missing or empty_alt or len(tex) != len(png):
    sys.exit(1)
print("PASS")
