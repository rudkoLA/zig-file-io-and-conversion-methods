import random

with open("large.md", "w", encoding="utf-8") as file:
    for _ in range(50_000_000):
        file.write(f"{random.randint(0, 10**8)}\n")
