# Pubblicare una nuova versione

1. Aggiorna il numero nel file `VERSION` (es. `0.9.1`). Regola: `0.9.x` per correzioni, `0.10.0` per novità, `1.0.0` quando esce dalla beta.
2. Scrivi le novità in cima a `CHANGELOG.md`.
3. Sul Mac, nella cartella del progetto:
   ```bash
   bash scripts/package.sh
   python3 tests/smoke.py dist/timelab-web.html   # facoltativo, serve Playwright
   ```
   In `dist/` trovi `TimeLab-0.9.1.zip` e `TimeLab-0.9.1.zip.sha256`.
4. Fai commit e push delle modifiche (GitHub Desktop: *Commit* › *Push origin*).
5. Su GitHub: **Releases › Draft a new release**
   - *Tag*: `v0.9.1` (con la **v**, stesso numero di `VERSION`)
   - *Title*: `TimeLab 0.9.1`
   - *Description*: incolla le novità dal CHANGELOG (sono il testo che vede chi aggiorna)
   - allega **entrambi** i file di `dist/`: lo zip e il `.sha256`
   - *Publish release*

Da quel momento chi ha TimeLab installato vede l'avviso al successivo avvio.

**Attenzione**
- Se manca il file `.sha256`, l'aggiornamento automatico non parte (per sicurezza): chi usa l'app vede solo il link alla pagina della release.
- Il repository deve essere **pubblico** e chiamarsi come in `UPDATE_REPO` dentro `src/editor.html` (oggi `bonimattiazano-dotcom/TimeLab`).
- Le *pre-release* non vengono proposte: l'app guarda solo l'ultima release normale.
