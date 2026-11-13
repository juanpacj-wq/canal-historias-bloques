import sys, time, re, json, urllib.request, urllib.error
UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Safari/537.36"
def get(url, cookies=None):
    h = {"User-Agent": UA, "Accept-Language": "en-US,en;q=0.9"}
    if cookies: h["Cookie"] = cookies
    try:
        r = urllib.request.urlopen(urllib.request.Request(url, headers=h), timeout=25)
        return r.status, r.geturl(), r.read().decode("utf-8", "replace")
    except urllib.error.HTTPError as e:
        try: b = e.read().decode("utf-8", "replace")
        except Exception: b = ""
        return e.code, url, b
    except Exception as e:
        return -1, url, str(e)
def yt(n):
    s, u, b = get(f"https://www.youtube.com/@{n}", "SOCS=CAI; CONSENT=YES+1")
    if s == 404: return "LIBRE(404)"
    if s == 200:
        if "consent.youtube.com" in u or "consent.google.com" in u: return "CONSENT?"
        m = re.search(r'"channelId":"(UC[\w-]{22})"', b) or re.search(r'channel/(UC[\w-]{22})', b)
        t = re.search(r'<title>(.*?)</title>', b)
        subs = re.search(r'"([\d.,]+[KM]? subscribers?)"', b)
        if m: return f"OCUPADO {m.group(1)} | {t.group(1) if t else ''} | {subs.group(1) if subs else ''}"
        return f"200 sin canal? len={len(b)}"
    return f"HTTP {s}"
def tt(n):
    s, u, b = get(f"https://www.tiktok.com/@{n}")
    if s != 200: return f"HTTP {s}"
    m = re.search(r'"statusCode":(\d+)', b)
    has = f'"uniqueId":"{n.lower()}"' in b.lower()
    if has: return "existe"
    if m and m.group(1) == "10221" or '"statusCode":10221' in b: return "no existe(10221)"
    if m and m.group(1) == "10202": return "no existe(10202)"
    return f"indeterminado sc={m.group(1) if m else None}"
def ig(n):
    s, u, b = get(f"https://www.instagram.com/{n}/")
    if s == 404: return "no existe(404)"
    if s == 200:
        if "accounts/login" in u: return "indeterminado(login)"
        t = re.search(r'<title>(.*?)</title>', b, re.S)
        tt_ = t.group(1).strip() if t else ""
        if f"@{n.lower()}" in tt_.lower() or f"({n.lower()})" in b.lower()[:200000] and "og:title" in b: 
            return "existe"
        if 'og:title' in b: return "existe?"
        return f"indeterminado(title={tt_[:30]!r})"
    return f"HTTP {s}"
names = [l.strip() for l in open(sys.argv[1]) if l.strip()]
what = sys.argv[2] if len(sys.argv) > 2 else "yt"
out = {}
for n in names:
    r = {}
    if "yt" in what: r["yt"] = yt(n); time.sleep(2.5)
    if "tt" in what: r["tt"] = tt(n); time.sleep(2)
    if "ig" in what: r["ig"] = ig(n); time.sleep(2.5)
    out[n] = r
    print(n, json.dumps(r, ensure_ascii=False), flush=True)
json.dump(out, open(f"res_{what}.json", "w"), ensure_ascii=False, indent=1)
