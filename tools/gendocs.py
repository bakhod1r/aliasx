#!/usr/bin/env python3
"""Generate docs/*.html (GitHub Pages) from aliases/*.sh and optional/*.sh.

Conventions read from module files:
  first comment line          module title (text before the first '.' or ':')
  # == Section                starts a table
  alias name='command'        one row
  # name ARGS — description   followed by name() { ... }: one function row
  if has TOOL / has TOOL &&   rows get a "needs TOOL" note
  if [ "$ALIASX_OS" = macos ] rows get a macOS / Linux note
"""
import html
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"

PAGES = [  # (file stem, folder, page title)
    ("core", "aliases", "Core"),
    ("hints", "aliases", "Hints"),
    ("completion", "aliases", "Completion"),
    ("nav", "aliases", "Navigation"),
    ("files", "aliases", "Files"),
    ("git", "aliases", "Git"),
    ("docker", "aliases", "Docker"),
    ("podman", "aliases", "Podman"),
    ("k8s", "aliases", "Kubernetes"),
    ("infra", "aliases", "Infrastructure"),
    ("ops", "aliases", "DevOps"),
    ("admin", "aliases", "Sysadmin"),
    ("net", "aliases", "Network"),
    ("system", "aliases", "System"),
    ("dev", "aliases", "Development"),
    ("api", "aliases", "Backend & API"),
    ("db", "aliases", "Databases"),
    ("nginx", "aliases", "nginx"),
    ("remote", "aliases", "SSH & tmux"),
    ("util", "aliases", "Utilities"),
    ("dotenv", "aliases", ".env files"),
    ("cloud", "aliases", "Cloud"),
    ("tools", "aliases", "Modern tools"),
    ("modern", "optional", "Modern replacements"),
    ("dangerous", "optional", "Dangerous helpers"),
]

ALIAS = re.compile(r"""alias (?:-- )?([^=\s]+)=(['"])(.*?)\2(?:\s+# (.*))?$""")
FUNC_DOC = re.compile(r"^# ([A-Za-z_][\w-]*)((?: [^—]*)?) — (.+)$")
FUNC_DEF = re.compile(r"^(?:function )?([A-Za-z_][\w-]*)(?:\(\)| \{)")
HAS = re.compile(r"\bhas ([\w-]+)")


def parse(path):
    lines = path.read_text().splitlines()
    title_line = lines[0].lstrip("# ").strip()
    intro = []
    for l in lines[1:]:
        if not l.startswith("#") or l.startswith("# =="):
            break
        intro.append(l.lstrip("# ").strip())
    sections, current = [], {"name": "General", "rows": []}
    guards, pending_doc, example = [], None, []

    for idx, raw in enumerate(lines[1:], 1):
        line = raw.strip()
        if line.startswith("# =="):
            if current["rows"]:
                sections.append(current)
            current = {"name": line[4:].strip(), "rows": []}
            continue
        m = FUNC_DOC.match(line)
        if m:
            pending_doc = m
            example = []
            continue
        if pending_doc and raw.lstrip().startswith("#   "):
            example.append(raw.lstrip()[4:])
            continue
        if line.startswith("if ") and not line.endswith("then"):
            continue
        if line.startswith("if "):
            if "ALIASX_OS" in line:
                guards.append("macOS" if "macos" in line else "Linux")
            else:
                guards.append(", ".join("needs " + t for t in HAS.findall(line)) or "")
            continue
        if line == "else" and guards and guards[-1] in ("macOS", "Linux"):
            guards[-1] = "Linux" if guards[-1] == "macOS" else "macOS"
            continue
        if line.startswith("elif ") or line == "else":
            continue
        if line == "fi" or line.endswith("; fi"):
            if line == "fi" and guards:
                guards.pop()
            continue
        notes = [g for g in guards if g]
        notes += ["needs " + t for t in HAS.findall(line.split("alias")[0])] if "alias" in line else []
        a = ALIAS.search(line)
        if a and not line.startswith("#"):
            cmd = a.group(3).replace("$_aliasx_ls", "ls -F --group-directories-first").replace("${_aliasx_ngroot}", "asroot ")
            current["rows"].append((a.group(1), cmd, a.group(4) or "", notes, "", ""))
            continue
        f = FUNC_DEF.match(line)
        if f and pending_doc and pending_doc.group(1) == f.group(1):
            usage = (pending_doc.group(1) + pending_doc.group(2)).strip()
            current["rows"].append((usage, "", pending_doc.group(3), notes, func_source(lines, idx), "\n".join(example)))
        pending_doc = None if not line.startswith("#") else pending_doc
    if current["rows"]:
        sections.append(current)
    return title_line, intro, sections


