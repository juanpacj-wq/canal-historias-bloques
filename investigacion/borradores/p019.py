import os
from ed import *
N="019"
for ext in (".md",".txt"):
    os.rename(G/f"019-the-borrower{ext}", G/f"019-the-night-trade{ext}")
sub(N,"# Guion 019: The Borrower","# Guion 019: The Night Trade")
sub(N,"`019-the-borrower.txt`","`019-the-night-trade.txt`")
sub(N,"If the Borrower brings back lost things, it could bring back that.","If our night guest brings back lost things, it could bring back that.")
sub(N,"| If the Borrower brings back lost things... |","| If our night guest brings back lost things... |")
sub(N,'''El
  Borrower nunca se ve''','''El
  visitante nunca se ve''')
sub(N,'''el piso y no se ve nunca, y devuelve tanto como se lleva. Si se quiere
  evitar la coincidencia de título, la alternativa propuesta es "The Night
  Guest".''','''el piso y no se ve nunca, y devuelve tanto como se lleva.
- **Cambio de título (revisión editorial de conjunto, 2026-11-13)**: el guion
  se llamaba "The Borrower". Se cambió a "The Night Trade" porque el título
  viejo queda a una letra de "The Borrowers" (la novela de Mary Norton y sus
  adaptaciones) y en la búsqueda se mezclaba con ella y con la película de
  1991. La alternativa que proponía la autora, "The Night Guest", se descartó:
  es el título de una novela de 2013 sobre una mujer mayor que pierde la
  memoria, demasiado cerca de este tema. Dentro de la narración la criatura
  ya no tiene nombre propio: la narradora usa el apodo de la abuela, "our
  night guest". Los archivos pasaron de `019-the-borrower` a
  `019-the-night-trade`. En el banco de premisas (`docs/05`, premisa 31) sigue
  figurando con el nombre viejo; esa carpeta no se tocó en esta revisión.
  Falta repetir la búsqueda en YouTube con el título nuevo antes de producir.''')
