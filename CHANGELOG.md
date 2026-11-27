# Changelog

## 0.9.1 — 2026-11-27

- Interfaccia con i colori del logo (grafite, blu, verde, rosso, viola); arancione solo per gli avvisi.
- Logo accanto al nome in alto a sinistra.
- L'anteprima video non è più una finestra flottante: si apre nella scaletta, sotto la voce del brano. Chiudendo la voce con la freccia il video si nasconde, aprendola ricompare.
- Video e audio separabili: l'audio del video si può **escludere** (la Video cue in QLab resta muta) o **scorporare** in un file audio a parte (WAV, in Musica › TimeLab › Audio scorporato). Dopo lo scorporo video e audio si tolgono in modo indipendente; togliendo un video che ha l'audio dentro, TimeLab chiede se tenere l'audio.
- Correzione: se un brano ha sia il video sia un file audio a parte, la Video cue in QLab viene resa muta (prima suonavano tutti e due). Puoi riattivare l'audio del video dalla scaletta.
- Correzione: importando da QLab comandi luci del grandMA3, il banco luci viene riconosciuto come grandMA3 (prima ChamSys).
- Pulizia del codice: stili duplicati unificati, codice non più usato rimosso.

## 0.9.0 — 2026-11-27 · prima versione pubblica (beta)

- Nuovo nome: **TimeLab** (prima "QLab Timeline Mixer"). Il Runner diventa *TimeLab Runner*; quello vecchio viene rimosso da solo al primo avvio. Progetti e impostazioni restano dove sono.
- Libreria luci: ChamSys MagicQ, grandMA2, grandMA3, Avolites Titan, MIDI Show Control generico, MIDI generico (note e CC), con traduzione dei comandi tra un banco e l'altro.
- Nuovi banchi audio: Allen & Heath CQ, Midas PRO, Midas Heritage-D HD96, DiGiCo SD / Quantum, DiGiCo S-Series.
- Elenchi dei banchi ordinati per marca.
- Riquadri del drag and drop centrati sotto il righello.
- **Aggiornamento automatico** dalle release di GitHub, con verifica SHA-256, controllo di versione e firma, e ripristino della versione precedente se qualcosa va storto.

## Prima della 0.9 (uso privato)

Profili Yamaha (MIDI e rete), Behringer/Midas via MIDI e OSC, Allen & Heath; traduzione dei comandi tra banchi; scaletta; importazione da QLab; esportazione robusta con controllo dei percorsi; LTC; supporto video con proxy per ProRes/HAP; aspetto simile a QLab.
