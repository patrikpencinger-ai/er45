# ER45 — original-site archive, decoded

An analysis of the old backup at **`C:\Users\patri\OneDrive\Backup\ER45`**
(~33,900 files, ~1.6 GB). This file just *describes* the archive — the archive
itself is not part of this repo. Goal: make sense of what's in there so it can
feed the er45.com revival.

> TL;DR — **ER45 was a Croatian electronic-music web portal** (techno / house /
> drum'n'bass) from roughly **1999–2003**: party calendar, DJ interviews & bios,
> party photo galleries, a forum, contests, an "ER45 Lounge", and its own audio
> productions. Run by **Patrik Pencinger**; it grew out of an earlier site called
> **Urban Fetish** and was rebuilt across several generations (V2 → V3 → a PHP
> forum era). The V3 plan already split the site **across subdomains** — the same
> idea the memorial page references.

---

## 1. What ER45 was
- **Genre/scene:** clubbing, nightlife, DJ culture — techno, house, drum'n'bass
  (`META novog sajta.txt` literally: "clubbing, nightlife, dj, techno").
- **Region:** Croatia — Istria/Pula (folders/files reference *Valkana Beach*,
  *Puntižela*, plus Zagreb) and the wider ex-Yugoslav scene (Slovenia: `SLO_PIX`,
  Celje). Coverage was both local and international.
- **Era:** earliest content ~**1999** ("love parade '99" gallery); site snapshots
  dated **Feb 2002** (`240202`) and **22 Jan 2003** (`22012003_www.er45.com`);
  editorial references to **Reason 2.0** (~2002) place the active period 1999–2003+.
- **People:** **Patrik Pencinger** (owner/admin — author of the planning docs);
  contributor/editor **"60nine"** (wrote the producer45 concept and a Reason
  tutorial); plus a roster of writers and promoters.

## 2. Site generations & tech stack (oldest → newest)
| Gen | Evidence | Stack |
|-----|----------|-------|
| **Urban Fetish** (predecessor) | `Urban Fetish/` (1,666 files); V3 doc calls it "prvi" (first) site | early static/Flash |
| **ER45 V2 / V2.1** | `er45.com V.2.1 todo's.doc`, ASP snippets | **Classic ASP / VBScript on IIS** (`wwwroot_er45`), **MS Access `.mdb`** + later **MySQL** |
| **ER45 V3** | `ER45 V3/`, `ER45 V3.doc`, `er45 v3 boje.htm` (colors), design-spec docs | ASP, **CSS** redesign, **sections split by subdomain** |
| **"LITE" version** | `ER45 To Dos.txt` ("pokrenuti LITE verziju") | trimmed front-end |
| **PHP / forum era** | `PHP SERVER/` (8,185 files) incl. `_forum_app_backup`, `.php`/`.pl`/`.cgi`, `baza.dump` | **PHP + Perl/CGI forum**, **MySQL 3.23** (db name `er45`) |

The site was primarily **Classic ASP on IIS** backed by Access then MySQL, with a
**Perl/CGI + PHP forum** bolted on, and Flash (`.swf`) for banners/the Lounge.

