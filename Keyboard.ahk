
	;   Виртуальная 10-ти "клавишная" клавиатура
	;   Автор - serzh82saratov
	;   http://forum.script-coding.com/viewtopic.php?pid=88135#p88135

#UseHook
#SingleInstance Force
#NoTrayIcon
#NoEnv
#HotkeyInterval 0
SetBatchLines -1
ListLines Off
OnExit GuiClose
FixIE(0)

Global Relative := 1.0		; Относительный размер клавиатуры. Например: "1.2" = +20%
, Bank := "bRu"				; Стартовая раскладка  -  sRu | bRu | sEn | bEn | Emb | Num
, TimeOut := 1500			; Таймаут авто ввода символа после последнего выбора
, TrayIcon := 1				; Иконка только в трее, или только на панели задач
, AutoRegistr := 1			; Переключать в нижний регистр, после ввода символа из верхнего
, cBg := "2F4F4F"			; Цвет фона
, cBorder := "767676"		; Цвет окантовки клавиш
, sBorder := 1				; Толщина окантовки клавиш
, cChr := "000000"			; Цвет шрифта
, cSel := "ffffff"			; Цвет шрифта выбранного символа
, cCtrl := "D9952F"			; Цвет шрифта кнопок "Ctrl+..."
, wKey := 130 * Relative
, hKey := wKey//2
, hCap := hKey//3

Menu, Tray, UseErrorLevel
Menu, Tray, Icon, Shell32.dll, 174
If TrayIcon
{
	Menu, Tray, Icon
	Menu, Tray, Click, 1
	Menu, Tray, NoStandard
	Menu, Tray, Add, Min/Max, MinMax
	Menu, Tray, Default, Min/Max
	Menu, Tray, Disable, Min/Max
	Gui, +Owner
}
Menu, Tray, Add, ExitApp, GuiClose
GoSub Init
Gui, Margin, 0, 0
Gui, -DPIScale -Caption +Lastfound +AlwaysOnTop +HWNDhThisGui
Gui, Add, ActiveX, % "voDoc w" wKey*3 " h" hKey*4+hCap, HTMLFile
oDoc.body.innerHTML := html
Loop 10
	(elem := oDoc.getElementById("p" A_Index)).style.top := [0,0,0,hKey,hKey,hKey,hKey*2,hKey*2,hKey*2,hKey*3][A_Index] + hCap . "px"
	, elem.style.left := [0,wKey,wKey*2,0,wKey,wKey*2,0,wKey,wKey*2,wKey][A_Index] . "px"
WinSet, Region, % "0-0 " wKey*3 "-0 " wKey*3 "-" (t := hKey*3+hCap) " 0-" t " 0-0 "
	. wKey "-" t " " wKey*2 "-" t " " wKey*2 "-" t+hKey " " wKey "-" t+hKey " " wKey "-" t
WinSet, Transparent, 225
OnMessage(0x201, "WM_LBUTTONDOWN"), OnMessage(0x200, "WM_MOUSEMOVE")
ComObjError(false), Layout(Bank)
WinGetPos, , Y, , , ahk_class Shell_TrayWnd ahk_exe explorer.exe
Gui, Show, % "NA xCenter y" Y - (hKey * 4) - hCap - 1, Virtual mini keyboard
SetTimer, OnTop, 500
OnMessage(0xC, "WM_SETTEXT")
Return

	; _________________________________________________ HotKey _________________________________________________

#If (!Minimize)    ; Если окно скрипта не свёрнуто. Условие для клавиш клавиатуры.

#If (IsGuiScript || WinActive("ahk_id" hThisGui))    ; Запрет вывода меню.

*+F10::
*AppsKey:: Return

#If IsGuiScript

*WheelDown::
	If (GetKeyState("RButton", "P"))
		(Area = "Caption" ? Send("{Left}") : Send("^+{Left}"))
	Else If Area is number
		K_ChangeBank()
	Return

*WheelUp::
	If (GetKeyState("RButton", "P"))
		(Area = "Caption" ? Send("{Right}") : Send("^+{Right}"))
	Else If Area is number
		NextChr(Area)
	Return

*MButton:: K_ChangeRegistr()

