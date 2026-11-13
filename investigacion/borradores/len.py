import re, sys
t = open(sys.argv[1], encoding="utf-8").read()
lines = t.split("\n")
i = 0
while i < len(lines):
    if lines[i].startswith("DESCRIPCION CORTA") or lines[i].startswith("DESCRIPCION LARGA"):
        j = i + 2
        body = []
        while j < len(lines) and not re.match(r"^[A-Z][A-Z ]{8,}", lines[j]):
            body.append(lines[j]); j += 1
        print(lines[i][:18], len("\n".join(body).strip()))
        i = j
    else:
        i += 1
