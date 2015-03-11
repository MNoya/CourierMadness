package  {
	
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.utils.getDefinitionByName;
	import scaleform.clik.events.*;
	import flash.text.TextField;
    import flash.text.TextFormat;
	
	//import some stuff from the valve lib
	import ValveLib.Globals;
	import ValveLib.ResizeManager;

	import fl.transitions.Tween;
	import fl.transitions.easing.*;
		
	public class ScorePanel extends MovieClip {
		
		public var gameAPI:Object;
		public var globals:Object;		
	
		public function ScorePanel() {
			// constructor code
		}
		
		//set initialise this instance's gameAPI
		public function setup(api:Object, globals:Object) {
			this.gameAPI = api;
			this.globals = globals;
			
			//Listeners
			this.gameAPI.SubscribeToGameEvent("update_scoreboard", this.scoreEvent);
			this.gameAPI.SubscribeToGameEvent("update_multiplier", this.multiplierEvent);
				
			trace("##ScorePanel Setup!");
		}
		
		public function scoreEvent(args:Object) : void {
			//trace("##Event Firing Detected")
			//trace("##Data: "+args.player_ID+" - "+args.score);
			if (globals.Players.GetLocalPlayer() == args.player_ID)
			{
				this.setScore(args.score);
			}
		}
		
		public function setScore(number): void {
			currentScore.text = number;
			
			var txFormat:TextFormat = new TextFormat;
	
			//font
			txFormat.font = "$TextFontBold";					
			
			currentScore.setTextFormat(txFormat);
			
			trace("##ScorePanel Set Score to "+currentScore.text);
		}
		
		public function multiplierEvent(args:Object) : void {
			//trace("##Event Firing Detected")
			//trace("##Data: "+args.player_ID+" - "+args.multiplier);
			if (globals.Players.GetLocalPlayer() == args.player_ID)
			{
				this.setMultiplier(args.multiplier);
			}
		}
		
		public function setMultiplier(number): void {
			currentMultiplier.text = "x"+number;
			
			//font
			var txFormat:TextFormat = new TextFormat;
			txFormat.font = "$TextFontBold";					
			currentMultiplier.setTextFormat(txFormat);
			
			trace("##ScorePanel Set Multiplier to "+currentMultiplier.text);
		}
		
						
		//onScreenResize
		public function screenResize(stageW:int, stageH:int, xScale:Number, yScale:Number, wide:Boolean){
			
			trace("Stage Size: ",stageW,stageH);
						
			this.x = stageW/2;
			this.y = 20*yScale;		
			
			this.width = this.width*yScale;
			this.height	 = this.height*yScale;
			
			trace("#Result Resize: ",this.x,this.y,yScale);
					 
			//Now we just set the scale of this element, because these parameters are already the inverse ratios
			this.scaleX = xScale;
			this.scaleY = yScale;
			
			trace("#ScorePanel  Resize");
		}
	}
	
}
