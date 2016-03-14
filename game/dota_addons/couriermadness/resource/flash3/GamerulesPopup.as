package  {
	
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.utils.getDefinitionByName;
	import scaleform.clik.events.*;
	
	//import some stuff from the valve lib
	import ValveLib.Globals;
	import ValveLib.ResizeManager;

	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	
	//copied from VotingPanel.as source
	import flash.display.*;
    import flash.filters.*;
    import flash.text.*;
    import scaleform.clik.events.*;
    import vcomponents.*;
	
	
	public class GamerulesPopup extends MovieClip {
		
		public var gameAPI:Object;
		public var globals:Object;
		
		public function GamerulesPopup() {
			// constructor code
		}
		
		//set initialise this instance's gameAPI
		public function setup(api:Object, globals:Object) {
			this.gameAPI = api;
			this.globals = globals;
			
			trace("##Called GamerulesPopup Setup!");
			this.visible = false;
			
			//text
			this.PopupText1.text = Globals.instance.GameInterface.Translate("#PopupText")
			this.PopupText1.text = Globals.instance.GameInterface.Translate("#PopupText1")
			this.PopupText2.text = Globals.instance.GameInterface.Translate("#PopupText2")
			this.PopupText3.text = Globals.instance.GameInterface.Translate("#PopupText3")
			this.PopupText4.text = Globals.instance.GameInterface.Translate("#PopupText4")
			
			//font
			var txFormat:TextFormat = new TextFormat;
			var txFormat1:TextFormat = new TextFormat;
			var txFormat2:TextFormat = new TextFormat;
			var txFormat3:TextFormat = new TextFormat;
			var txFormat4:TextFormat = new TextFormat;
			txFormat.font = "$TextFontBold";			
			this.PopupText.setTextFormat(txFormat);
			txFormat1.font = "$TextFont";			
			this.PopupText1.setTextFormat(txFormat1);
			txFormat2.font = "$TextFont";			
			this.PopupText2.setTextFormat(txFormat2);
			txFormat3.font = "$TextFont";			
			this.PopupText3.setTextFormat(txFormat3);
			txFormat4.font = "$TextFont";			
			this.PopupText4.setTextFormat(txFormat4);
			
			var GoButton = replaceWithValveComponent(btn_replace_go, "ButtonThinSecondary");
			GoButton.addEventListener(ButtonEvent.CLICK, onGoButtonClicked);
			GoButton.label = Globals.instance.GameInterface.Translate("#Play");
			//GoButton.scaleX = 0.7;
			
			GoButton.getChildAt(0).width = 96;
			GoButton.getChildAt(1).width = 100;
			GoButton.getChildAt(2).width = 96;
			GoButton.getChildAt(3).width = 96;
			GoButton.getChildAt(4).x = -10;
						
			//Listeners
			this.gameAPI.SubscribeToGameEvent("show_gamerules_popup", this.showGameRulesPopup);
			
			trace("##GamerulesPopup Setup!");
		}
		
		public function onGoButtonClicked(event:ButtonEvent) {
			trace("##onGoButtonClicked");
			this.gameAPI.SendServerCommand("StartGame");
			this.visible = false;
		}
		
		public function showGameRulesPopup(args:Object) : void {	
			
			//Only show this in the corresponding player UI
			var pID:int = globals.Players.GetLocalPlayer();
			if (args.player_ID == pID) {
				trace("##showGameRulesPopup");
				this.visible = true;
			}
		}
		
		//Parameters: 
		//	mc - The movieclip to replace
		//	type - The name of the class you want to replace with
		//	keepDimensions - Resize from default dimensions to the dimensions of mc (optional, false by default)
		public function replaceWithValveComponent(mc:MovieClip, type:String, keepDimensions:Boolean = false) : MovieClip {
			var parent = mc.parent;
			var oldx = mc.x;
			var oldy = mc.y;
			var oldwidth = mc.width;
			var oldheight = mc.height;
			
			var newObjectClass = getDefinitionByName(type);
			var newObject = new newObjectClass();
			newObject.x = oldx;
			newObject.y = oldy;
			if (keepDimensions) {
				newObject.width = oldwidth;
				newObject.height = oldheight;
			}
			
			parent.removeChild(mc);
			parent.addChild(newObject);
			
			return newObject;
		}
		
		//onScreenResize
		public function screenResize(stageW:int, stageH:int, xScale:Number, yScale:Number, wide:Boolean){
			
			trace("Stage Size: ",stageW,stageH);
						
			this.x = stageW/2	;
			this.y = stageH/2 - (15*yScale);		
			
			this.width = this.width*yScale;
			this.height	 = this.height*yScale;
			
			trace("#Result Resize: ",this.x,this.y,yScale);
					 
			//Now we just set the scale of this element, because these parameters are already the inverse ratios
			this.scaleX = xScale;
			this.scaleY = yScale;
			
			trace("#Highscore Panel  Resize");
		}
	}
	
}
