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
	
	
	public class HighscorePanel extends MovieClip {
		
		public var gameAPI:Object;
		public var globals:Object;
		
		var currentHighscore:int = 0;
		
		public function HighscorePanel() {
			// constructor code
		}
		
		//set initialise this instance's gameAPI
		public function setup(api:Object, globals:Object) {
			this.gameAPI = api;
			this.globals = globals;
			
			trace("##Called HighscorePanel Setup!");
			this.visible = false;
			
			//Listeners
			this.gameAPI.SubscribeToGameEvent("show_highscore", this.showHighscore);
			this.gameAPI.SubscribeToGameEvent("update_highscore", this.updateHighscore);
			
			trace("##HighscorePanel Setup!");
			//globals.Loader_StatsCollectionHighscores.movieClip.SaveHighScore(modID:String, highscoreID:int, highscoreValue:int)
			//globals.Loader_StatsCollectionHighscores.movieClip.GetPersonalLeaderboard(modID:String, callback:Function)
			//globals.Loader_StatsCollectionHighscores.movieClip.GetTopLeaderboard(modID:String, callback:Function)
			//function Callback(jsonInfo:Object) {}
		}
		
		public function showHighscore(args:Object) : void {
			trace("##showHighscore");
			this.visible = true;
			//Get the Highscore for the player
			globals.Loader_StatsCollectionHighscores.movieClip.GetPersonalLeaderboard('70a0be5310f54fa1811657f5d5a0f884', PersonalCallback);
			trace("##FINISHED SHOWING HIGHSCORES");
		}
		
		public function PersonalCallback(jsonInfo:Object) {
			trace("###HighscorePanel PersonalCallback");
			var i:int = 0;
			for (var highscoreID in jsonInfo) {
				trace("##Tracing Highscore number "+i);
				i++;
				trace(highscoreID);
				var leaderboard:Array = jsonInfo[highscoreID];
				for each (var entry:Object in leaderboard) {
					trace(entry.highscoreValue);
					trace(entry.date);
						
					// Check to update highscore
					if (entry.highscoreValue < currentHighscore)
					{
						globals.Loader_StatsCollectionHighscores.movieClip.SaveHighScore('70a0be5310f54fa1811657f5d5a0f884', 1, currentHighscore);
						this.setHighScore(currentHighscore);
						trace("## HIGH SCORE SUCCESFULLY UPDATED TO "+currentHighscore);
						this.gameAPI.SendServerCommand("HighscoreAchieved "+currentHighscore);
					}
					else
					{
						trace("## Another higher score was found: ",entry.highscoreValue);
						currentHighscore = entry.highscoreValue;
						this.setHighScore(currentHighscore);
					}
				}
			}
			if (i == 0) { 
				trace("## NO HIGHSCORES, DEFAULTING TO 0"); 
				globals.Loader_StatsCollectionHighscores.movieClip.SaveHighScore('70a0be5310f54fa1811657f5d5a0f884', 1, 1);//Save 1 highscore because 0 is dumbo
				currentHighscore = 0;
				this.setHighScore(currentHighscore);
				this.gameAPI.SendServerCommand("ShowFirstTime");
			}
			else
			{
				//Welcome back! your highscore is...
				trace("## Welcome back! your highscore is "+currentHighscore); 
				this.gameAPI.SendServerCommand("OldHighscoreDetected "+currentHighscore);
			}
		}
				
		public function updateHighscore(args:Object) : void {
			
			trace("##Fired Game event, Checking if Highscore should be updated");
			if (globals.Players.GetLocalPlayer() == args.player_ID)
			{
				currentHighscore = args.score;
				globals.Loader_StatsCollectionHighscores.movieClip.GetPersonalLeaderboard('70a0be5310f54fa1811657f5d5a0f884', PersonalCallback);
			}
			trace("##Finished updateHighscore");
		}
		
		// Updates the number on the screen
		public function setHighScore(number): void {
			highScore.text = number;
			highscoreLabel.text = Globals.instance.GameInterface.Translate("#HIGHSCORE")
			
			//font
			var txFormat:TextFormat = new TextFormat;
			txFormat.font = "$TextFontBold";					
			highScore.setTextFormat(txFormat);
			
			var txFormat2:TextFormat = new TextFormat;
			txFormat2.font = "$TextFontBold";
			highscoreLabel.setTextFormat(txFormat2);
			
			trace("##HighScore Set Score to "+highScore.text);
		}
		
		//onScreenResize
		public function screenResize(stageW:int, stageH:int, xScale:Number, yScale:Number, wide:Boolean){
			
			trace("Stage Size: ",stageW,stageH);
						
			this.x = stageW-500*yScale;
			this.y = 25*yScale;		
			
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
