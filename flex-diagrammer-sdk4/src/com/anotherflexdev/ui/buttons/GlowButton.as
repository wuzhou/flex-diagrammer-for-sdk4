package com.anotherflexdev.ui.buttons {
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.filters.ColorMatrixFilter;
	import flash.filters.GlowFilter;
	import flash.ui.Keyboard;
	
	import mx.controls.Button;

	[IconFile("GlowButton.png")]
	[Style(name="glowColor", type="uint", format="Color")]
	public class GlowButton extends Button {
		
		private var glowFilter:GlowFilter;
		public var isPressed:Boolean;
		private const disabledImageFilter:ColorMatrixFilter = new ColorMatrixFilter([0.3, 0.6, 0.1, 0, 0,
																					 0.3, 0.6, 0.1, 0, 0,
																					 0.3, 0.6, 0.1, 0, 0,
																					 0,   0,   0,   .6, 0]);
		private var oldFilters:Array;
		
		
		public function set source(value:Class):void {
			this.setStyle("icon", value);
		}
		
		public function get source():Class {
			return this.getStyle("icon");
		}
		
		override public function set enabled(value:Boolean):void {
			super.enabled = value;
			if(value == false) {
				this.filters = [disabledImageFilter];
			} else {
				this.filters = null;
			}
		}
		
		public function GlowButton() {
			super();
			this.glowFilter = new GlowFilter;
			this.glowFilter.blurX = 12; glowFilter.blurY = 9;
			this.glowFilter.alpha = 1;
			this.glowFilter.quality = 2;
			this.glowFilter.knockout = false;
			this.glowFilter.strength = 1; 
			this.addEventListener(MouseEvent.MOUSE_OVER, handleMouseOver);
			this.addEventListener(MouseEvent.MOUSE_OUT, handleMouseOut);
			this.addEventListener(MouseEvent.MOUSE_DOWN, handleMouseDown);
			this.addEventListener(KeyboardEvent.KEY_DOWN, handleKeyDown);
			this.setStyle("skin", null);
		}
		
		private function handleKeyDown(event:KeyboardEvent):void {
			if(event.keyCode == Keyboard.SPACE && !this.isPressed) {
				this.handleMouseDown(null);
				systemManager.addEventListener(KeyboardEvent.KEY_UP, handleKeyUp);
			}
		}
		
		private function handleKeyUp(event:KeyboardEvent):void {
			if(event.keyCode == Keyboard.SPACE) {
				this.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
			}
			if(isPressed) {
				this.handleMouseUp(null);
			}
			systemManager.removeEventListener(KeyboardEvent.KEY_UP, handleKeyUp);
		}
		
		private function handleMouseOver(event:MouseEvent):void {
			if(this.enabled) {
				this.glowFilter.color = this.getStyle("glowColor");
				this.oldFilters = this.filters;
				this.filters = [this.glowFilter];
			}
		}
		
		private function handleMouseOut(event:MouseEvent):void {
			if(this.enabled) {
				this.filters = oldFilters;
			}
		}
		
		private function handleMouseDown(event:MouseEvent):void {
			if(this.enabled) {
				this.oldFilters = null;
				this.x += 1;
				this.y += 1;
				this.isPressed = true;
				systemManager.addEventListener(MouseEvent.MOUSE_UP, handleMouseUp);
			}
		}
		
		private function handleMouseUp(event:MouseEvent):void {
			if(this.enabled) {
				this.x -= 1;
				this.y -= 1;
				this.isPressed = false;
				systemManager.removeEventListener(MouseEvent.MOUSE_UP, handleMouseUp);
			}
		}
		
		override public function drawFocus(isFocused:Boolean):void {
			if(isFocused) {
				this.glowFilter.color = this.getStyle("themeColor");
				this.filters = [this.glowFilter];
			} else {
				this.glowFilter.color = this.getStyle("glowColor");
				this.filters = null;
			}
		}
		
		override protected function measure():void {
			super.measure();
			var w:Number = this.measuredWidth - (getStyle("paddingLeft") + getStyle("paddingRight"));
            var h:Number = this.measuredHeight - (getStyle("paddingTop") + getStyle("paddingBottom"));
	        measuredMinWidth = measuredWidth = w;
	        measuredMinHeight = measuredHeight = h;            
		}
		
	}
}
