import json,sys,re,html
d=json.load(open(sys.argv[1],encoding='utf-8'))
print('TITLE:',d.get('title'),'| created',d.get('created_at'))
pats=[re.compile(p,re.I) for p in sys.argv[3:]]
for p in d['post_stream']['posts'][:int(sys.argv[2])]:
    t=html.unescape(re.sub(r'<[^>]+>','',p['cooked']))
    sents=re.split(r'(?<=[.!?])\s+|\n+',t)
    hits=[s.strip() for s in sents if any(q.search(s) for q in pats)]
    if hits:
        print('--',p['username'],p['created_at'][:10],'staff' if p.get('staff') or p.get('primary_group_name') else '', p.get('user_title') or '')
        for h in hits[:8]: print('   ',h[:420])