*RButton::
	If Area is number
		K_Input()
	Else If Area = Caption
		InputCancel(), oDoc.getElementById("viewinput").InnerText := "", ViewInput := ""
	Return

#If (IsGuiScript && Area != "Caption")

*LButton::
	If (Area = "Emb" || GetKeyState("RButton", "P"))
		EmbBank()
	Else If Area is number
		NextChr(Area)
	Else If Area = Del
		Chr.P ? InputCancel() : ClickKey()
	Else If Area = Ret
		ClickKey()
	Else If Area = Turn
		Gosub K_MinMax
	Else If Area = Close
		ExitApp
	Return

#If

	; _________________________________________________ Logic _________________________________________________

Layout(b)  {
	Loop 10
		(elem := oDoc.getElementById("p" A_Index)).innerHTML := Ins[b "_" A_Index]
		, elem.style.fontSize := Param[t := Type[b "_" A_Index]][1] . "px"
		, elem.style.paddingTop := Param[t][2] . "em", elem.style.color := Param[t][3]
	PrBank := Bank, Bank := b, Chr.P := ""
	Caps := (t := SubStr(Bank, 1, 1)) = "b" ? 1 : t = "s" ? 0 : Caps
}

ChangeBank()  {
	Layout(Caps ? {"bRu":"bEn","bEn":"Num","Emb":"bRu","Num":"bRu"}[Bank]
		: {"sRu":"sEn","sEn":"Num","Emb":"sRu","Num":"sRu"}[Bank])
}

ChangeRegistr()  {
	Layout({"sRu":"bRu","bRu":"sRu","sEn":"bEn","bEn":"sEn","Emb":"Num","Num":"Emb"}[Bank])
}

NextChr(A)  {
	Chr.E.style.color := Chr.Color
	Chr.P && Chr.P != A ? Input() : 0
	Chr.C := (Chr.P = A ? (++Chr.C > Bank_%Bank%[A].maxindex() ? 1 : Chr.C) : 1)
	Chr.P := A, Chr.Color := Param[t := Type[Bank "_" Chr.P]][3]
	(Chr.E := oDoc.getElementById("p" Chr.P "c" Chr.C)).style.color := cSel
	SetTimer, Input, % t = "ctrl" || t = "num" ? -40 : "-" TimeOut
	Chr.S := Bank_%Bank%[Chr.P][Chr.C]
}

Input(man=0)  {
	SetTimer, Input, Off
	Chr.E.style.color := Chr.Color
	Send((Ex := Send_Exception[Chr.S]) = "" ? "{Raw}" Chr.S : Ex)
	add := Ex = "" ? Chr.S : !InStr(Ex, "{Raw}") ? "" : Chr.E.InnerText
	oDoc.getElementById("viewinput").InnerText := (ViewInput := SubStr(ViewInput add, -96)) . (ViewInput != "" ? "|" : "")
	(!man && AutoRegistr && (Bank = "bEn" || Bank = "bRu") && Chr.P) ? Layout({"bRu":"sRu","bEn":"sEn"}[Bank]) : 0, Chr.P := ""
}

Input:
	Input()
	Return

InputCancel()  {
	SetTimer, Input, Off
	Chr.E.style.color := Chr.Color, Chr.P := ""
}

ClickKey()  {
	Static Key
	Key := Area
	(Key = "Del" ? Send("{BS}") : Input())
	SetTimer, ClickKey, -650
	oDoc.getElementById(Key).style.color := cSel
	KeyWait LButton
	SetTimer, ClickKey, Off
	oDoc.getElementById(Key).style.color := cChr
	Return

	ClickKey:
		(Key = "Del" ? Send("{BS}") : Input())
		SetTimer, ClickKey, -30
		Return
}

EmbBank()  {
	InputCancel(), Layout(Bank = "Emb" ? PrBank : "Emb")
}

K_ChangeBank()  {
	Chr.P ? InputCancel() : ChangeBank()
}

K_ChangeRegistr()  {
	Chr.P ? Input(1) : 0
	Layout({"sRu":"bRu","bRu":"sRu","sEn":"bEn","bEn":"sEn","Emb":"Num","Num":"Emb"}[Bank])
}

