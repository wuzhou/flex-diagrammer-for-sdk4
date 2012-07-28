package com.anotherflexdev.ui.skins {
	import flash.filters.DropShadowFilter;
	import flash.geom.Point;
	
	import mx.core.EdgeMetrics;
	import mx.skins.ProgrammaticSkin;
	import mx.styles.CSSStyleDeclaration;

	public class BalloonBorder extends ProgrammaticSkin {
		
		private static var defaultStyle:CSSStyleDeclaration = classConstruct();
		private var _borderMetrics:EdgeMetrics;
		        
        private static function classConstruct():CSSStyleDeclaration {
            var defaultLinkStyles:CSSStyleDeclaration = new CSSStyleDeclaration();
            defaultLinkStyles.defaultFactory = function():void {
                this.borderColor = 0xACACAC;
                this.backgroundColor = 0xFFFFFF;
                this.legSize = 5;
                this.roundHeight = 15;
                this.legPoint = "L20, L-10";
            }
            return defaultLinkStyles;
        }
        
        protected function legPointXIsRealPoint():Boolean {
        	var val:String = this.getStyle("legPoint");
        	var strX:String = val.substr(0, val.indexOf(","));
        	return strX.indexOf("L") != -1;
        }
        	
        protected function legPointYIsRealPoint():Boolean {
        	var val:String = this.getStyle("legPoint");
        	var strX:String = val.substr(0, val.indexOf(","));
        	return strX.indexOf("L") != -1;
        }	
        
        protected function parsePoint(val:String):Point {
        	var result:Point = new Point(0,0);
        	var strX:String = val.substr(0, val.indexOf(","));
        	if(strX.indexOf("L") != -1) {
        		strX = strX.substr(strX.indexOf("L")+1);
        		result.x = parent.x + Number(strX);
        	} else {
        		result.x = Number(strX);
        	}
        	var strY:String = val.substr(val.indexOf(",")+1);
        	if(strY.indexOf("L") != -1) {
        		strY = strY.substr(strY.indexOf("L")+1);
        		result.y = parent.y + Number(strY);
        	} else {
        		result.y = Number(strY);
        	}
        	return result;
        }	
        
        override public function getStyle(styleProp:String):* {
        	var result:Object = super.getStyle(styleProp);
        	if(!result) {
        		return defaultStyle.getStyle(styleProp);
        	} else {
        		return result;
        	}
        }
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			graphics.clear();
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			var borderThickness:Number = this.getStyle("borderThickness");
			var roundHeight:Number = this.getStyle("roundHeight");
			graphics.lineStyle(borderThickness, this.getStyle("borderColor"), 1, true);
			graphics.beginFill(this.getStyle("backgroundColor"));
			graphics.drawRoundRect(0, 0, unscaledWidth, unscaledHeight, roundHeight, roundHeight);
			graphics.endFill();
			if(parent!= null){
				var styleLegPoint:Point = this.parsePoint(this.getStyle("legPoint"));
				if(styleLegPoint != null && parent != null) {
					var realLegPoint:Point = new Point(styleLegPoint.x - parent.x, styleLegPoint.y - parent.y);
					var boxMiddlePointer:Point = new Point(parent.x + (parent.width / 2), parent.y + (parent.height / 2));
					var boundaryPointer:Point = this.getBoundary(styleLegPoint);
					var drawDirection:String = this.getLegPosition(styleLegPoint);
					switch(drawDirection) {
						case "BOTTOM" : 
						case "TOP" : drawLegAtTopOrBottom(realLegPoint, boundaryPointer); break;
						case "RIGHT" : 
						case "LEFT" : drawLegAtLeftOrRight(realLegPoint, boundaryPointer); break;
						case "TOP_RIGHT" : drawLegAtTopRight(realLegPoint, boundaryPointer); break;
						case "BOTTOM_RIGHT" : drawLegAtBottomRight(realLegPoint, boundaryPointer); break;
						case "TOP_LEFT" : drawLegAtTopLeft(realLegPoint, boundaryPointer); break;
						case "BOTTOM_LEFT" : drawLegAtBottomLeft(realLegPoint, boundaryPointer); break;
						case "INSIDE" : drawInsidePoint(realLegPoint);
					}			
				}
			}
			this.filters = [new DropShadowFilter(4, 45, 0, .50)];
		}
		
		public function get borderMetrics():EdgeMetrics {
			if (_borderMetrics) {
			   return _borderMetrics;
			}
			var styleLegPoint:Point = this.parsePoint(this.getStyle("legPoint"));
			var borderThickness:Number = getStyle("borderThickness");
			var drawDirection:String = this.getLegPosition(styleLegPoint);
			var legSize:Number = this.getStyle("legSize");
			switch(drawDirection) {
				case "LEFT" : _borderMetrics = new EdgeMetrics(borderThickness + legSize, borderThickness, borderThickness, borderThickness); break;
				case "RIGHT" : _borderMetrics = new EdgeMetrics(borderThickness, borderThickness, borderThickness + legSize, borderThickness); break;
				case "TOP_LEFT" : 
				case "TOP_RIGHT" : 
				case "TOP" : _borderMetrics = new EdgeMetrics(borderThickness, borderThickness + legSize, borderThickness, borderThickness); break;
				case "BOTTOM_RIGHT" : 
				case "BOTTOM_LEFT" : 
				case "BOTTOM" : _borderMetrics = new EdgeMetrics(borderThickness, borderThickness, borderThickness, borderThickness + legSize); break;
				default : _borderMetrics = new EdgeMetrics(borderThickness, borderThickness, borderThickness, borderThickness); 
			}				
			return _borderMetrics;
		}		
		
		protected function drawInsidePoint(leg:Point):void {
			graphics.beginFill(0xff0000, 0.5);
			graphics.drawCircle(leg.x, leg.y, 5);
			graphics.endFill();
		}
		
		protected function drawLegAtBottomRight(leg:Point, box:Point):void {
			var borderThickness:Number = getStyle("borderThickness");
			var legSize:Number = this.getStyle("legSize");
			graphics.beginFill(this.getStyle("backgroundColor"));
			graphics.lineStyle(borderThickness,this.getStyle("backgroundColor"));
			graphics.moveTo(leg.x, leg.y);
			graphics.lineTo(parent.width - legSize, box.y);
			graphics.lineTo(parent.width, box.y - legSize);
			graphics.lineTo(leg.x, leg.y);
			graphics.endFill();
			graphics.lineStyle(borderThickness, this.getStyle("borderColor"));			
			graphics.moveTo(leg.x, leg.y);
			graphics.lineTo(parent.width - legSize, box.y);
			graphics.moveTo(leg.x, leg.y);
			graphics.lineTo(parent.width, box.y - legSize);
		}

		protected function drawLegAtTopRight(leg:Point, box:Point):void {
			var borderThickness:Number = getStyle("borderThickness");
			var legSize:Number = this.getStyle("legSize");
			graphics.beginFill(this.getStyle("backgroundColor"));
			graphics.lineStyle(borderThickness,this.getStyle("backgroundColor"));
			graphics.moveTo(leg.x, leg.y);
			graphics.lineTo(parent.width - legSize, box.y);
			graphics.lineTo(parent.width, box.y + legSize);
			graphics.lineTo(leg.x, leg.y);
			graphics.endFill();
			graphics.lineStyle(borderThickness, this.getStyle("borderColor"));			
			graphics.moveTo(leg.x, leg.y);
			graphics.lineTo(parent.width - legSize, box.y);
			graphics.moveTo(leg.x, leg.y);
			graphics.lineTo(parent.width, box.y + legSize);
		}
		
		protected function drawLegAtTopOrBottom(leg:Point, box:Point):void {
			var borderThickness:Number = getStyle("borderThickness");
			var legSize:Number = this.getStyle("legSize");
			if((box.x + legSize) > (parent.width - legSize)){
				box.x = parent.width - (legSize *2);
			} else if ( (box.x - legSize) < legSize){
				box.x = legSize *2;
			}
			graphics.beginFill(this.getStyle("backgroundColor"));
			graphics.lineStyle(borderThickness,this.getStyle("backgroundColor"));
			graphics.moveTo(leg.x, leg.y);
			graphics.lineTo(box.x - legSize, box.y);
			graphics.lineTo(box.x + legSize, box.y);
			graphics.lineTo(leg.x, leg.y);
			graphics.endFill();
			graphics.lineStyle(borderThickness, this.getStyle("borderColor"));			
			graphics.moveTo(leg.x, leg.y);
			graphics.lineTo(box.x - legSize, box.y);
			graphics.moveTo(leg.x, leg.y);
			graphics.lineTo(box.x + legSize, box.y);
		}
		
		protected function drawLegAtTopLeft(leg:Point, box:Point):void {
			var borderThickness:Number = getStyle("borderThickness");
			var legSize:Number = this.getStyle("legSize");
			graphics.beginFill(this.getStyle("backgroundColor"));
			graphics.lineStyle(borderThickness,this.getStyle("backgroundColor"));
			graphics.moveTo(leg.x, leg.y);
			graphics.lineTo(box.x, box.y + legSize);
			graphics.lineTo(box.x + legSize, box.y);
			graphics.lineTo(leg.x, leg.y);
			graphics.endFill();
			graphics.lineStyle(borderThickness, this.getStyle("borderColor"));			
			graphics.moveTo(leg.x, leg.y);
			graphics.lineTo(box.x, box.y + legSize);
			graphics.moveTo(leg.x, leg.y);
			graphics.lineTo(box.x + legSize, box.y);
		}
		
		protected function drawLegAtBottomLeft(leg:Point, box:Point):void {
			var borderThickness:Number = getStyle("borderThickness");
			var legSize:Number = this.getStyle("legSize");
			graphics.beginFill(this.getStyle("backgroundColor"));
			graphics.lineStyle(borderThickness,this.getStyle("backgroundColor"));
			graphics.moveTo(leg.x, leg.y);
			graphics.lineTo(box.x, box.y - legSize);
			graphics.lineTo(box.x + legSize, box.y);
			graphics.lineTo(leg.x, leg.y);
			graphics.endFill();
			graphics.lineStyle(borderThickness, this.getStyle("borderColor"));			
			graphics.moveTo(leg.x, leg.y);
			graphics.lineTo(box.x, box.y - legSize);
			graphics.moveTo(leg.x, leg.y);
			graphics.lineTo(box.x + legSize, box.y);
		}
		
		protected function drawLegAtLeftOrRight(leg:Point, box:Point):void {
			var borderThickness:Number = getStyle("borderThickness");
			var legSize:Number = this.getStyle("legSize");
			var roundHeight:Number = this.getStyle("roundHeight");
			if(box.y < roundHeight) {
				box.y = roundHeight;
			}
			if(box.y > parent.height - roundHeight) {
				box.y = parent.height - roundHeight;
			}
			graphics.beginFill(this.getStyle("backgroundColor"));
			graphics.moveTo(leg.x, leg.y);
			graphics.lineTo(box.x, box.y - legSize);
			graphics.lineTo(box.x, box.y + legSize);
			graphics.lineTo(leg.x, leg.y);
			graphics.endFill();
			graphics.lineStyle(borderThickness, this.getStyle("backgroundColor"));
			graphics.moveTo(box.x, box.y - legSize);
			graphics.lineTo(box.x, box.y + legSize);
		}
		
		protected function getLegPosition(legPoint:Point):String {
			var rx:Number = parent.x + parent.width;
			var by:Number = parent.y + parent.height;
			if(legPoint.x < parent.x && legPoint.y > parent.y && legPoint.y < by) {
				return "LEFT";
			} else if(legPoint.x > parent.x && legPoint.x < rx && legPoint.y < parent.y) {
				return "TOP";
			} else if(legPoint.x > rx && legPoint.y > parent.y && legPoint.y < by) {
				return "RIGHT";
			} else if(legPoint.x > parent.x && legPoint.x < rx && legPoint.y > by) {
				return "BOTTOM";
			} else if(legPoint.x < parent.x && legPoint.y < parent.y) {
				return "TOP_LEFT";
			} else if(legPoint.x < parent.x && legPoint.y > by) {
				return "BOTTOM_LEFT";
			} else if(legPoint.x > rx && legPoint.y < parent.y) {
				return "TOP_RIGHT";
			} else if(legPoint.x > rx && legPoint.y > by) {
				return "BOTTOM_RIGHT";
			} else {
				return "INSIDE";
			}
		}
		
		protected function getBoundary(legPoint:Point):Point{
			var legPos:String = this.getLegPosition(legPoint);
			var realLegPoint:Point = new Point(legPoint.x - parent.x, legPoint.y - parent.y);
			if(legPos == "LEFT") {
				return new Point(0, realLegPoint.y);
			} else if(legPos == "TOP_LEFT") {
				return new Point(0, 0);
			} else if(legPos == "BOTTOM_LEFT") {
				return new Point(0, parent.height);
			} else if(legPos == "TOP") {
				return new Point(realLegPoint.x, 0);
			} else if(legPos == "TOP_RIGHT") {
				return new Point(parent.width, 0);
			} else if(legPos == "RIGHT") {
				return new Point(parent.width, realLegPoint.y);
			} else if(legPos == "BOTTOM_RIGHT") {
				return new Point(parent.width, parent.height);
			} else if(legPos == "BOTTOM") {
				return new Point(realLegPoint.x, parent.height);
			} else {
				return legPoint;
			}
		}
		
	}
}