
	;   Виртуальная 10-ти "клавишная" клавиатура + менеджер буфера обмена
	;   Автор - serzh82saratov
	;   http://forum.script-coding.com/viewtopic.php?pid=88583#p88583

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
Gui, Color, %cBg%
Gui, -DPIScale -Caption +Lastfound +AlwaysOnTop +HWNDhThisGui
Gui, Add, ActiveX, % "voDoc w" hKey*9+2 " h" hKey*4+hCap, HTMLFile
oDoc.body.innerHTML := html
Loop 10
	(elem := oDoc.getElementById("p" A_Index)).style.top := [0,0,0,hKey,hKey,hKey,hKey*2,hKey*2,hKey*2,hKey*3][A_Index] + hCap . "px"
	, elem.style.left := [0,wKey,wKey*2,0,wKey,wKey*2,0,wKey,wKey*2,wKey][A_Index] . "px"
WinSet, Region, % "0-0 " wKey*3 "-0 " wKey*3 "-" (t := hKey*3+hCap) " 0-" t " 0-0 "
	. wKey "-" t " " wKey*2 "-" t " " wKey*2 "-" t+hKey " " wKey "-" t+hKey " " wKey "-" t
WinSet, Transparent, 235
OnMessage(0x201, "WM_LBUTTONDOWN"), OnMessage(0x200, "WM_MOUSEMOVE")
ComObjError(false), Layout(Bank)
WinGetPos, X, Y, W, , ahk_class Shell_TrayWnd ahk_exe explorer.exe
Gui, Show, % "NA x" (X+W)-(hKey*9)-28 " y" Y - (hKey * 4) - hCap - 2 " w" hKey*9+2, Virtual mini keyboard
SetTimer, OnTop, 500
(Clipboard = "" ? 0 : ClipInsert(Clipboard)), ClipInsert := 1
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
	Else If Area = ClipMan
		t := (e := oDoc.getElementById("ClipMan")).scrollTop, e.scrollTop := t+hKey, MouseDrag()
	Return

*WheelUp::
	If (GetKeyState("RButton", "P"))
		(Area = "Caption" ? Send("{Right}") : Send("^+{Right}"))
	Else If Area is number
		NextChr(Area)
	Else If Area = ClipMan
		t := (e := oDoc.getElementById("ClipMan")).scrollTop, e.scrollTop := t-hKey, MouseDrag()
	Return

*MButton::
	If (Area = "ClipMan" && GetKeyState("RButton", "P"))
		ClipManDelItem()
	Else If Area is number
		K_ChangeRegistr()
	Else If (Area = "Caption" || Area = "ClipMan")
		ClipManShow()
	Return

*RButton::
	If Area is number
		K_Input()
	Else If Area = Caption
		InputCancel(), oDoc.getElementById("viewinput").InnerText := "", ViewInput := ""
	Else If Area = ClipMan
		ClipTip()
	Return

#If (IsGuiScript && Area != "Caption")

*LButton::
	If (GetKeyState("RButton", "P"))
		(Area != "ClipMan" ? EmbBank() : 0)
	Else If Area is number
		NextChr(Area)
	Else If Area = Del
		Chr.P ? InputCancel() : ClickKey()
	Else If Area = Ret
		ClickKey()
	Else If Area = ClipMan
		ClipManSelect()
	Else If Area = Emb
		EmbBank()
	Else If Area = Turn
		Gosub K_MinMax
	Else If Area = Close
		ExitApp
	Return

#If

	; _________________________________________________ ClipMan _________________________________________________

OnClipboardChange:
	If (ClipInsert && A_EventInfo = 1)
		ClipInsert(Clipboard)
	Return

ClipManShow()  {
	x1 := wKey*3+2, x2 := x1+hKey*3, y2 := hKey*3+hCap, ClipManShow := !ClipManShow, it := 8, st := (hKey*3)/it
	Gui, +Lastfound
	Loop % it
	{
		Sleep 1
		rest := A_Index = it ? 0 : hKey*3-A_Index*st
		WinSet, Region, % "0-0 0-" y2 " " wKey "-" y2 " " wKey "-" y2+hKey " "
			. wKey*2 "-" y2+hKey " " wKey*2 "-" y2 " " wKey*3 "-" y2 " " wKey*3 "-0 "
			. (ClipManShow ? x1 "-0 " x2-rest "-0 " x2-rest "-" y2 " " x1 "-" y2 " " x1 "-0"
			: x1 "-0 " x1+rest "-0 " x1+rest "-" y2 " " x1 "-" y2 " " x1 "-0")
	}
}

