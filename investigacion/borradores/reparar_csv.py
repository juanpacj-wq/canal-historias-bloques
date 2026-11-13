import csv, sys, io
p = sys.argv[1]
texto = open(p, encoding="utf-8", newline="").read()
filas = list(csv.reader(io.StringIO(texto)))
n = len(filas[0])
malas = 0
for i, f in enumerate(filas):
    while len(f) > n:
        # une el primer campo cuyo siguiente empieza con espacio (rastro del reemplazo)
        for j in range(len(f) - 1):
            if f[j + 1].startswith(" "):
                f[j] = f[j] + " -" + f[j + 1]
                del f[j + 1]
                break
        else:
            print("no se pudo reparar la fila", i, len(f)); break
        malas += 1
    filas[i] = f
print("columnas:", n, "filas:", len(filas), "uniones:", malas, "filas con columnas distintas:", sum(1 for f in filas if len(f) != n))
with open(p, "w", encoding="utf-8", newline="") as s:
    csv.writer(s).writerows(filas)
