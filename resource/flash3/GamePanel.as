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
	
	public class GamePanel extends MovieClip {
		
		public var gameAPI:Object;
		public var globals:Object;
		
		private var _btnYes:VButton;
        private var _btnNo:VButton;
		
		private var _loc_2:VComponent;
		private var _loc_3;

		private var MouseStreamCheckbox:Object;

		public function GamePanel() {
			// constructor code
		}
		
		//set initialise this instance's gameAPI
		public function setup(api:Object, globals:Object) {
			this.gameAPI = api;
			this.globals = globals;
			
			trace("##Called GamePanel Setup!");
			this.visible = true;
			
			//font
			this.gameRestartLabel.text = Globals.instance.GameInterface.Translate("#GAMERESTARTING")
			var txFormat:TextFormat = new TextFormat;
			txFormat.font = "$TextFontBold";			
			this.gameRestartLabel.setTextFormat(txFormat);
			
			this.gameRestartLabel.visible = false;
			
			//Listeners
			this.gameAPI.SubscribeToGameEvent("toggle_restart", this.toggleGameRestart);
			
			var ExitButton = replaceWithValveComponent(btn_replace, "chrome_button_normal");
			ExitButton.addEventListener(ButtonEvent.CLICK, onExitButtonClicked);
			ExitButton.label = Globals.instance.GameInterface.Translate("#EXIT");

			MouseStreamCheckbox = replaceWithValveComponent(mouseStreamCheckbox, "DotaCheckBoxDota");
			MouseStreamCheckbox.addEventListener(ButtonEvent.CLICK, onMouseStreamChecked);
			trace("textfield width: " + MouseStreamCheckbox.textField.width);
			trace("textfield height: " + MouseStreamCheckbox.textField.height);

			MouseStreamCheckbox.label = Globals.instance.GameInterface.Translate("#MouseStreamCheckboxLabel");
			resetMouseStreamText();

			//ExitButton.width = 220;
			//ExitButton.height = 45;
						
			trace("##GamePanel Setup!");
		}
		
		public function toggleGameRestart():void
		{
			if (this.gameRestartLabel.visible == false)
			{
				this.gameRestartLabel.visible = true;
				trace("Game Restarting is now visible")
			}
			else
			{
				this.gameRestartLabel.visible = false
				trace("Game Restarting is invisible")
			}
		}
	
		public function onMouseStreamChecked(event:ButtonEvent) {
			trace("onMouseStreamChecked");
			this.gameAPI.SendServerCommand("MouseStreamToggle");

			// color resets, so we have to set it again.
			resetMouseStreamText();
		}

		public function onExitButtonClicked(event:ButtonEvent) {
			
			//Credits to Ractis for this
			trace("Leave?");
			this.visible = true;
			_loc_2 = new VComponent("bg_overlayBox");
			_loc_2.width = 500;
			_loc_2.height = 160;
			_loc_2.x = -350;
			_loc_2.y = 35;
			addChild(_loc_2);
			
			_loc_3 = Utils.CreateLabel(Globals.instance.GameInterface.Translate("#LeaveQuestion"), FontType.TextFont);
			
			//Font
			var _loc_4:* = new TextFormat();
			_loc_4.size = 24;
			_loc_4.align = TextFormatAlign.CENTER;
			_loc_4.color = 0xFFCC00;
			_loc_4.font = FontType.TextFontBold;
			_loc_3.setTextFormat(_loc_4);
			
			_loc_3.x = -350;
			_loc_3.y = 65;
			_loc_3.width = 500;
			_loc_3.alpha = 0.9;
			_loc_3.filters = [new GlowFilter(0x000000)];
			addChild(_loc_3);
				
			this._btnYes = new VButton("chrome_button_primary", Globals.instance.GameInterface.Translate("#YES"));
			this._btnYes.x = -300;
			this._btnYes.y = 120;
			addChild(this._btnYes);
				
			this._btnNo = new VButton("chrome_button_normal", Globals.instance.GameInterface.Translate("#NO"));
			this._btnNo.x = -50;
			this._btnNo.y = 120;
			addChild(this._btnNo);
				
			this._btnYes.addEventListener(ButtonEvent.CLICK, this._onClickYes);
			this._btnNo.addEventListener(ButtonEvent.CLICK, this._onClickNo);	
		}
		
		private function resetMouseStreamText() : void
		{
			MouseStreamCheckbox.textField.textColor = 0xFFC800;

			// make the text bigger
			var format:TextFormat = new TextFormat();
			format.size = 16;
			MouseStreamCheckbox.textField.defaultTextFormat = format;


			MouseStreamCheckbox.textField.setTextFormat(format);

		}

		private function _onClickYes(event:ButtonEvent) : void
		{
			this.gameAPI.SendServerCommand("Disconnecting");
			trace("##Disconnecting");
			this._close();
			return;
		}// end function
		
		private function _onClickNo(event:ButtonEvent) : void
		{
			trace("##Cancel");
			this._close();
			return;
		}// end function
		
		private function _close() : void
		{
			removeChild(_loc_2);
			//removeChild(_loc_3);
			//removeChild(this._btnYes);
			//removeChild(this._btnNo);
			_loc_3.visible = false;
			this._btnYes.visible = false;
			this._btnNo.visible = false;
			//visible = false;
			return;
		}
		
		//onScreenResize
		public function screenResize(stageW:int, stageH:int, xScale:Number, yScale:Number, wide:Boolean){
			
			trace("Stage Size: ",stageW,stageH);
						
			this.x = 350*yScale;
			this.y = 16*yScale;		
			
			this.width = this.width*yScale;
			this.height	 = this.height*yScale;
			
			trace("#Result Resize: ",this.x,this.y,yScale);
					 
			//Now we just set the scale of this element, because these parameters are already the inverse ratios
			this.scaleX = xScale;
			this.scaleY = yScale;
			
			trace("#Highscore Panel  Resize");
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
	}	
}

