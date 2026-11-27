-- TimeLab Runner: riceve le richieste dell'editor (link qlabtm://...)
--   run?id=..&s=...      esegue lo script che crea/aggiorna le cue in QLab e restituisce il riepilogo
--   proxy?id=..&p=...    crea (in background) una copia leggera H.264 di un video per l'anteprima nell'editor
--   check?id=..&p=...    controlla i file audio (righe: percorso TAB nome TAB dimensione) e ritrova quelli spostati
--   pick?id=...[&m=1]    fa scegliere uno o più file audio e restituisce i percorsi (uno per riga)
--   locate?id=..&n=..    ritrova un file audio per nome (Spotlight) e restituisce il percorso
--   update?id=..&u=..&s=..&v=..  scarica la release da GitHub, la verifica (SHA-256, versione, firma) e sostituisce l'app
on open location theURL
	set qpos to offset of "?" in theURL
	if qpos = 0 then return
	set act to text 10 thru (qpos - 1) of theURL
	set q to text (qpos + 1) thru -1 of theURL
	set reqID to my param(q, "id", false)
	if act is "run" then
		set res to ""
		try
			set src to my param(q, "s", true)
			if reqID is not "" then
				-- l'editor aspetta il riepilogo: lo script non mostra la finestra finale ma lo restituisce
				set AppleScript's text item delimiters to "property viaRunner : false"
				set parts to text items of src
				set AppleScript's text item delimiters to "property viaRunner : true"
				set src to parts as text
				set AppleScript's text item delimiters to ""
			end if
			set res to run script src
			try
				set res to res as text
			on error
				set res to ""
			end try
			if res is "" then set res to "OK" & linefeed & "0|0|0|0"
		on error errMsg number errNum
			set AppleScript's text item delimiters to ""
			set res to "ERR|" & errNum & "|" & errMsg
			if reqID is "" and errNum is not -128 then
				tell me to activate
				display dialog "TimeLab Runner — errore " & errNum & ":" & return & errMsg buttons {"OK"} default button 1 with icon caution
			end if
		end try
		my reply(reqID, res)
		return
	end if
	set p to ""
	if act is "pick" then
		try
			tell me to activate
			if my param(q, "m", true) is "1" then
				set fl to choose file with prompt "Scegli uno o più file audio o video (nell'ordine della scaletta)" of type {"public.audio", "public.movie"} with multiple selections allowed
				set out to {}
				repeat with f in fl
					set end of out to POSIX path of f
				end repeat
				set AppleScript's text item delimiters to linefeed
				set p to out as text
				set AppleScript's text item delimiters to ""
			else
				set f to choose file with prompt "Scegli il file audio o video per TimeLab" of type {"public.audio", "public.movie"}
				set p to POSIX path of f
			end if
		end try
	else if act is "check" then
		try
			set p to my checkFiles(my param(q, "p", true))
		end try
	else if act is "proxy" then
		my makeProxy(my param(q, "p", true), reqID)
		return
	else if act is "update" then
		try
			set p to my installUpdate(my param(q, "u", true), my param(q, "s", true), my param(q, "v", true))
		on error errMsg
			set p to "ERR|" & errMsg
		end try
	else if act is "locate" then
		try
			set p to my locate(my param(q, "n", true), my param(q, "z", true))
		end try
	end if
	my reply(reqID, p)
end open location

on makeProxy(src, reqID)
	-- converte in background: la risposta (percorso della copia, o ERR|...) la scrive lo script quando ha finito
	set resDir to (POSIX path of (path to home folder)) & ".qlab-timeline-mixer/"
	set resPath to resDir & "res-" & reqID & ".txt"
	set sh to "src=\"$1\"; res=\"$2\"; dir=\"$HOME/.qlab-timeline-mixer/proxy\"; mkdir -p \"$dir\"
