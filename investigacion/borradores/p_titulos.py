import re
from ed import *

TIT = {
"001": ("In This World, Friendships Have a Battery", "The Battery"),
"002": ("In This World, Your Heartbeat Plays Out Loud as Music", "The Quiet Heart"),
"003": ('In This World, You Only Get Three "I Love Yous"', "Three Lights"),
"004": ("In This World, Your Shadow Walks Toward Who You Like", "The Yellow Umbrella"),
"005": ("In This Town, Breakups Make It Snow", "The Snow Cloud"),
"006": ("In This Town, Inside Jokes Become Pets", "Long Distance"),
"007": ("In This World, Everyone Can See Who You Miss", "Foggy Barty"),
"008": ("In This World, You Can Lend Your Courage", "The Orange Marble"),
"009": ("In This Town, Apologies Are Paid in Memories", "The Blanket Fort"),
"010": ("In This World, Your Best Friend Is Chosen by Lottery", "The Green Crayon"),
"011": ("In This World, Parents Can Pause Their Kids", "The Clicker"),
"012": ("In This World, You Inherit Your Parents' Fears", "The 3:15 Text"),
"013": ("In This World, Hugs Are Counted", "The Last Hug"),
"014": ("In This School, Your Grades Appear on Your Forehead", "The Question Mark"),
"015": ("In This School, Rumors Become Graffiti", "The Gym Wall"),
"016": ("In This School, the Quietest Kid Controls the Weather", "The Weather Kid"),
"017": ("In This World, Your Backpack Weighs Your Worries", "The Kite"),
"018": ("The Echo", "In This Town, the Echo Says What You Really Think"),
"019": ("The Night Trade", "In This Town, Something Takes One Thing Every Night"),
"020": ("In This Town, Nobody Opens After the Third Knock", "The Third Knock"),
"021": ("In This World, Forgotten Things Go to the Basement", "The Bottom Step"),
"022": ("In This World, Excuses Become True", "No Take-Backs"),
"023": ("In This World, Pets Write Reviews of Their Owners", "One Star"),
"024": ("In This Town, You Can Only Lie on Tuesdays", "The Tuesday List"),
"025": ("The Tunda", "In This Town, You Check Your Mother's Feet First"),
}

