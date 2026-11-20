"""Control minimo de la ventana de Studio de un video: traerla al frente, enviar teclas y
clics, y capturar el escritorio. Lo usa rodar.py; a mano sirve para preparar la ventana.

  python ui.py --video NNN frente
  python ui.py --video NNN tecla F11              pantalla completa (otra vez para salir)
  python ui.py --video NNN clic X Y [X Y ...]     coordenadas fisicas de pantalla
  python ui.py foto SALIDA.png                    captura todo el escritorio

Preparacion de la ventana para rodar (se hace una vez; Studio la recuerda):
  1. Cerrar los paneles Toolbox, Terrain Editor, Explorer y Properties (la X de cada uno).
  2. View, quitar "Show View Selector".
  3. Window, Script, quitar "Command Bar".
  4. F11 para pantalla completa.
Las posiciones de esos botones cambian con el idioma, la escala y la version de Studio:
toma una captura con 'foto', mirala y haz los clics que hagan falta. Para devolver todo:
Window, Reset Layout.
"""
import ctypes
import ctypes.wintypes as w
import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

ctypes.windll.shcore.SetProcessDpiAwareness(2)
u = ctypes.windll.user32
VK = {"F11": 0x7A, "ESC": 0x1B, "F5": 0x74, "ALT": 0x12, "ENTER": 0x0D, "CTRL": 0x11, "SHIFT": 0x10}


def ventana(slug):
    hallada = []

    def cb(h, l):
        if u.IsWindowVisible(h):
            n = u.GetWindowTextLengthW(h)
            if n:
                t = ctypes.create_unicode_buffer(n + 1)
                u.GetWindowTextW(h, t, n + 1)
                if slug in t.value and "Roblox Studio" in t.value:
                    hallada.append(h)
        return True

    u.EnumWindows(ctypes.WINFUNCTYPE(ctypes.c_bool, w.HWND, w.LPARAM)(cb), 0)
    return hallada[0] if hallada else None


def frente(slug):
    h = ventana(slug)
    if not h:
        raise SystemExit("no encuentro la ventana de Studio de " + slug)
    if u.GetForegroundWindow() != h:
        # Windows solo deja cambiar el foco si hubo entrada reciente: se simula ALT.
        u.keybd_event(VK["ALT"], 0, 0, 0)
        u.keybd_event(VK["ALT"], 0, 2, 0)
        if u.IsIconic(h):
            u.ShowWindow(h, 9)
        u.SetForegroundWindow(h)
        time.sleep(0.4)
    return h


def es_frente(slug):
    return u.GetForegroundWindow() == ventana(slug)


def clic(x, y):
    u.SetCursorPos(int(x), int(y))
    time.sleep(0.15)
    u.mouse_event(2, 0, 0, 0, 0)
    time.sleep(0.05)
    u.mouse_event(4, 0, 0, 0, 0)
    time.sleep(0.35)


def tecla(nombre):
    codigos = [VK.get(p, ord(p) if len(p) == 1 else None) for p in nombre.upper().split("+")]
    for c in codigos:
        u.keybd_event(c, 0, 0, 0)
        time.sleep(0.03)
    for c in reversed(codigos):
        u.keybd_event(c, 0, 2, 0)
    time.sleep(0.4)


if __name__ == "__main__":
    import base as b
    a = sys.argv[1:]
    if a and a[0] == "foto":
        from PIL import ImageGrab
        ImageGrab.grab().save(a[1])
        print("captura:", a[1])
    else:
        video = b.tomar_video(a)
        frente(video.slug)
        if a[0] == "clic":
            for i in range(1, len(a), 2):
                clic(float(a[i]), float(a[i + 1]))
        elif a[0] == "tecla":
            for t in a[1:]:
                tecla(t)
