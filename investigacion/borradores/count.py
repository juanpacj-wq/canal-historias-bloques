import re, sys, glob, os
d = sys.argv[1]
for f in sorted(glob.glob(os.path.join(d, '0*.txt'))):
    if '001-' in f: continue
    t = open(f, encoding='utf-8').read()
    paras = [p for p in t.strip().split('\n\n')]
    counts = [len(p.split()) for p in paras]
    sents = [s for s in re.split(r'(?<=[.?!])["\']?\s+', t) if s.strip()]
    longs = [s for s in sents if len(s.split()) >= 14]
    print(os.path.basename(f), 'total', sum(counts), 'blocks', counts, 'paras', len(paras),
          'emdash', t.count('—'), 'sent', len(sents), 'long', len(longs))
    md = f[:-4] + '.md'
    if os.path.exists(md):
        m = open(md, encoding='utf-8').read()
        nar = m.split('## Narración')[1].split('## Lista de planos')[0]
        got = [l.strip() for l in nar.split('\n') if l.strip() and not l.startswith('**[') and l.strip() in paras]
        rows = [l for l in m.split('\n') if re.match(r'^\| \d+ \|', l)]
        print('   md: narration match', got == paras, '| planos', len(rows), '| emdash', m.count('—'),
              '| count stated', re.findall(r'Palabras[^\n]*', m)[:1])