def func_source(lines, start):
    """Lines of the function starting at lines[start], dedented."""
    first = lines[start]
    indent = len(first) - len(first.lstrip())
    body = [first]
    if not first.rstrip().endswith("}"):
        for l in lines[start + 1:]:
            body.append(l)
            if l.rstrip() == " " * indent + "}":
                break
    return "\n".join(l[indent:] if l[:indent].strip() == "" else l for l in body)


def nav(active):
    items = ['<a href="index.html"%s>Getting started</a>' % (' class="on"' if active == "index" else "")]
    for stem, folder, title in PAGES:
        label = title + (" ·opt-in" if folder == "optional" else "")
        on = ' class="on"' if stem == active else ""
        items.append('<a href="%s.html"%s>%s</a>' % (stem, on, html.escape(label)))
    search = ('<div class="search"><input id="q" type="search" placeholder="Search: port, git, logs…" '
              'autocomplete="off" aria-label="Search commands"><div id="results" hidden></div></div>')
    return "<nav>\n  <b>aliasx</b>\n  " + search + "\n  " + "\n  ".join(items) + "\n</nav>"


def page(active, title, body):
    return f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>{html.escape(title)}</title>
<link rel="stylesheet" href="style.css">
<script src="search.js" defer></script>
</head>
<body>
{nav(active)}
<main>
{body}
</main>
<dialog id="code"><div class="dlg-head"><b id="code-title"></b><span><button id="code-copy">copy</button> <button id="code-close" aria-label="Close">✕</button></span></div><pre id="code-body"></pre></dialog>
<script>
(function () {{
  var q = document.getElementById("q"), res = document.getElementById("results");
  function esc(t) {{ return t.replace(/[&<>"]/g, function (c) {{ return {{"&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;"}}[c]; }}); }}
  function search() {{
    var w = q.value.trim().toLowerCase(), idx = window.ALIASX_INDEX || [];
    if (!w) {{ res.hidden = true; return; }}
    var word = new RegExp("(^|[^a-z0-9])" + w.replace(/[^a-z0-9_-]/g, ""), "i");
    var hits = idx.filter(function (e) {{ return e[0].toLowerCase().indexOf(w) >= 0; }})
      .concat(idx.filter(function (e) {{ return e[0].toLowerCase().indexOf(w) < 0 && word.test(e[1] + " " + e[2] + " " + e[3]); }}))
      .slice(0, 30);
    res.innerHTML = hits.length ? hits.map(function (e) {{
      return '<a href="' + e[4] + '.html#n-' + encodeURIComponent(e[0]) + '"><code>' + esc(e[1]) + '</code><span>' + esc(e[3] || e[2]) + '</span></a>';
    }}).join("") : '<p class="muted">No match</p>';
    res.hidden = false;
  }}
  if (q) {{
    q.addEventListener("input", search);
    q.addEventListener("keydown", function (e) {{
      if (e.key === "Enter") {{ var a = res.querySelector("a"); if (a) location.href = a.href; }}
      if (e.key === "Escape") {{ q.value = ""; res.hidden = true; }}
    }});
    document.addEventListener("keydown", function (e) {{
      if (e.key === "/" && document.activeElement !== q) {{ e.preventDefault(); q.focus(); }}
    }});
  }}
  var on = document.querySelector("nav a.on");
  if (on) on.parentNode.scrollTop = on.offsetTop - on.parentNode.clientHeight / 2;
  var d = document.getElementById("code"), body = document.getElementById("code-body");
  if (!d) return;
  document.addEventListener("click", function (e) {{
    var b = e.target.closest("button.fn");
    if (b) {{
      body.textContent = document.getElementById(b.dataset.src).content.textContent;
      document.getElementById("code-title").textContent = b.dataset.name + "()";
      d.showModal();
    }} else if (e.target.id === "code-close" || e.target === d) d.close();
    else if (e.target.id === "code-copy") {{
      navigator.clipboard && navigator.clipboard.writeText(body.textContent);
      e.target.textContent = "copied"; setTimeout(function () {{ e.target.textContent = "copy"; }}, 1200);
    }}
  }});
}})();
</script>
</body>
</html>
"""


def module_page(stem, folder, title):
    head, intro, sections = parse(ROOT / folder / f"{stem}.sh")
    out = [f"<h1>{html.escape(title)}</h1>", f"<p>{html.escape(head)}</p>"]
    for line in intro:
        out.append(f"<p class=\"muted\">{html.escape(line)}</p>")
    if folder == "optional":
        out.append(f'<p>Not loaded by default. Enable: <code>export ALIASX_ENABLE="{stem}"</code></p>')
    elif stem != "core":
        out.append(f'<p>File <code>{folder}/{stem}.sh</code>. Disable: <code>export ALIASX_DISABLE="{stem}"</code></p>')
    count = 0
    for s in sections:
        out.append(f"<h2>{html.escape(s['name'])}</h2>")
        out.append("<table>\n<tr><th>Name</th><th>Runs</th><th>What it does</th><th></th></tr>")
        for name, cmd, desc, notes, src, ex in s["rows"]:
            count += 1
            if src:
                fid = f"fn{count}"
                out.append(f'<template id="{fid}">{html.escape(src)}</template>')
                run = f'<button class="fn" data-src="{fid}" data-name="{html.escape(name.split()[0])}">show code</button>'
            else:
                run = f"<code>{html.escape(cmd)}</code>"
            run += f"</td><td>{html.escape(desc)}"
            if ex:
                first, _, rest = ex.partition("\n")
                shown = f'<span class="cmd">{html.escape(first)}</span>' + ("\n" + html.escape(rest) if rest else "")
                run += f'<details class="ex" open><summary>example</summary><pre>{shown}</pre></details>'
            note = html.escape(", ".join(dict.fromkeys(notes)))
            key = name.split()[0]
            SEARCH.append([key, name, cmd, desc, stem])
            out.append(f"<tr id=\"n-{html.escape(key)}\"><td><code>{html.escape(name)}</code></td><td>{run}</td><td class=\"muted\">{note}</td></tr>")
        out.append("</table>")
    return page(stem, f"{title} — aliasx", "\n".join(out)), count


INDEX = """<h1>aliasx</h1>
<p>Safe, modular shell aliases for bash and zsh on Linux and macOS. {total} aliases and functions in {mods} modules.</p>

<h2>Install</h2>
<pre>git clone https://github.com/bakhod1r/aliasx ~/.aliasx
~/.aliasx/install.sh</pre>
<p><code>install.sh</code> adds one line to <code>~/.bashrc</code> and <code>~/.zshrc</code>. Running it again changes nothing. Open a new shell.</p>
<p>oh-my-zsh: clone into <code>$ZSH_CUSTOM/plugins/aliasx</code> and add <code>aliasx</code> to <code>plugins=(...)</code>.</p>

<h2>Profiles</h2>
<pre>export ALIASX_PROFILE=backend     # devops, sysadmin, minimal; combine: "backend devops"
aliasx profiles                   # what each profile loads</pre>

<h2>Your own aliases</h2>
<pre>aliasx add deploy './scripts/deploy.sh --prod' "deploy to production"
aliasx mine
aliasx rm deploy</pre>
<p>Saved in <code>~/.aliasx.local.sh</code>, loaded last, with hints and search like built-in ones.</p>

<h2>Configure</h2>
<pre>export ALIASX_DISABLE="docker k8s"      # skip default modules
export ALIASX_ENABLE="modern dangerous"  # load opt-in modules</pre>
<p>Set these before the aliasx line in your rc file.</p>

<h2>Inspect</h2>
<pre>aliasx modules          # list modules
aliasx list git         # aliases in one module
aliasx check gs k tf    # is a name taken?
aliasx conflicts        # names that hide programs or clash with your rc files
aliasx doctor           # version, shell, profile, install state
aliasx update           # pull the latest version
aliasx why lni          # lni → ln -i · link, ask before overwriting</pre>

<h2>Hints</h2>
<p>Type an aliasx name and press Space: zsh shows what it does under the prompt.</p>
<pre>$ lni █
lni → ln -i · link, ask before overwriting</pre>
<p>Don't know the name? Type a word like <code>port</code> and press Space: related commands are listed.</p>
<pre>$ port █
related commands:
ports [PORT] · listening TCP ports, or who listens on PORT
freeport PORT · kill what listens on PORT after y/N
waitport HOST PORT [SEC] · wait until PORT accepts connections</pre>
<p>Same in any shell: <code>aliasx find port</code>. Turn lists off with <code>ALIASX_FIND=0</code>.</p>
<p>bash 4+ prints the hint above the prompt. bash 3 (macOS default) has no live hook; use <code>aliasx why</code>.</p>

<h2>Safe mode</h2>
<pre>aliasx mode safe     # rm lists targets and asks [Y/n]
aliasx mode normal   # plain rm
aliasx mode          # show current mode
export ALIASX_MODE=safe   # keep it on (put in rc before aliasx)</pre>

<h2>Rules</h2>
<ul>
<li>Tool modules load only when the tool is installed (<code>has docker</code>, <code>has kubectl</code>…).</li>
<li>Standard commands (<code>cp</code>, <code>mv</code>, <code>rm</code>, <code>cat</code>, <code>top</code>, <code>ping</code>) are never replaced by default. Safe variants get new names: <code>cpi</code>, <code>mvi</code>, <code>rmi</code>.</li>
<li>Destructive actions show what they will touch and ask first. Bulk deletes live in the opt-in <a href="dangerous.html">dangerous</a> module and need a typed phrase.</li>
<li>No implicit <code>sudo</code> outside package and power commands. No <code>-y</code> on upgrades.</li>
<li>One meaning per name: <code>h</code> is history, Helm uses <code>hm</code>; Rust uses <code>cargo-*</code>; pnpm uses <code>pn*</code>.</li>
</ul>

<h2>Modules</h2>
<table>
<tr><th>Module</th><th>Covers</th><th>Count</th></tr>
{rows}
</table>

<h2>Uninstall</h2>
<pre>~/.aliasx/install.sh --uninstall</pre>
"""


SEARCH = []


def main():
    rows, total = [], 0
    for stem, folder, title in PAGES:
        text, count = module_page(stem, folder, title)
        (DOCS / f"{stem}.html").write_text(text)
        total += count
        head = parse(ROOT / folder / f"{stem}.sh")[0]
        tag = " <span class=\"muted\">opt-in</span>" if folder == "optional" else ""
        rows.append(f'<tr><td><a href="{stem}.html">{html.escape(title)}</a>{tag}</td><td>{html.escape(head)}</td><td>{count}</td></tr>')
    body = INDEX.format(total=total, mods=len(PAGES), rows="\n".join(rows))
    (DOCS / "index.html").write_text(page("index", "aliasx", body))
    (DOCS / "search.js").write_text("window.ALIASX_INDEX=" + json.dumps(SEARCH, ensure_ascii=False) + ";\n")
    print(f"docs: {len(PAGES) + 1} pages, {total} entries")


if __name__ == "__main__":
    main()
