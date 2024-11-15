#Requires AutoHotkey v2.0
#SingleInstance Force
; Controller Test Script
; https://www.autohotkey.com/docs/v1/scripts/index.htm#ControllerTest

ControllerNumber := 0
; LogFile := "AutoHotkeyLog.log"
DetectExe := "C:\Users\nueca\Documents\scripting\button-box\detect-button\dist\detect\detect.exe"
GSPWindowTitle := "GSPro"
GameOptions := ["Putting", "Drop", "Mulligan", "Map", "Reset Aim", "Flyover"]
Debug := 0

for n, param in A_Args  ; For each parameter:
{
    if (param == "--debug") {
        Debug := 1
    }
}

; Use absolute mouse positions
CoordMode("Mouse", "Screen")
SetMouseDelay(1000)

; Setup GUI
G := Gui("+Resize +MinSize640x480", "Button Box Controller")

G.Add("Text", "w300", "Debug GSPro button box")
G.OnEvent("Close", Gui_Close)

GuiButtons := []
GuiIndicators := []
GuiButtonDropDowns := []

;; create 6 buttons
loop 6 {
    label := A_Index <= GameOptions.Length ? GameOptions[A_Index] : "Unknown"
    ButtonGroupBox := G.AddGroupBox("w400 h50 x10 yp+40", label)
    TestBtn := G.Add("Button", "w100 xp+5 yp+20", "Test Button " A_Index)
    TestBtn.Name := A_Index
    GuiButtons.Push(TestBtn)
    Indicator := G.Add("Progress", "w100 h20 xp+110 yp+1 c32a852 Background1f2621 vIndicator" A_index, 0)
    GuiIndicators.Push(Indicator)
    TestBtn.OnEvent("Click", TestBtn_Click)
    ; GuiButtonDropDowns.Push(G.Add("DropDownList", "vButtonCommand" A_Index " xp+110 yp+1", GameOptions))
}

;; Setup debug text area
E := G.Add("Edit", "w640 h400 yp+40 x10 +ReadOnly")
E.Value := "Debugging enabled"
; E.Visible := Debug == 1

G.Show()

logger("Starting Button Box Controller v1")

OSDGui := Gui("+AlwaysOnTop +Disabled -Caption +ToolWindow", "OSDScreen")
OSDGui.BackColor := "222222"
WinSetTransColor("222222 150", OSDGui)
OSDGui.SetFont("s32 q2", "Arial Bold")
textShadow := OSDGui.Add("Text", "w400 Center c000000", "")
text := OSDGui.Add("Text", "w400 xp-4 yp-4 Center BackGroundTrans cFFFFFF", "")

ShowOSDWindow(displayText) {
    wp := GetGSProWindowPosition()
    if wp.Length == 0 {
        return
    }
    xpos := wp[1] + (wp[3] / 2) - 250
    ypos := wp[2] + 100
    OSDGui.Show("x" xpos " y" ypos " w500 h200 NoActivate")
    textShadow.Text := displayText
    text.Text := displayText
    ; Sleep(2000)
    ; OSDGui.Hide()
    SetTimer(HideOSDWindow, -4000)
}

HideOSDWindow() {
    OSDGui.Hide()
}

TestBtn_Click(GuiCtrlObj, Info) {
    buttonIndex := Integer(GuiCtrlObj.Name)
    logger("Clicked button ", buttonIndex)
    ; ButtonPressed(buttonIndex)
}

logger(params*) {
    ts := FormatTime(, "yyyy-MM-dd HH:mm:ss.") substr(A_TickCount, -3)
    for , param in params
        message .= param . " "
    ; FileAppend ts " - " message "`n", LogFile
    E.Value .= ts " - " message "`n"
    ; scroll to bottom
    ControlSend("^{END}", E)
}

ActiveGSPro() {
    if WinExist(GSPWindowTitle) {
        if WinActive(GSPWindowTitle) == 0 {
            logger("Activating " GSPWindowTitle)
            WinActivate(GSPWindowTitle)
        } else {
            logger(GSPWindowTitle " already active")
        }
    } else {
        logger(GSPWindowTitle " window not found! Is it running?")
    }
}

GetGSProWindowPosition() {
    if WinExist(GSPWindowTitle) {
        WinGetPos(&X, &Y, &W, &H, GSPWindowTitle)
        return [X, Y, W, H]
    } else {
        logger("Error: GSPro window not found! Is it running?")
    }
    return []
}

RunWaitOne(command) {
    shell := ComObject("WScript.Shell")
    ; Execute a single command via cmd.exe
    exec := shell.Exec(A_ComSpec " /C " command)
    ; Read and return the command's output
    return exec.StdOut.ReadAll()
}

RunWaitSilent(command) {
    ; Source: https://www.autohotkey.com/boards/viewtopic.php?t=13257#p68030
    ; WshShell object: http://msdn.microsoft.com/en-us/library/aew9yb99
    logger("Running command: " command)
    shell := ComObject("WScript.Shell")
    launch := A_ComSpec " /C " command " > stdout.txt"
    exec := shell.Run(launch, 0, true)
    ; Read and return the command's output
    output := FileRead("stdout.txt")
    FileDelete("stdout.txt")
    return output
}

