# Written by Anders
#
# http://nsis.sourceforge.net/WinSxS_QueryAssemblyInfo_to_check_if_assembly_is_installed

!include LogicLib.nsh
!include WinVer.nsh

Function WinSxS_HasAssembly ;legacyDllName,(Strong)AssemblyName
	/*
	push 'msvcr80.dll'
	push 'Microsoft.VC80.CRT,version="8.0.50727.42",type="win32",processorArchitecture="x86",publicKeyToken="1fc8b3b9a1e18e3b"'
	call WinSxS_HasAssembly
	pop $0 ;0 on fail, 1 if it is in WinSxS or 2 if LoadLibrary worked on pre xp (call GetDLLVersion to make sure if you require a minimum version)
	*/
	Exch $8
	Exch
	Exch $7
	Push $9
	StrCpy $9 0
	Push $0
	Push $R0
	Push $R1

	${If} ${AtLeastWinXP}
		System::Call "sxs::CreateAssemblyCache(*i.R0,i0)i.r0"
		${If} $0 == 0
			System::Call '*(i 24,i0,l,i0,i0)i.R1' ;TODO,BUGBUG: check alloc success
			System::Call `$R0->4(i 0,w '$8',i $R1)i.r0` ;IAssemblyCache::QueryAssemblyInfo
			${If} $0 == 0
				System::Call '*$R1(i,i.r0)'
				IntOp $0 $0 & 1 ;ASSEMBLYINFO_FLAG_INSTALLED=1
				${IfThen} $0 <> 0 ${|} StrCpy $9 1 ${|}
			${EndIf}
			System::Free $R1
			System::Call $R0->2() ;IAssemblyCache::Release
		${EndIf}
	${Else}
		; i.r0 at the end has the following meaning
		; i  : Return type is an integer
		; .  : We don't care about the source
		; r0 : The destination is $0
		System::Call kernel32::LoadLibrary(t"$7")i.r0
		${If} $0 != 0
			StrCpy $9 2
			System::Call 'kernel32::FreeLibrary(i r0)'
		${EndIf}
	${EndIf}

	Pop $R1
	Pop $R0
	Pop $0
	Exch 2
	Pop $8
	Pop $7
	Exch $9
FunctionEnd