done_() { printf '%s' \"$1\" > \"$res.tmp\" && mv -f \"$res.tmp\" \"$res\"; }
[ -f \"$src\" ] || { done_ 'ERR|il file video non esiste più'; exit 0; }
key=$(stat -f '%z-%m' \"$src\"); h=$(printf '%s' \"$src$key\" | md5 -q); out=\"$dir/$h.mp4\"
if [ -s \"$out\" ]; then done_ \"$out\"; exit 0; fi
tmp=\"$dir/$h.part.mp4\"; rm -f \"$tmp\"
if /usr/bin/avconvert -s \"$src\" -o \"$tmp\" -p Preset960x540 --replace >/dev/null 2>&1 && [ -s \"$tmp\" ]; then mv -f \"$tmp\" \"$out\"; done_ \"$out\"; exit 0; fi
rm -f \"$tmp\"
FF=$(command -v ffmpeg 2>/dev/null); [ -z \"$FF\" ] && for c in /opt/homebrew/bin/ffmpeg /usr/local/bin/ffmpeg; do [ -x \"$c\" ] && FF=$c && break; done
if [ -n \"$FF\" ] && \"$FF\" -v error -y -i \"$src\" -vf scale=-2:540 -c:v libx264 -preset veryfast -crf 28 -pix_fmt yuv420p -c:a aac -b:a 128k -movflags +faststart \"$tmp\" && [ -s \"$tmp\" ]; then mv -f \"$tmp\" \"$out\"; done_ \"$out\"; exit 0; fi
rm -f \"$tmp\"
if [ -n \"$FF\" ]; then done_ 'ERR|né macOS né ffmpeg riescono a leggere questo formato'; else done_ 'ERR|macOS non legge questo formato (per esempio HAP): installa ffmpeg (brew install ffmpeg) per l anteprima'; fi"
	do shell script "mkdir -p " & quoted form of resDir & "; /bin/sh -c " & quoted form of sh & " qtm " & quoted form of src & " " & quoted form of resPath & " > /dev/null 2>&1 &"
end makeProxy

on installUpdate(zipURL, sumURL, ver)
	-- tutto o niente: se un controllo fallisce l'app installata resta com'è
	set sh to "set -u; url=\"$1\"; sumurl=\"$2\"; ver=\"$3\"; dir=\"$HOME/.qlab-timeline-mixer\"
fail() { echo \"ERR|$1\"; exit 0; }
case \"$url\" in https://github.com/*/releases/download/*) ;; *) fail 'indirizzo di download non valido';; esac
case \"$sumurl\" in https://github.com/*/releases/download/*) ;; *) fail 'manca il file di controllo .sha256 nella release';; esac
echo \"$ver\" | grep -Eq '^[0-9]+\\.[0-9]+\\.[0-9]+$' || fail 'numero di versione non valido'
app=$(cat \"$dir/app.path\" 2>/dev/null); [ -n \"$app\" ] && [ -d \"$app\" ] || fail 'non trovo TimeLab.app: riaprila una volta dal Finder e riprova'
parent=$(dirname \"$app\"); [ -w \"$parent\" ] || fail \"non ho il permesso di scrivere in $parent\"
tmp=$(mktemp -d) || fail 'cartella temporanea non disponibile'; trap 'rm -rf \"$tmp\"' EXIT
curl -fsSL --max-time 180 -o \"$tmp/u.zip\" \"$url\" || fail 'download non riuscito'
want=$(curl -fsSL --max-time 30 \"$sumurl\" | awk '{print tolower($1)}') ; [ -n \"$want\" ] || fail 'non riesco a leggere il file .sha256'
got=$(shasum -a 256 \"$tmp/u.zip\" | awk '{print tolower($1)}'); [ \"$want\" = \"$got\" ] || fail 'il file scaricato non corrisponde alla firma SHA-256'
mkdir \"$tmp/x\" && ditto -x -k \"$tmp/u.zip\" \"$tmp/x\" || fail 'archivio non valido'
new=\"$tmp/x/TimeLab.app\"; [ -d \"$new\" ] || fail 'nell archivio non c e TimeLab.app'
PB=/usr/libexec/PlistBuddy
[ \"$($PB -c 'Print :CFBundleIdentifier' \"$new/Contents/Info.plist\" 2>/dev/null)\" = 'io.github.bonimattiazano-dotcom.timelab' ] || fail 'l app scaricata non è TimeLab'
[ \"$($PB -c 'Print :CFBundleShortVersionString' \"$new/Contents/Info.plist\" 2>/dev/null)\" = \"$ver\" ] || fail 'la versione dell app scaricata non corrisponde'
cs=$(codesign --verify --deep \"$new\" 2>&1) || echo \"$cs\" | grep -q 'not signed at all' || fail 'firma dell app non valida'
xattr -dr com.apple.quarantine \"$new\" 2>/dev/null
bak=\"$dir/backup\"; rm -rf \"$bak\"; mkdir -p \"$bak\"
mv \"$app\" \"$bak/\" || fail 'non riesco a spostare la versione installata'
if ! ditto \"$new\" \"$app\"; then rm -rf \"$app\"; mv \"$bak/$(basename \"$app\")\" \"$app\"; fail 'copia non riuscita: ripristinata la versione precedente'; fi
( sleep 2; open \"$app\" ) >/dev/null 2>&1 &
echo OK"
	return do shell script "/bin/bash -c " & quoted form of sh & " qtm " & quoted form of zipURL & " " & quoted form of sumURL & " " & quoted form of ver
end installUpdate

on reply(reqID, p)
	if reqID is "" then return
	set resDir to (POSIX path of (path to home folder)) & ".qlab-timeline-mixer/"
	do shell script "mkdir -p " & quoted form of resDir & "; find " & quoted form of resDir & " -name 'res-*.txt' -mmin +10 -delete 2>/dev/null; printf '%s' " & quoted form of p & " > " & quoted form of (resDir & "res-" & reqID & ".txt")
end reply

on param(q, k, isB64)
	set AppleScript's text item delimiters to "&"
	set parts to text items of q
	set AppleScript's text item delimiters to ""
	repeat with pp in parts
		set pp to contents of pp
		if pp starts with (k & "=") then
			if (length of pp) ≤ ((length of k) + 1) then return ""
			set v to text ((length of k) + 2) thru -1 of pp
			if isB64 then set v to do shell script "printf '%s' " & quoted form of v & " | tr '_-' '/+' | base64 -D"
			return v
		end if
	end repeat
	return ""
end param

on checkFiles(lst)
	-- per ogni riga "percorso TAB nome TAB dimensione": ok TAB percorso / found TAB nuovo percorso / missing
	set out to {}
	set AppleScript's text item delimiters to tab
	set rows to paragraphs of lst
	repeat with r in rows
		set f to text items of (contents of r)
		set pth to ""
		set nm to ""
		set sz to ""
		try
			set pth to item 1 of f
			set nm to item 2 of f
			set sz to item 3 of f
		end try
		set ok to false
		if pth is not "" then
			try
				do shell script "test -f " & quoted form of pth
				set ok to true
			end try
		end if
		if ok then
			set end of out to "ok" & tab & pth
		else
			set AppleScript's text item delimiters to ""
			set np to ""
			try
				set np to my locate(nm, sz)
			end try
			set AppleScript's text item delimiters to tab
			if np is not "" then
				set end of out to "found" & tab & np
			else
				set end of out to "missing" & tab
			end if
		end if
	end repeat
	set AppleScript's text item delimiters to linefeed
	set res to out as text
	set AppleScript's text item delimiters to ""
	return res
end checkFiles

on locate(n, z)
	if n is "" then return ""
	set found to do shell script "mdfind -name " & quoted form of n
	set AppleScript's text item delimiters to "/"
	set firstHit to ""
	repeat with pr in paragraphs of found
		set p to contents of pr
		if p is not "" and (last text item of p) is n then
			if z is "" then
				set AppleScript's text item delimiters to ""
				return p
			end if
			set sz to do shell script "stat -f%z " & quoted form of p
			if sz is z then
				set AppleScript's text item delimiters to ""
				return p
			end if
			if firstHit is "" then set firstHit to p
		end if
	end repeat
	set AppleScript's text item delimiters to ""
	return firstHit
end locate

on run
	display dialog "TimeLab Runner è installato." & return & "Si usa dall'app TimeLab." buttons {"OK"} default button 1
end run
