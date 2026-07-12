from pathlib import Path

KEYWORDS = ("if ", "elif ", "for ", "while ", "match ")

for file in Path(".").rglob("*.gd"):
    changed = False
    lines = file.read_text(encoding="utf-8").splitlines()

    for i, line in enumerate(lines):
        stripped = line.lstrip()
        if stripped.startswith(KEYWORDS):
            new = line.replace(" -> void:", ":")
            if new != line:
                lines[i] = new
                changed = True

    if changed:
        file.write_text("\n".join(lines) + "\n", encoding="utf-8")
        print(file)