ClipInsert(str)  {
	For K, V in Clips.Clone(), Clips := [], i := 1
	{
		If (K = 24 || str == V[1] "")
			Continue
		h .= "<a href=''><div name='ClipMan' id='" ++i "'>" V[2] "</div></a>", Clips[i] := [V[1] "", V[2]]
	}
	Clips[1] := [str "", ih := TransformHTML(SubStr(str, 1, 96))]
	(e := oDoc.getElementById("ClipMan")).innerHTML := "<a href=''><div name='ClipMan' id='1'>" ih "</div></a>" h
	e.scrollTop := 0, (Area = "ClipMan" ? MouseDrag() : 0)
}

ClipManSelect()  {
	Static tClipboardAll
	If (oNode.Id = "ClipMan")
		Return
	ClipInsert := 0
	tClipboardAll := ClipboardAll
	Clipboard := Clips[oNode.Id][1]
	Send("^{vk56}")
	SetTimer, ClipInsert, -50
	Return

	ClipInsert:
		Clipboard := tClipboardAll
		Sleep 50
		ClipInsert := 1, MouseDrag(2, 2)
		Return
}

ClipTip()  {
	If (oNode.Id = "ClipMan")
		Return
	SetTimer, OnTop, Off
	str := Clips[oNode.Id][1]
	ToolTip % SubStr(str, 1, 1000) . (StrLen(str) > 1000 ? ". . . . . . . . ." : "")
	KeyWait RButton
	ToolTip
	SetTimer, OnTop, 500
}

ClipManClean()  {
	Clips := [], oDoc.getElementById("ClipMan").innerHTML := ""
	ToolTip
}

ClipManDelItem()  {
	If (oNode.Id = "ClipMan")
		Return
	Clips.Remove(oNode.Id)
	ToolTip
	For K, V in Clips, i := 0
		h .= "<a href=''><div name='ClipMan' id='" ++i "'>" V[2] "</div></a>", Clips[i] := [V[1] "", V[2]]
	oDoc.getElementById("ClipMan").innerHTML := h, MouseDrag()
}

TransformHTML(str)  {
	Transform, str, HTML, %str%, 3
	StringReplace, str, str, <br>, &crarr;, 1
	StringReplace, str, str, %A_Space%, &rarr;, 1
	StringReplace, str, str, %A_Tab%, &harr;, 1
	Return str
}

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
	SetTimer, Input, % t = "ctrl" || t = "num" ? -30 : "-" TimeOut
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

	; Для управления сообщениями: SendMessage, 0xC, 3, "NextChr", , Virtual mini keyboard ahk_class AutoHotkeyGUI

WM_SETTEXT(wp, lp) {
	Return True, IsFunc(F := StrGet(lp)) ? %F%(wp) : 0
}

	; _________________________________________________ Window _________________________________________________

WM_MOUSEMOVE(wp, lp) {
	Area := (oNode := oDoc.elementFromPoint(lp & 0xFFFF, lp >> 16)).name
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

MouseDrag(offset=1, speed=0)   {
	MouseMove, "-" offset, 0, speed, R
	MouseMove, offset, 0, speed, R
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
	Global hThisGui, oDoc, Area, PrArea, PrBank, Caps, ViewInput, ClipManShow, ClipInsert, oNode
	, Chr := {}, Ins := {}, Type := {}, Clips := []
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
	<pre name='ClipMan' id='ClipMan'></pre>
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
	#ClipMan {
		overflow-y: 'auto';
		overflow-x: 'hidden';
		text-align: 'left';
		text-overflow: 'ellipsis';
		font-size: '" hKey/4.25 "px';
		font-family: 'Arial';
		color: '#" cChr "';
		cursor: 'default';
		scrollbar-track-color: '#" cBG "';
		scrollbar-3dlight-color: '#" cBG "';
		scrollbar-highlight-color: '#" cBG "';
		scrollbar-base-color: '#" cBorder "';
		scrollbar-arrow-color: '#" cBG "';
		position: 'absolute';
		width: " hKey*3 "px;
		height: " hKey*3+hCap "px;
		left: " wKey*3+2 "px;
		top: 0px;
	}
	a {display: block; text-decoration: none; color: '#" cChr "';}
	a:hover {background-color: '#" cCtrl "';}
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
		color: '#" cSel "';
		padding-top: '0.2em';
	}
	</style>
	)"

	For a, b in ["bRu","sRu","bEn","sEn","Emb","Num"]
		For c, d in Bank_%b%
		{
			Loop % d.maxindex()
				e .= "<span name='" c "' class='chr' id='p" c "c" A_Index "'>" d[A_Index] "</span>"
			Ins[b "_" c] := e, e := ""
			Type[b "_" c] := (t := SubStr(b, 1, 1)) = "b" ? (InStr(c, "1") ? "emb" : "big")
				: t = "s" ? (InStr(c, "1") ? "emb" : "small")
				: t = "E" ? (c > 6 ? "ctrl" : "emb") : "num"
		}
	Return
