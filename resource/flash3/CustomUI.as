package {
	import flash.display.MovieClip;
	import flash.text.*;

	//import some stuff from the valve lib
	import ValveLib.Globals;
	import ValveLib.ResizeManager;
	
	public class CustomUI extends MovieClip{
		
		//these three variables are required by the engine
		public var gameAPI:Object;
		public var globals:Object;
		public var elementName:String;
		
		//
		private var ScreenWidth:int;
		private var ScreenHeight:int;
		public var scaleRatioY:Number;
		
		//outside of func
		private var holder:MovieClip = new MovieClip;
		
		//constructor, you usually will use onLoaded() instead
		public function CustomUI() : void {
	
		}
		
		//this function is called when the UI is loaded
		public function onLoaded() : void {		
			//make this UI visible
			visible = true;
			
			trace("OnLoaded");
			
			this.addChild(holder);
			
			trace("added Child Holder");
			
			//let the client rescale the UI
			Globals.instance.resizeManager.AddListener(this);
			
			trace("resize manager done");
			
			//pass the gameAPI on to the modules
			this.myScore.setup(this.gameAPI, this.globals);
			
			trace("myScore.setup");
			
			this.myHighscore.setup(this.gameAPI, this.globals);
			
			trace("myHighscore.setup");
			
			this.myGamePanel.setup(this.gameAPI, this.globals);
			
			trace("myGamePanel.setup");
			
			this.myPopup.setup(this.gameAPI, this.globals);
			
			trace("myGamePanel.setup");
			
			this.gameAPI.SubscribeToGameEvent("show_ultimate_ability", this.AbilityButtonEvent);
			
			

			//this is not needed, but it shows you your UI has loaded (needs 'scaleform_spew 1' in console)
			trace("Custom UI loaded!");
		}
		
		public function AbilityButtonEvent(args:Object) : void {
			trace("##Event Firing Detected")
			trace("##Data: "+args.player_ID);
			if (globals.Players.GetLocalPlayer() == args.player_ID)
			{
				this.showAbilityButton();
			}
		}
		
		public function showAbilityButton(): void {
			globals.Loader_actionpanel.movieClip.visible = false;
			
			// Special thanks to zed for this
			var abHold = globals.Loader_actionpanel.movieClip.middle.abilities["Ability3"];
			var manaHold = globals.Loader_actionpanel.movieClip.middle.abilities["abilityMana3"];
			var keyHold = globals.Loader_actionpanel.movieClip.middle.abilities["abilityBind3"];
			globals.Loader_actionpanel.movieClip.middle.abilities.removeChild(abHold);
			globals.Loader_actionpanel.movieClip.middle.abilities.removeChild(manaHold);
			globals.Loader_actionpanel.movieClip.middle.abilities.removeChild(keyHold);
								
			holder.addChild(abHold);
			holder.addChild(manaHold);
			holder.addChild(keyHold);
						
			holder.x = ScreenWidth/2 - (280);
			holder.y = ScreenHeight/10;
									
			//holder.width = 128;
			//holder.height = 100;
			trace(abHold.scaleX,abHold.scaleY);
			abHold.scaleY = 1 * scaleRatioY;
			abHold.scaleX = 1 * scaleRatioY;
			
			trace(manaHold.scaleX,manaHold.scaleY);
			manaHold.scaleY = 1 * scaleRatioY;
			manaHold.scaleX = 1 * scaleRatioY;
			
			trace(keyHold.scaleX,keyHold.scaleY);
			keyHold.scaleY = 1.5 * scaleRatioY;
			keyHold.scaleX = 1.5 * scaleRatioY;
		}
		
		//this handles the resizes
		public function onResize(re:ResizeManager) : * {
			
			// calculate by what ratio the stage is scaling
			scaleRatioY = re.ScreenHeight/1080;
			
			trace("##### RESIZE #########");
					
			ScreenWidth = re.ScreenWidth;
			ScreenHeight = re.ScreenHeight;
					
			//pass the resize event to our module, we pass the width and height of the screen, as well as the INVERSE of the stage scaling ratios.
			this.myScore.screenResize(re.ScreenWidth, re.ScreenHeight, scaleRatioY, scaleRatioY, re.IsWidescreen());
			this.myHighscore.screenResize(re.ScreenWidth, re.ScreenHeight, scaleRatioY, scaleRatioY, re.IsWidescreen());
			this.myGamePanel.screenResize(re.ScreenWidth, re.ScreenHeight, scaleRatioY, scaleRatioY, re.IsWidescreen());
			this.myPopup.screenResize(re.ScreenWidth, re.ScreenHeight, scaleRatioY, scaleRatioY, re.IsWidescreen());
		}
	}
}