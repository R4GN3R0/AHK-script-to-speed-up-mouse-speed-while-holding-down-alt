; =====================================================================================
; AHK v1 COMPATIBLE MOUSE/CURSOR ACCELERATION SCRIPT
; =====================================================================================
#Persistent
#SingleInstance, Force

; --- Configuration ---
global acceleration_factor := 2.5  ; The multiplier for your cursor speed. 2 = 2x speed, 3 = 3x speed, etc.

; --- Global Variable for the Hook ---
; This variable will store the ID of our mouse hook when it's active.
global hHook := 0

return ; End of the auto-execute section. The script will now wait for hotkey presses.


; --- Hotkeys to Turn the Hook On and Off ---

; This hotkey triggers when you PRESS the Left Alt key.
~LAlt::
    ; Only start the hook if it isn't already running.
    if (!hHook) {
        ; Start the low-level mouse hook and store its ID in the hHook variable.
        hHook := DllCall("SetWindowsHookExW", "int", 14, "ptr", RegisterCallback("MouseProc"), "ptr", DllCall("GetModuleHandleW", "ptr", 0, "ptr"), "uint", 0)
    }
return

; This hotkey triggers when you RELEASE the Left Alt key.
~LAlt Up::
    ; Only try to stop the hook if it's currently running.
    if (hHook) {
        DllCall("UnhookWindowsHookEx", "ptr", hHook)
        hHook := 0 ; Reset the variable to 0 to show that the hook is no longer active.
    }
return


; --- The Core Function That Processes Mouse Movement ---
MouseProc(nCode, wParam, lParam) {
    global acceleration_factor
    static last_x := 0, last_y := 0

    ; We only act on mouse movement messages. WM_MOUSEMOVE is message type 0x200.
    if (nCode >= 0 && wParam = 0x200)
    {
        ; Get the cursor's current position from the data provided by the hook.
        current_x := NumGet(lParam + 0, 0, "Int")
        current_y := NumGet(lParam + 4, 0, "Int")

        ; If the script just started, set the "last" position to the current one.
        if (last_x = 0 and last_y = 0) {
            last_x := current_x
            last_y := current_y
        }

        ; Calculate how far the mouse has moved since the last check (the delta).
        delta_x := current_x - last_x
        delta_y := current_y - last_y

        ; Calculate the new, accelerated position by multiplying the delta movement.
        new_x := last_x + (delta_x * acceleration_factor)
        new_y := last_y + (delta_y * acceleration_factor)

        ; Instantly move the cursor to the new accelerated position.
        DllCall("SetCursorPos", "int", new_x, "int", new_y)

        ; IMPORTANT: Update the "last" position to our new calculated position.
        last_x := new_x
        last_y := new_y

        ; Block the original mouse movement event from being processed by Windows.
        ; This prevents a "double movement" or stutter.
        return 1
    }

    ; If it's not a mouse movement event we're interested in, reset the tracking and pass the event on.
    last_x := 0, last_y := 0
    return DllCall("CallNextHookEx", "ptr", 0, "int", nCode, "ptr", wParam, "ptr", lParam)
}