import json,sys,re,html
p=sys.argv[1]
d=json.load(open(p,encoding='utf-8'))
a=d.get('article',d)
print('TITLE:',a.get('title'),'| updated:',a.get('updated_at'),'| edited:',a.get('edited_at'))
t=a.get('body') or ''
t=re.sub(r'<(br|/p|/li|/h\d|/tr)[^>]*>','\n',t)
t=html.unescape(re.sub(r'<[^>]+>','',t))
t=re.sub(r'\n\s*\n+','\n',t)
open(p.replace('.json','.txt'),'w',encoding='utf-8').write(t)
if len(sys.argv)>2: print(t[:int(sys.argv[2])])