MAY = {
"001": ["every friendship has a *battery*", "*Red*. *Two* percent.", "At *zero*, a friendship shuts off", "The bar has *two halves*.", "Mine was *empty*.", "It *exploded*."],
"002": ["plays out loud as *music*", "one long *car alarm*", 'wrote "*weird*" on my chart', "She has not slept in *nine* days", "You got the *broken* one", "the only *quiet* place", "she was *asleep*"],
"003": ['"I love you" *three* times', "Then *never* again.", "I have *one* left.", "My last light went *dark*.", "*Nothing* came out.", 'my sneakers. "Got your shoes *tied*?"', "about *five thousand* times", "I'm at *zero* now"],
"004": ["your *shadow* walks toward", "you can't call it *back*", "At sunset, your shadow is *forty* feet long.", "I got *nine* shadows", "One of them was *waving*.", "I *like* you. Sorry", "My shadow likes *nachos*.", "I get to *pick* for myself"],
"005": ["makes it *snow*", "Big breakup, a *blizzard*.", "The sky *checks*.", "The snow is all on *my* side", "nobody asks the *little brother*", "It *aimed*.", '"*Left*."', "break up with *me*, too?", "One *tiny* cloud."],
"006": ["turns into a *pet*", "the pet goes *see-through*.", "Boom. *Duck*.", "we were down to *six*", "jokes don't *travel* well", "been *fake* laughing since", "*Real* laughing.", "He is getting *extremely* fat."],
"007": ["see who you *miss*,", "My biggest *rival*.", "He has *eyebrows* now.", "Now I had *two* fogs.", "*Disgusting*.", "I *miss* you, okay?", "My fog *popped* like", "*No* fog.", "Just to *boo* me."],
"008": ["you can *lend* your courage", "you have *none* until", "buttoned it. *Twice*. He sang", "back takes *courage*.", "*Soup* is hot, and it moves.", "Bram's table with *nothing*", "Still warm. He never *used* it.", "So I just sang *scared*.", "You walked over here *without* it?"],
"009": ["one happy *memory*,", "lost a whole *beach trip*", "I've *never* said sorry", '"My bad" costs *nothing*.', '"I\'m *sorry*. I don\'t want your room.', "I want *you* in it.", "A blanket. *One* spoon.", "I don't *remember* that blackout", "remembers that night *twice*"],
"010": ["a *lottery* picks", "stuck with them by *law*", "My *worst enemy*.", "*Zero* words.", "*Nothing* came out.", "I ate the *blue* one."],
"011": ["gets *ten* pauses", "one click *freezes* their kid", "She *never* used one.", '"*Pause* me," I said.', "You were *never* easy.", "I'm *awake* for", "the clicker went *dark*", "I can pause *myself*"],
"012": ["your dad's biggest *fear*", "he loses it *forever*", "you can't give it *back*", 'one word. "*Home*?"', "my knees turned to *pudding*", "was never *fire*", "I'm *scared* all the time now", '"*Badly*," Dad said.', "I think it *grew* back."],
"013": ["one *thousand* hugs", "opens their arms *first*. So", "hit *zero* before the cake", "I have *four* left", "It counted. *Three*.", "Trees never go first. *Two*.", "It charged us both. *One*.", "Then she opened hers. *Wide*.", "I was *saving* them.", "She always goes *first*."],
"014": ["glows on your *forehead*", "It shows a *question mark*.", "Partners share *one* grade.", '"the *wrong* orange."', "*Wrong* word.", "*None* turned in.", "it can't be *wrong*.\"", '"See? *Still here*.', "*B-plus*. She forgot"],
"016": ["follows the *mood* of", "talks the *least*", "I talk the *most*.", "I *closed* it.", "I said *nothing*.", '"Oh. You *too*?"'],
"017": ["as much as your *worries*", "emptying it doesn't *help*", "Mine *floats* too.", "his bag wouldn't *move* at all", '"It\'s *fine*! I\'ll just', 'Yours *floats*."', "put *one* in mine", "That one's *mine* now.", "carrying my *half*", "*Best* backache"],
"019": ["takes *one* thing from your house", "one thing you *lost* years ago", "The trade is always *fair*.", 'Since March, she calls me "the *nice girl*."', "Night four, I left *nothing*.", '"*Pidge*," she said.', "it *washed* the cup"],
"020": ["after the *third* knock.", "*Three* knocks is something else.", "Like it's *sorry*.", "I *opened* the door.", '"*Two* is for neighbors."', "Knock *twice*."],
"022": ["every *excuse* you say", "comes *true*.", "there are no *take-backs*.", "Now I have a *Thing*.", "I'm fourteen and I can't *swim*.", "Our whole *house* was out of town", "The truth doesn't *poof*.", "Our deep end is *broken*!", "The whole pool was *two feet* deep", "Now there are *two*."],
"023": ["writes a *review* of its owner", '"*One star*. He sings', "and you *lose* your pet", '"*Half* a star.', "You *win*.", '"*Two* stars.', "I'm *staying*.", "*Zero* stars."],
"024": ["only lie on *Tuesdays*.", "only the *truth* comes out", "*Nobody* believes one word", '"*Gotcha*, it\'s Tuesday."', "For *real*.\"", "on a *Wednesday*, I said", '"*Finally*," she said.'],
"025": ["look at her *feet* before you answer", "call it the *Tunda*.", "One foot is always *wood*.", "So we check *feet*.", "You have to look *down* yourself.", "A *perfect* one.", "I *almost* took it.", "I *knew*.", "But Mom can't *whistle*.", '"Mom. Come *home*."'],
}

for num, (titulo, alterno) in TIT.items():
    t = leer(num)
    lineas = t.split("\n")
    m = re.match(r"(# Guion(?: piloto)? \d{3}: )(.*)$", lineas[0])
    assert m, (num, lineas[0])
    lineas[0] = m.group(1) + titulo
    lineas = [l for l in lineas if not l.startswith("- **Título alterno**:")]
    # última línea de la primera lista de viñetas
    i = next(k for k, l in enumerate(lineas) if l.startswith("- **"))
    j = i
    while j + 1 < len(lineas) and (lineas[j + 1].startswith("- ") or (lineas[j + 1].startswith("  ") and lineas[j + 1].strip())):
        j += 1
    lineas.insert(j + 1, f"- **Título alterno**: {alterno}")
    t = "\n".join(lineas)

    if num in MAY:
        ini = t.index("## Narración")
        fin = t.index("\n## ", ini + 5)
        narr = t[ini:fin]
        for marca in MAY[num]:
            plano = marca.replace("*", "")
            assert narr.count(plano) == 1, (num, marca, narr.count(plano))
            nuevo = re.sub(r"\*(.+?)\*", lambda mm: mm.group(1).upper(), marca)
            narr = narr.replace(plano, nuevo)
        t = t[:ini] + narr + t[fin:]
    escribir(num, t)
print("ok")
