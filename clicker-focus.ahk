; AutoHotkey v2. The clicker's 4th button alternates Esc / Shift+F5;
; pressing it twice quickly (Esc then Shift+F5, or the other way round)
; brings the presentation window to the front. A single Esc or Shift+F5
; goes through as normal, so this can stay running all the time.
#Requires AutoHotkey v2.0
#SingleInstance Force
SetTitleMatchMode 2   ; match anywhere in the window title

PresentTitle := "IS 201 Cheat Sheet: Present"
DoubleMs := 600       ; max gap between the two presses

lastEsc := 0
lastShiftF5 := 0

#HotIf WinExist(PresentTitle)
$Esc:: {
    global lastEsc, lastShiftF5
    if (A_TickCount - lastShiftF5 < DoubleMs) {
        lastShiftF5 := 0
        WinActivate PresentTitle
    } else {
        lastEsc := A_TickCount
        Send "{Esc}"
    }
}
$+F5:: {
    global lastEsc, lastShiftF5
    if (A_TickCount - lastEsc < DoubleMs) {
        lastEsc := 0
        WinActivate PresentTitle
    } else {
        lastShiftF5 := A_TickCount
        Send "+{F5}"
    }
}
#HotIf
