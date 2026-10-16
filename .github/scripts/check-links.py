#!/usr/bin/env python3
"""Verifica que los enlaces relativos de los .md apunten a archivos que existen y que las anclas
(#seccion) existan en el documento destino. Se corre en la CI y a mano antes de un pull request.

Se excluyen a proposito los documentos que son PLANTILLAS: se copian a otro proyecto y sus enlaces
apuntan a rutas de ESE proyecto (Docs/03_governance_and_guidelines/...), que aqui no existen.
"""
import pathlib
import re
import sys
import unicodedata

ROOT = pathlib.Path(__file__).resolve().parents[2]
TEMPLATE_PATHS = ("docs/02_governance_templates/", "AGENT_GUIDE.md")
SKIP_PARTS = {".git", "node_modules"}

LINK = re.compile(r'!?\[[^\]\n]*\]\(<?([^)\s>]+)>?(?:\s+"[^"]*")?\)')
HEADING = re.compile(r"^\s{0,3}(#{1,6})\s+(.*?)\s*#*\s*$")
FENCE = re.compile(r"^\s*(```|~~~)")
SCHEME = re.compile(r"^[a-zA-Z][a-zA-Z0-9+.-]*:")


def strip_code(lines):
    """Devuelve las lineas fuera de bloques de codigo, sin spans de codigo en linea."""
    out, in_fence = [], False
    for line in lines:
        if FENCE.match(line):
            in_fence = not in_fence
            continue
        if not in_fence:
            out.append(re.sub(r"`[^`\n]*`", "", line))
    return out


def slug(text):
    text = re.sub(r"<[^>]+>", "", text)
    text = re.sub(r"[*_`]|\[([^\]]*)\]\([^)]*\)", lambda m: m.group(1) or "", text)
    text = unicodedata.normalize("NFC", text).lower()
    text = "".join(ch for ch in text if ch.isalnum() or ch in " -_")
    return text.strip().replace(" ", "-")


def anchors_of(path, cache={}):
    if path not in cache:
        seen, found = {}, set()
        for line in strip_code(path.read_text(encoding="utf-8").splitlines()):
            m = HEADING.match(line)
            if m:
                base = slug(m.group(2))
                n = seen.get(base, 0)
                seen[base] = n + 1
                found.add(base if n == 0 else f"{base}-{n}")
        cache[path] = found
    return cache[path]


def is_template(path):
    rel = path.relative_to(ROOT).as_posix()
    return any(rel == t or rel.startswith(t) for t in TEMPLATE_PATHS)


def main():
    errors, checked = [], 0
    for md in sorted(ROOT.rglob("*.md")):
        if SKIP_PARTS & set(md.relative_to(ROOT).parts) or is_template(md):
            continue
        for line in strip_code(md.read_text(encoding="utf-8").splitlines()):
            for target in LINK.findall(line):
                if SCHEME.match(target):
                    continue
                checked += 1
                path_part, _, anchor = target.partition("#")
                path_part = path_part.split("?")[0]
                dest = md if not path_part else (md.parent / path_part).resolve()
                rel = md.relative_to(ROOT).as_posix()
                if not dest.exists():
                    errors.append(f"{rel}: el enlace '{target}' apunta a un archivo que no existe")
                elif anchor and dest.suffix == ".md" and anchor.lower() not in anchors_of(dest):
                    errors.append(f"{rel}: la ancla '#{anchor}' no existe en {dest.relative_to(ROOT).as_posix()}")
    for e in errors:
        print(f"  X  {e}")
    print(f"Enlaces revisados: {checked}   Rotos: {len(errors)}")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
