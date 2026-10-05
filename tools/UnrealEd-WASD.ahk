; UnrealEd dell'SDK (Deus Ex) - muoversi con WASD (AutoHotkey 1.1)
; L'editor del 2000 si muove solo col mouse: questo script, tenendo premuti i tasti con
; il puntatore sopra una vista, simula i trascinamenti che l'editor capisce.
;
;   Vista 3D ("Viewport"):  W/S avanti/indietro   A/D di lato   E/Q su/giu'
;                           W+A / W+D avanti girando
;   Viste 2D (mappe):       W/A/S/D spostano la vista
;   Shift = piu' veloce.  F8 = attiva/disattiva lo script.
;
; Non interferisce quando scrivi: funziona solo con il puntatore sopra una vista
; dell'editor e se non stai scrivendo in una casella di testo.
; Si chiude da solo quando chiudi UnrealEd.

#NoEnv
#SingleInstance Force
#Persistent
SendMode Input
SetMouseDelay, -1
SetBatchLines, -1
CoordMode, Mouse, Screen

global gMode := ""       ; "" | "L" (tasto sinistro) | "LR" (entrambi i tasti)
global gIs3D := false
global gOn := true
global gStep := 8
global gSeen := false
global gStart := A_TickCount

Menu, Tray, Tip, UnrealEd WASD (F8 per spegnere)
TrayTip, UnrealEd WASD, W/A/S/D sopra le viste per muoverti. F8 attiva/disattiva., 3
SetTimer, Tick, 15
SetTimer, CheckEditor, 2000
return

CheckEditor:
    ; l'editor ci mette ~40 s ad aprirsi: si chiude solo dopo averlo visto e poi perso
    Process, Exist, UnrealEd.exe
    if (ErrorLevel)
        gSeen := true
    else if (gSeen || A_TickCount - gStart > 180000)
        ExitApp
return

; Il puntatore e' sopra una vista dell'editor e non si sta scrivendo in una casella?
InViewport(ByRef title := "") {
    MouseGetPos,,, hwnd
    WinGetClass, cls, ahk_id %hwnd%
    if (cls != "DeusExUnrealWWindowsViewportWindowLite")
        return false
    if !WinActive("ahk_exe UnrealEd.exe")
        return false
    ControlGetFocus, fc, A
    if (fc ~= "i)edit|textbox|combo|richedit")
        return false
    WinGetTitle, title, ahk_id %hwnd%
    return true
}

SetMode(m) {
    global gMode
    if (m = gMode)
        return
    if (gMode != "") {
        SendInput, {LButton up}
        if (gMode = "LR")
            SendInput, {RButton up}
    }
    if (m != "") {
        SendInput, {LButton down}
        if (m = "LR")
            SendInput, {RButton down}
    }
    gMode := m
}

Tick:
    fw := GetKeyState("w", "P"), bk := GetKeyState("s", "P")
    lf := GetKeyState("a", "P"), rt := GetKeyState("d", "P")
    up := GetKeyState("e", "P"), dn := GetKeyState("q", "P")
    if (!gOn || !(fw || bk || lf || rt || up || dn)) {
        SetMode("")
        return
    }
    if (gMode = "") {
        if !InViewport(title)
            return
        gIs3D := (title = "Viewport")
    }
    step := GetKeyState("Shift", "P") ? gStep * 3 : gStep
    dx := 0, dy := 0
    if (!gIs3D) {
        mode := "L"
        dx := (rt - lf) * step, dy := (bk - fw) * step
    } else if (fw || bk) {
        mode := "L"                              ; sinistro: avanti/indietro e gira
        dy := (bk - fw) * step, dx := (rt - lf) * (step // 2)
    } else {
        mode := "LR"                             ; entrambi: di lato e su/giu'
        dx := (rt - lf) * step, dy := (dn - up) * step
    }
    SetMode(mode)
    if (dx || dy)
        MouseMove, %dx%, %dy%, 0, R
return

F8::
    gOn := !gOn
    SetMode("")
    TrayTip, UnrealEd WASD, % (gOn ? "Attivo" : "Spento"), 2
return

; i tasti non arrivano all'editor quando servono per muoversi
#If gOn && (gMode != "" || InViewport())
w::return
a::return
s::return
d::return
q::return
e::return
#If
