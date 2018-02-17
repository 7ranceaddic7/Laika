// ----------------------------------------------------------------------------------[WINDOW'S WIDTH]---->

//									
//	PID Controller Module for LAIKA.				
//									
// * New architecture format using PreProcessor				
//									

// * Updated for KoS 1.1.5.0.

//			
// CONFIG SETUP		
//			
// {{{
// >> Sets-up module's basic data			     <<	

LOCAL _mFullN IS
// **** [0]: MODULE FULLNAME				   ****	
	"PID Controller".

// **** [1]: MODULE SHORT NAME				   ****	
LOCAL _mShortN IS
	"PIDC".

LOCAL _defaultP IS
// **** [2]: EXTRA PARAMETERS (can be FALSE).		   ****	
	LEXICON(
		"Kp",		0.01,
		"Ki",		0.006,
		"Kd",		0.006,
		"Zero",		1000,
		"Sensed",	"SHIP:ALTITUDE",
		"Timer",	"TIME:SECONDS",
		"Output",	"THROTTLE"
	).

//@ IF (FALSE):			
// Block executed during CONFIG-PHASE.
// MOD_DATA LIST(					{{{	
//	[0]		Module fullname				
//	[1]		Module short name			
//	[2] 		Extra parameters (can be FALSE)		
//	[3] LIST()	Informations				
//	[4] LIST()	Version					
//	[5] LIST()	UI Placement				
//	[6] LEX()	Required Modules			
//	[7] LEX()	Configurator Calls			
//	[8] LEX()	Configurator Options (can be FALSE)	
// 							}}}	
GLOBAL MOD_DATA IS LIST( _mFullN, _mShortN, _defaultP,

// **** [3]: INFORMATIONS				   ****	
	LIST(
//	   >>>> [3,0]: Description.			
		"Generic PID controller KoS based.
		 This is an early version.",

//	   >>>>	[3,1]: Author name.			
		"(Laika Dev Team)",
//	   >>>>	[3,2]: Extra Options' descriptions.	
		LEXICON(
			"Kp",		"Proportional gain.",
			"Ki",		"Integral gain.",
			"Kd",		"Derivative gain.",
			"Zero",		"Desired value the PID should reach and keep.",
			"Sensed",	"Sensed value the PID will read.",
			"Timer",	"Time value used for integration and derivation.",
			"Output",	"Actuator agent contolled by PID."
		),
//	   >>>>	[3,3]: Config Options' descriptions.	
		LEXICON()
	),

// ****	[4]: VERSION					   ****	
	LIST(
// 	   >>>>	[4,0]: MAJOR				
		0,
// 	   >>>>	[4,1]: MINOR				
		1,
//	   >>>> [4,2]: PATCH				
		3
	),

// ****	[5]: UI-PLACEMENT				   ****	
	LIST(
// 	   >>>>	[5,0]: Self menu name.			
		"PID",

// 	   >>>>	[5,1]: Parent menu name.		
		"MAIN",

// 	   >>>>	[5,2]: Btn num in parent menu (base1).	
		1
	),

// ****	[6]: REQUIRED MODULES				   ****	
	LEXICON(
	),

// **** [7]: CONFIGURATOR CALLS				   ****	
	LEXICON(
		"prebuild", _prebuild@
	),

// **** [8]: CONFIGURATOR OPTIONS (can be FALSE)	   ****	
	FALSE
).

// _prebuild function must return a LEXICON() structure.
LOCAL FUNCTION _prebuild {
	PARAMETER m IS FALSE.
	
	IF m:TYPENAME = "Bool" RETURN LEXICON().

	LOCAL ret IS LEXICON(
//					SET Output TO PID:UPDATE(Timer, Sensed).
		"update",		"SET " + m[2][0]["Output"] +" TO PID:UPDATE(" + m[2][0]["Timer"]
						+", " + m[2][0]["Sensed"] + ").",

//					SET Output TO 0.
		"release",		"SET " +m[2][0]["Output"] +" TO 0."
	).

	RETURN ret.
}

PRINT msgModF +_mFullN.		// Module found message.
// }}}


IF FALSE {
//@ ELSE:		{{{	
// Block executed after preprocessing by LAIKA.

//			
// INSTALLATION		
//			
// {{{
PARAMETER _mName	IS "UNKN", // Module menu name
	_mParent	IS "MAIN", // Parent menu name
	_mButton	IS 7,	   // Button number in parent menu (base1)
	_extraP		IS FALSE.  // Extra configuration for this module (FALSE if none).

// The followings are mandatory lines.
PRINT "Loading: " +_mFullN.	// fullname

SET _extraP TO import( _extraP, _defaultP).

// >> Adds the new menu structure to MenuRegistry		{{{	
//									
//	LK_MENUS:ADD(							
//		menu_name,						
//		LIST(							
//			back_menu,					
//			LIST(button_name),				
//			LIST(is_submenu?)				
//		)							
// 	).								
//								}}}	
LK_MENUS:ADD(
	_mName, LIST( _mParent,	// module menu name - parent menu name
		LIST("ACTIVATE", "DEACTIVATE", "", "", "", "", "", ""),
		LIST(FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE))
).


// >> Install module menu to desired parent-menu's button	{{{	
//									
//	LK_MENUS[menu_name][0] = back_menu				
//      	              [1] = LIST(button_name)			
//	 		      [2] = LIST(is_submenu?)			
//								}}}	
SET LK_MENUS[_mParent][1][_mButton-1] TO _mName.
SET LK_MENUS[_mParent][2][_mButton-1] TO TRUE.


// >> Adds module menu commands to CommandsRegistry.		{{{	
//									
//	LK_CMDS:ADD( menu_name,						
//		LIST (							
//			LEXICON(button_name, function),			
//			LIST(daemon_running_while_on_this_menu)		
//		)							
//	).								
//								}}}	
LK_CMDS:ADD(_mName, LIST(
	LEXICON(
		"ACTIVATE",	pidActivate@,
		"DEACTIVATE",	pidDeactivate@),
	LIST(),
	LEXICON())
).

// }}}

LOCAL PID IS PIDLOOP(_extraP["Kp"], _extraP["Ki"], _extraP["Kd"], 0, 1).

LOCAL FUNCTION pidActivate {
	IF DAEMONS:HASKEY("PID") RETURN.

	PID:RESET.
	SET PID:SETPOINT TO _extraP["Zero"].
	DAEMONS:ADD("PID", updateAll@).
}

LOCAL FUNCTION updateAll {
//@ ADDCODE(update).
//@ IF NOT DECLARED(update):
	SET THROTTLE TO PID:UPDATE(TIME:SECONDS, SHIP:ALTITUDE).	// Default behaviour.
//@ ENDIF.
}

LOCAL FUNCTION pidDeactivate {
	IF NOT DAEMONS:HASKEY("PID") RETURN.

	DAEMONS:REMOVE("PID").
//@ ADDCODE(release).
//@ IF NOT DECLARED(release):
	SET THROTTLE TO 0.						// Default behaviour.
//@ ENDIF.
}

//@ ENDIF.		}}}	

//@ EXCLUDE NEXT.		
}

// last size: 746b
// last size: 768b
//
// vim: fdc=6 fdm=marker :