K_Input()  {
	Chr.P ? Input() : 0
}

Send(k)  {
	SendInput %k%
}

	;  Для управления сообщениями: SendMessage, 0xC, 3, "NextChr", , Virtual mini keyboard ahk_class AutoHotkeyGUI
WM_SETTEXT(wp, lp) {
	Return True, IsFunc(F := StrGet(lp)) ? %F%(wp) : 0
}

	; _________________________________________________ Window _________________________________________________

WM_MOUSEMOVE(wp, lp) {
	Area := oDoc.elementFromPoint(lp & 0xFFFF, lp >> 16).name
	PrArea = Area ? 0 : (PrArea := Area)
	SetTimer, IsThisGui, -30
}

IsThisGui:
	MouseGetPos, , , WinID
	If (hThisGui = WinID && (IsGuiScript := 1))
		SetTimer, IsThisGui, -50
	Else
		Area := PrArea := Chr.P := "", IsGuiScript := 0
	Return

OnTop:
	If (!Minimize)
		Gui, Show, NA
	Return

GuiSize:
	If A_Eventinfo = 2
		Return
	Minimize := A_Eventinfo
	If (IsStart && !Minimize)
		SendInput !{Esc}
	IsStart := 1
	Return

MinMax:
K_MinMax:
	If TrayIcon
	{
		Gui, Show, % Minimize ? "NA" : "Hide"
		SetTimer, OnTop, % (Minimize := !Minimize) ? "Off" : "On"
		Minimize ? InputCancel() : Send("!{Esc}")
		Minimize && A_ThisLabel = "MinMax" ? Send("!{Esc}") : 0
	}
	Else
		Gui, % Minimize = 1 ? "Show" : "Minimize" InputCancel()
	Return

WM_LBUTTONDOWN()   {      ; Перетаскивание окна
	If Area = Caption
	{
		PostMessage, 0xA1, 2
		KeyWait LButton
		IfWinActive
			SendInput !{Esc}
	}
}

FixIE(Fix)  {
	Static Key := "Software\Microsoft\Internet Explorer\MAIN\FeatureControl\FEATURE_BROWSER_EMULATION"
	If A_IsCompiled
		ExeName := A_ScriptName
	Else
		SplitPath, A_AhkPath, ExeName
	If Fix
		RegWrite, REG_DWORD, HKCU, %Key%, %ExeName%, 0
	Else
		RegDelete, HKCU, %Key%, %ExeName%
}

GuiClose:
GuiEscape:
	oDoc := ""
	ExitApp

	; _________________________________________________ Init _________________________________________________