ClickDropOrRehitButton() {
    wp := GetGSProWindowPosition()
    ; buttonPositionRaw := RunWaitOne(DetectExe " --xpos " wp[1] " --ypos " wp[2] " --width " wp[3] " --height " wp[4])
    buttonPositionRaw := RunWaitSilent(DetectExe " --xpos " wp[1] " --ypos " wp[2] " --width " wp[3] " --height " wp[4]
    )
    buttonPositionTrimmed := Trim(StrReplace(buttonPositionRaw, "`r`n"))
    buttonPosition := StrSplit(buttonPositionTrimmed, " ")
    if buttonPosition.Length == 2 {
        logger("position: " buttonPosition[1] ", " buttonPosition[2])
        ActiveGSPro()
        MouseClick("left", buttonPosition[1], buttonPosition[2])
        ; SetMouseDelay(100)
        ; move the mouse back out of view
        ; MouseMove(buttonPosition[1], buttonPosition[2])
        ; Sleep(500)
        ; MouseMove(200, 200)
        SetTimer(ClearMouse, -100)
    }

}

ClearMouse() {
    MouseMove(200, 200)
}

KeyboardShortcut(key) {
    ActiveGSPro()
    Send(key)
    logger("Sent key " key)
}

ButtonPressed(ButtonNumber) {
    logger("Button press")
    switch ButtonNumber {
        ; putting
        case 1:
            KeyboardShortcut("{u}")
            ; drop
        case 2:
            ShowOSDWindow("Attempting Drop...")
            ClickDropOrRehitButton()
            ; mulligan
        case 3:
            KeyboardShortcut("^{m}")
            ; map expand
        case 4:
            KeyboardShortcut("{s}")
            ; reset aim
        case 5:
            KeyboardShortcut("{a}")
            ; flyover
        case 6:
            KeyboardShortcut("{o}")
    }
}

HandleArrowKey(value, &prevValue, &prevPressed, onLowDown, onLowUp, onHighDown, onHighUp) {
    direction := prevValue - value
    if value > 50 {
        prevPressed := 1
        onHighDown()
    } else if value < 50 {
        prevPressed := 1
        onLowDown()
    } else if prevPressed == 1 {
        prevPressed := 0
        if direction > 0 {
            onHighUp()
        } else {
            onLowUp()
        }
    }

    prevValue := value
}

onLeftPressed() {
    logger("onLeftPressed")
    KeyboardShortcut("{Left down}")
}
onLeftReleased() {
    logger("onLeftReleased")
    KeyboardShortcut("{Left up}")
}
onRightPressed() {
    logger("onRightPressed")
    KeyboardShortcut("{Right down}")
}
onRightReleased() {
    logger("onRightReleased")
    KeyboardShortcut("{Right up}")
}

onUpPressed() {
    logger("onUpPressed")
    KeyboardShortcut("{Up down}")
}
onUpReleased() {
    logger("onUpReleased")
    KeyboardShortcut("{Up up}")
}
onDownPressed() {
    logger("onDownPressed")
    KeyboardShortcut("{Down down}")
}
onDownReleased() {
    logger("onDownReleased")
    KeyboardShortcut("{Down up}")
}

; Auto-detect the controller number if called for:
if ControllerNumber <= 0 {
    loop 16  ; Query each controller number to find out which ones exist.
    {
        if GetKeyState(A_Index "JoyName") {
            ControllerNumber := A_Index
            break
        }
    }
    if ControllerNumber <= 0 {
        logger("The system does not appear to have any controllers.")
        return
    }
}

cont_buttons := GetKeyState(ControllerNumber "JoyButtons")
cont_name := GetKeyState(ControllerNumber "JoyName")
cont_info := GetKeyState(ControllerNumber "JoyInfo")

buttonsPressed := []
buttonsPressed.Default := 0
buttonsPressed.Length := cont_buttons

buttonXPressed := 0
buttonYPressed := 0
prevX := 0
prevY := 0

logger("Found joystick " cont_name " " cont_info)

Gui_Close(GuiObj) {
    ExitApp
    return 0
}

loop {
    loop cont_buttons {
        if GetKeyState(ControllerNumber "Joy" A_Index) {
            if buttonsPressed[A_Index] < 1 {
                buttonsPressed[A_Index] := 1
                logger("button-press " A_Index)
                ButtonPressed(A_Index)
                if A_Index <= GuiIndicators.Length {
                    GuiIndicators[A_Index].Value := 100
                }
            }
        } else {
            if buttonsPressed[A_Index] > 0 {
                buttonsPressed[A_Index] := 0
                logger("button-release " A_Index)
                if A_Index <= GuiIndicators.Length {
                    GuiIndicators[A_Index].Value := 0
                }
            }
        }
    }

    ; arrow keys
    x_value := Round(GetKeyState(ControllerNumber "JoyX"))
    y_value := Round(GetKeyState(ControllerNumber "JoyY"))

    HandleArrowKey(x_value, &prevX, &buttonXPressed, onLeftPressed, onLeftReleased, onRightPressed, onRightReleased)
    HandleArrowKey(y_value, &prevY, &buttonYPressed, onUpPressed, onUpReleased, onDownPressed, onDownReleased)

    Sleep 100
}
return