## 3. Content inventory
| Area | Where (in `Backup\ER45`) | Notes |
|------|--------------------------|-------|
| **Articles / interviews / bios** | `Članci/` (148), `članci (PATRIK)/` (81) | Original interviews & translated bios: Sven Väth, Adam Beyer, Marco Carola, Mark Farina, Claude Young, David Morales, Drexciya, Silicone Soul, Eddie Richards, Peace Division, Percy X… + topical pieces (Roland TB-303, ecstasy/harm-reduction, "clubbin' USA") |
| **Party calendar (chrono)** | `BAZE/chrono.sql`, `ER45 baze/` | MySQL `chrono` table: party title, date, location, lineup, ticket price, genre |
| **Article DB** | `BAZE/clanci.sql` | MySQL `clanci` table (articles as data) |
| **DJ/artist photo galleries** | `pix.artists/` (295), `198.slike/`, `Slike Iz Zadnjih Kop…/` | Carl Cox, Derrick May, Plastikman, Goldie, LTJ Bukem, Surgeon, Luke Slater, Westbam, Ken Ishii, Green Velvet, Joey Beltram, Prodigy, + local acts |
| **Profiles** | `ER45 profili/`, `profiles/` | DJ/member profile pages |
| **Forum** | `PHP SERVER/_forum_app_backup`, `*.cgi`, `*.threads`, `baza.dump` | Perl/PHP forum + its big SQL dump |
| **News images** | `news.pix/` (148) | homepage news thumbnails |
| **Flyers / banners / logos** | `Flyeri/` (69), `Banneri/` (21), `ER45 logotipi i banneri/`, `48 px ikone/` (129 icons) | event flyers + site graphics; `banneri.txt` lists banners |
| **Contests** | `ER45 - NAGRADNE IGRE.doc`, `nagradne igre kroz bazu/` | prize games run through the DB |
| **ER45 Lounge** | `ER45.lounge/`, `ER45 lounge.doc`, `lounge-banner.swf`, `er45lounge.mpeg` | a chill/lounge sub-section |
| **Audio (own productions/mixes)** | 10 mp3/mpeg, ~141 MB | `mary - futurescope.mp3` (96 MB, full mix), `urban fetish - editor's groove v1`, local producers (aaron.goldboy, blashko, Le Du, ljulja, zvuk.broda) — an in-house netlabel/mix angle |
| **Editorial guidelines** | `Upute za pisanje/` (80) | how-to-write-for-ER45 docs for contributors |
| **Featured artists** | `CISCO FEREIRA`, `Oliver Ho`, `technasia`, `kittin`, `DJ MARY.ER45.com` | per-artist press kits / mini-sites |

## 4. Databases
- **MySQL 3.23**, database name **`er45`** (dumped with MySQL-Front 2.5).
  - `chrono` — the party/event calendar (the backbone of the site).
  - `clanci` — articles.
  - `baza.dump` / `baza.dump.gz` (152 MB / 18 MB) — large dump, most likely the
    **forum** database.
- **MS Access `.mdb`** (46 files, ~26 MB) — the earlier ASP-era data store.

## 5. The "producer45" plan (unbuilt sub-site)
`producer45-koncepcija.doc` (by **60nine**) specs **produc.er45.com**: a portal
for music *producers* — news, reviews, an artists directory (name, nick, DOB,
genre, gear, bio, track list), shareware-tool downloads, sample kits, tips &
tricks, an archive, and **charts** (top-5 tracks voted by visitors with 128 kbps
loop previews). Evidence the brand was meant to expand into subdomains.

## 6. Sensitive files — handle with care (do NOT publish)
- `_LOZINKE.txt` — **passwords**.
- `ER45 hosting.txt`, `popis @ER45 mailova.txt` (mailing list), `HR - promoteri -
  kontakti.txt` (promoter contacts) — **credentials / personal data**.
These were noted but **not** opened/printed during analysis. Keep them out of any
public revival and out of git.

## 7. How this feeds the revival
- The memorial's tagline **"the infrastructure continues in the subdomains"** is
  historically accurate — V3 genuinely split sections across subdomains.
- Rich revival material already exists: the **party chronology** (`chrono.sql`),
  the **article archive** (`clanci.sql` + `Članci/`), and thousands of **party
  photos** — any of these could become a real subdomain (e.g. `archive.er45.com`).
- The **original 2003 site** is preserved under `_backup\22012003_www.er45.com`
  and `_backup\wwwroot_er45` — static parts may be viewable; ASP pages would need
  IIS (or a quick port) to run again.

---
*Generated from a structural scan + reading the planning docs and SQL headers.
Counts are approximate; the archive lives at `C:\Users\patri\OneDrive\Backup\ER45`.*