Init:
	Global hThisGui, oDoc, Area, PrArea, PrBank, Caps, ViewInput, Chr := {}, Ins := {}, Type := {}
	, Bank_Num := [[1],[2],[3],[4],[5],[6],[7],[8],[9],[0]]
	, Bank_Chr_1 := ["&rarr;",".","`,","!","?","""","`%"]
	, Bank_Chr_10 := ["&crarr;","+","-","*",":","(",")","|"]
	, Bank_bRu := [Bank_Chr_1,["А","Б","В","Г"],["Д","Е","Ё","Ж","З"],["И","Й","К","Л"],["М","Н","О","П"]
		,["Р","С","Т","У"],["Ф","Х","Ц","Ч"],["Ш","Щ","Ь","Ы"],["Ъ","Э","Ю","Я"],Bank_Chr_10]
	, Bank_sRu := [Bank_Chr_1,["а","б","в","г"],["д","е","ё","ж","з"],["и","й","к","л"],["м","н","о","п"]
		,["р","с","т","у"],["ф","х","ц","ч"],["ш","щ","ь","ы"],["ъ","э","ю","я"],Bank_Chr_10]
	, Bank_bEn := [Bank_Chr_1,["A","B","C"],["D","E","F"],["G","H","I"],["J","K","L"]
		,["M","N","O"],["P","Q","R","S"],["T","U","V"],["W","X","Y","Z"],Bank_Chr_10]
	, Bank_sEn := [Bank_Chr_1,["a","b","c"],["d","e","f"],["g","h","i"],["j","k","l"]
		,["m","n","o"],["p","q","r","s"],["t","u","v"],["w","x","y","z"],Bank_Chr_10]
	, Bank_Emb := [Bank_Chr_1,["{","}","<",">","`[","`]"],["+","-","*",":","=","_"]
		,["&crarr;","&","'","|","``","~"],["(",")","/","\","^","#","$"]
		,["&harr;","`;","@","№"],["Ctrl+C"],["Ctrl+V"],["Ctrl+A"],["Ctrl+Z"]]
	, Send_Exception := {"Ctrl+C":"^{vk43}","Ctrl+V":"^{vk56}","Ctrl+A":"^{vk41}","Ctrl+Z":"^{vk5A}"
		,"&rarr;":"{Raw}" A_Space,"&crarr;":"{Raw}`n","&harr;":"{Raw}" A_Tab}
	, Param := {big:[hKey/1.91,0.35,cChr], small:[hKey/1.71,0.22,cChr], num:[hKey/1.35,0.08,cChr]
		, emb:[hKey/2.0,0.4,cChr], ctrl:[hKey/1.91,0.35,cCtrl]}

	Loop 10
		p_spans .= "<span name='" A_Index "' class='p' id='p" A_Index "'></span>"
	html := "
	(
	<body onselectstart='return false' oncontextmenu='return false'>" p_spans "
	<span name='Del' class='k' id='Del'>DEL</span>
	<span name='Emb' class='k' id='Emb'>EMB</span>
	<span name='Ret' class='k' id='Ret'>RET</span>
	<span name='Caption' id='Caption'><span name='Caption' id='viewinput'></span></span>
	<span name='Turn' class='k' id='Turn'>&ndash;</span>
	<span name='Close' class='k' id='Close'>&times;</span>
	</body>

	<style>
	body {
		background-color: '#" cBg "';
		overflow: 'hidden';
		white-space: 'nowrap';
		font-family: 'Arial';
		text-align: 'center';
	}
	.p {
		cursor: 'pointer';
		overflow: 'hidden';
		border: " sBorder "px solid #" cBorder "`;
		position: 'absolute';
		width: " wKey "px;
		height: " hKey "px;
	}
	.k {
		cursor: 'default';
		overflow: 'hidden';
		border: " sBorder "px solid #" cBg "`;
		font-size: '" hKey/6 "px';
		font-weight: '900';
		padding-top: '0.3em';
		position: 'absolute';
		width: " hCap//0.6 "px;
		height: " hCap "px;
		top: 0px;
	}
	#Del {background-color: '#D9952F'; left: 0px;}
	#Ret {background-color: '#FFFF00'; left: " hCap//0.6 "px;}
	#Emb {background-color: '#44AD24'; left: " (hCap//0.6)*2 "px;}
	#Turn {background-color: '#365DC0'; left: " (wKey*3) - (hCap//0.6)*2 "px;}
	#Close {background-color: '#EC4D48'; left: " (wKey*3) - (hCap//0.6) "px;}
	#Turn, #Close {font-size: " hKey/4 "px; padding-top: 0.0em;}
	#Caption {
		cursor: 'move';
		position: 'absolute';
		top: 0px;
		left: " (hCap//0.6)*3 "px;
		width: " (wKey*3) - (hCap//0.6)*5 "px;
		height: " hCap "px;
		overflow: hidden;
	}
	#viewinput {
		position: 'absolute';
		right: '1px';
		font-size: '" hKey/4.5 "px';
		color: '#fff';
		padding-top: '0.2em';
	}
	</style>
	)"

	For a, b in ["bRu","sRu","bEn","sEn","Emb","Num"]
		For c, d in Bank_%b%
		{
			Loop % d.maxindex()
				e .= "<span name='" c "' id='p" c "c" A_Index "'>" d[A_Index] "</span>"
			Ins[b "_" c] := e, e := ""
			Type[b "_" c] := (t := SubStr(b, 1, 1)) = "b" ? (InStr(c, "1") ? "emb" : "big")
				: t = "s" ? (InStr(c, "1") ? "emb" : "small")
				: t = "E" ? (c > 6 ? "ctrl" : "emb") : "num"
		}
	Return
