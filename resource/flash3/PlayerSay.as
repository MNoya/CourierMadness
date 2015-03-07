// This is used to kill the player writing cheats
package {
	import flash.display.MovieClip;

	//import some stuff from the valve lib
	import ValveLib.Globals;
	import ValveLib.ResizeManager;
	
	public class PlayerSay extends MovieClip{
		
		//these three variables are required by the engine
		public var gameAPI:Object;
		public var globals:Object;
		public var elementName:String;
		
		//constructor, you usually will use onLoaded() instead
		public function PlayerSay() : void {
			trace("[PlayerSay] PlayerSay UI Constructed!");
		}
		
		//this function is called when the UI is loaded
		public function onLoaded() : void {			
			var oldChatSay:Function = globals.Loader_hud_chat.movieClip.gameAPI.ChatSay;
			globals.Loader_hud_chat.movieClip.stopMessageMode()
			globals.Loader_hud_chat.movieClip.gameAPI.ChatSay = function(obj:Object, bool:Boolean){
				var type:int = globals.Loader_hud_chat.movieClip.m_nLastMessageMode
				if (bool)
					type = 4
				
				gameAPI.SendServerCommand( "player_say " + type + " " + obj.toString());
				globals.Loader_hud_chat.movieClip.hud_chat_input.InputBox.text = ""
				oldChatSay("", bool);
				//globals.Loader_hud_chat.movieClip.stopMessageMode() //kills the chat but also the hotkeys
			};
		}
		
		//this handles the resizes - credits to Nullscope
		public function onResize(re:ResizeManager) : * {
			
		}
	}
}