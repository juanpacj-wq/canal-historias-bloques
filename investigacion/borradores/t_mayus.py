import re
t = "In this world, friendships have a BATTERY. RED. Two percent. I said NO eleven times. DON'T go. I'M fine. A B."
t = re.sub(r"\b[A-Z][A-Z']{1,}\b", lambda m: m.group(0).lower(), t)
t = re.sub(r"(^|[.!?]\s+)([a-z])", lambda m: m.group(1) + m.group(2).upper(), t)
print(t)
