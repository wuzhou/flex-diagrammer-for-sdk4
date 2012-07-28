package com.anotherflexdev.diagrammer {
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	
	import mx.binding.utils.BindingUtils;
	import mx.controls.Label;
	import mx.core.FlexGlobals;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.events.ResizeEvent;
	import mx.styles.CSSStyleDeclaration;
	import mx.styles.IStyleManager2;
	import mx.styles.StyleManager;
	
	[Style(name="templateBottomLineColor", type="uint", format="Color")]
	[Style(name="tempalteLineColor", type="uint", format="Color")]
	[Style(name="bottomLineColor", type="uint", format="Color")]
	[Style(name="lineColor", type="uint", format="Color")]
	[Style(name="lineThickness", type="Number")]
	public class Link extends UIComponent {
		
		[Bindable] public var fromNode:BaseNode;
		[Bindable] public var toNode:BaseNode;
		[Bindable] public var linkName:String;
		[Bindable] public var linkNum:Number = 0;
		private var fromPoint:Point;
		private var toPoint:Point;
		

		protected var label:Label;
		protected var linkContextPanel:GenericLinkContextPanel;
        private static var classConstructed:Boolean = classConstruct();
        
        private static function classConstruct():Boolean {
			var styleManager:IStyleManager2 = FlexGlobals.topLevelApplication.styleManager;
            if (!styleManager.getStyleDeclaration("Link")) {
                var defaultLinkStyles:CSSStyleDeclaration = new CSSStyleDeclaration();
                defaultLinkStyles.defaultFactory = function():void {
                    this.bottomLineColor = 0x2C2C54;
                    this.lineColor = 0xFFFFFF;
                    this.lineThickness = 2;
                    this.tempalteLineColor = 0xF0F0FF;
                    this.templateBottomLineColor = 0x008080;
                }
                styleManager.setStyleDeclaration("Link", defaultLinkStyles, true);
            }
            return true;
        }		
		
		public function Link() {
			super();			
			this.addEventListener(MouseEvent.CLICK, handleClick);
			this.addEventListener(KeyboardEvent.KEY_UP, handleKeyUp);
			this.addEventListener(FlexEvent.REMOVE, handleRemove);
		}
		
		override protected function createChildren():void {
			super.createChildren();
			if(!this.linkContextPanel) {
				this.createLinkContextPanel();
			}		
			if(!this.label) {
				this.createLabel();
				this.label.addEventListener(ResizeEvent.RESIZE, handleLabelResize);
				BindingUtils.bindProperty(this.label, "text", this, "linkName");		
			}	
		}
		
		protected function createLinkContextPanel():void {
			this.linkContextPanel = new LinkContextPanel;
			this.linkContextPanel.addEventListener("removeLink", handleRemoveLink);
			this.linkContextPanel.addEventListener("labelLink", handleLabelLink);			
		}
		
		protected function createLabel():void {
			this.label = new Label();
			this.label.addEventListener(MouseEvent.CLICK, handleClick);
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			if(!this.fromNode && !this.toNode) {
				return;
			}
			
			if(this.toNode == null) {
				this.drawTemplate();
			} else {
				this.draw();
			}
			if(this.linkContextPanel.parent != null) {
				this.setLinkContextPanelPosition();
			}
			if(this.linkName != null && this.linkName != "") {
				var point:Point = this.getMidlePoint();
				this.label.x = point.x;
				var drawDirection:String = getDrawDirection(this.fromNode, this.toNode);
				if(drawDirection == "TOP" || drawDirection == "BOTTOM" && fromNode.getAllLeavingLinksTo(toNode).length > 0) {
					this.label.y = (this.linkNum%2) == 0 ? point.y - (this.label.height/2 * this.linkNum) : point.y + (this.label.height/2 * this.linkNum);  
				} else {
					this.label.y = point.y;
				}
				this.label.x -= this.label.width/2;
				this.label.y -= this.label.height/2;
				this.label.setStyle("fontFamily", this.getStyle("labelFontFamily"));
				this.label.setStyle("fontSize", this.getStyle("labelFontSize"));
				this.label.setStyle("color",this.getStyle("labelFontColor"));
				this.label.setStyle("fontWeight",this.getStyle("labelFontWeight"));
				this.drawLinkRectangle(this.label.x - 1, this.label.y -1, this.label.width + 1, this.label.height + 1);
				if(this.label.parent == null && this.parent != null) {
					Diagram(parent).addChild(this.label);
				}
			} else {
				if(this.label.parent != null) {
					Diagram(parent).removeChild(this.label);
				}
			}
		}
		
		private function handleLabelResize(event:Event):void {
			this.invalidateDisplayList();
		}
		
		protected function getMidlePoint():Point {
//			var fromNodeCenterPoint:Point = new Point(this.fromNode.x+this.fromNode.width/2, this.fromNode.y+this.fromNode.height/2);
//			var toNodeCenterPoint:Point = new Point(this.toNode.x + this.toNode.width/2, this.toNode.y + this.toNode.height/2);
//			var point1:Point = this.getBoundary(fromNodeCenterPoint, toNodeCenterPoint, this.fromNode);
//			var point2:Point = this.getBoundary(toNodeCenterPoint, fromNodeCenterPoint, this.toNode);
			var point1:Point = this.fromPoint;
			var point2:Point = this.toPoint;
			var x:Number = point1.x == point2.x ? point1.x : point1.x + ((point2.x-point1.x)/2);
			var y:Number = point1.x == point2.x ? point1.y + (point2.y - point1.y)/2 : this.getYBound(x, point2.x, point2.y, point1.x, point1.y);
			return new Point(x,y);			
		}
		
		protected function handleRemove(event:Event):void {
			if(this.label.parent != null) {
				Diagram(parent).removeChild(this.label);
			}
			if(this.linkContextPanel.parent != null) {
				this.removeChild(this.linkContextPanel);
			}
		}
		
		protected function handleLabelLink(event:LabelLinkEvent):void {
			this.linkName = event.value;
			this.invalidateDisplayList();
			this.removeLinkContextPanelFromParent();
		}
		
		protected function handleKeyUp(event:KeyboardEvent):void {
			if(event.keyCode==Keyboard.BACKSPACE || event.keyCode == Keyboard.DELETE){
				handleRemoveLink(null);
			}				
		}
		
		protected function handleRemoveLink(event:Event):void {
			removeLinkContextPanelFromParent();
			Diagram(parent).removeLink(this);
		}
		
		protected function handleClick(event:MouseEvent):void {
			var diagram:Diagram = Diagram(parent);
			if(!diagram.isLinking && !diagram.contains(this.linkContextPanel)) {
				setLinkContextPanelPosition();
				this.linkContextPanel.linkName = this.linkName;
				diagram.addChild(this.linkContextPanel);
				diagram.addEventListener(MouseEvent.CLICK, handleParentClick);
				diagram.addEventListener(Event.ADDED, handleParentAdded);
				this.invalidateDisplayList();
				this.setFocus();
			}
		}
		
		protected function handleParentAdded(event:Event):void {
			if((event.target is GenericLinkContextPanel && event.target != this.linkContextPanel) || event.target is DiagramElement) {
				removeLinkContextPanelFromParent();
			}
		}
		
		protected function removeLinkContextPanelFromParent():void {
			this.linkContextPanel.currentState = null;
			this.linkContextPanel.invalidateDisplayList();
			Diagram(parent).removeEventListener(MouseEvent.CLICK, handleParentClick);
			Diagram(parent).removeEventListener(Event.ADDED, handleParentAdded);
			Diagram(parent).removeChild(this.linkContextPanel);
			this.invalidateDisplayList();
		}

		protected function setLinkContextPanelPosition():void {
			var point:Point = this.getMidlePoint();
			this.linkContextPanel.x = point.x;
			this.linkContextPanel.y = point.y;
			this.linkContextPanel.x -= this.linkContextPanel.width/2;
			if(this.label.parent != null) {
				this.linkContextPanel.y = (this.label.y - this.linkContextPanel.height);
			} else {
				this.linkContextPanel.y -= this.linkContextPanel.height;
			}
		}
		
		protected function handleParentClick(event:MouseEvent):void {
			if(event.target == parent && Diagram(parent).contains(this.linkContextPanel)) {
				removeLinkContextPanelFromParent();
			}
		}				
		
		protected function getCenterPoint(node:BaseNode):Point {
			var point:Point = new Point(node.x + (node.width/2), node.y + (node.height/2));
			return point;
		}
		
		protected function getYBoundary(x:Number, x2:Number, y2:Number, node:BaseNode):Number {
			var x1:Number = node.x+node.width/2;
			var y1:Number = node.y+node.height/2;
			return getYBound(x, x1, y1, x2, y2);
		}
		
		protected function getYBound(x:Number, x1:Number, y1:Number, x2:Number, y2:Number):Number {
			if(y1==y2) return y1;
			var a:Number = (y2-y1)/(x2-x1);
			var b:Number = y1-(a*x1);
			return (a*x)+b;
		}
		
		protected function getXBoundary(y:Number, x2:Number, y2:Number, node:BaseNode):Number {
			var x1:Number = node.x+node.width/2;
			var y1:Number = node.y+node.height/2;
			if(x1==x2) return x1;
			var a:Number = (y2-y1)/(x2-x1);
			var b:Number = y1-(a*x1);
			return (y-b)/a;
		}
				
		protected function draw():void {
			var fromNodeCenterPoint:Point = this.getCenterPoint(this.fromNode);
			var toNodeCenterPoint:Point = this.getCenterPoint(this.toNode);
			drawLine(fromNodeCenterPoint, toNodeCenterPoint, this.linkContextPanel.parent != null ? this.getStyle("selectionColor") : this.getStyle("bottomLineColor"), this.getStyle("lineColor"));
		}
		
		protected function drawTemplate():void {
			var fromNodeCenterPoint:Point = this.getCenterPoint(this.fromNode);
			var toNodeCenterPoint:Point = new Point(this.mouseX, this.mouseY);
			drawLine(fromNodeCenterPoint, toNodeCenterPoint, this.getStyle("templateBottomLineColor"), this.getStyle("tempalteLineColor"));
		}
		
		protected function drawLinkRectangle(x:Number, y:Number, w:Number, h:Number):void {
			//For easy event handling a transparent stronger line
			var ellipseH:Number = h;
			var ellipseW:Number = ellipseH;
			this.graphics.lineStyle(this.getStyle("lineThickness")+8, this.linkContextPanel.parent != null ? this.getStyle("selectionColor") : this.getStyle("bottomLineColor"), 0.1);
			this.graphics.drawRoundRect(x, y, w, h, ellipseW, ellipseH);
			//			
			this.graphics.beginFill(this.linkContextPanel.parent != null ? this.getStyle("selectionColor") : this.getStyle("bottomLineColor"), 1);
			this.graphics.lineStyle(this.getStyle("lineThickness")+2, this.getStyle("bottomLineColor"), 0.70);
			this.graphics.drawRoundRect(x, y, w, h, ellipseW, ellipseH);
			this.graphics.beginFill(this.getStyle("lineColor"), 0.70);
			this.graphics.lineStyle(this.getStyle("lineThickness"), this.getStyle("lineColor"), 0.70);			
			this.graphics.drawRoundRect(x, y, w, h, ellipseW, ellipseH);
		}

		protected function drawLine(fromNodeCenterPoint:Point, toNodeCenterPoint:Point, bottomColor:uint, topColor:uint):void {
			var point1:Point = null;
			var point2:Point = null;
			
			if(this.toNode == null) {
				point1 = fromNodeCenterPoint;
				point2 = toNodeCenterPoint;
			} else {
				point1 = this.getBoundary(fromNodeCenterPoint, toNodeCenterPoint, this.fromNode);
				point2 = this.getBoundary(toNodeCenterPoint, fromNodeCenterPoint, this.toNode);
				var drawDirection:String = null;
				drawDirection = getDrawDirection(this.fromNode, this.toNode);
				if(fromNode.getAllLinks().length > 1) {
					var lineThickness:Number = this.getStyle("lineThickness") != null ? this.getStyle("lineThickness") : 1;
					var linkIndex:Number = this.linkNum;
					if(linkIndex%2 == 0) {
						if(drawDirection == "RIGHT" || drawDirection == "LEFT") {
							point1.y += (lineThickness+8) * (linkIndex -1);
							point2.y += (lineThickness+8) * (linkIndex -1);
						} else if(drawDirection == "TOP" || drawDirection == "BOTTOM") {
							point1.x += (lineThickness+8) * (linkIndex -1);
							point2.x += (lineThickness+8) * (linkIndex -1);
						} else if(drawDirection == "LEFT_BOTTOM" || drawDirection == "RIGHT_TOP") {
							point1.y += (lineThickness+8) * (linkIndex -1);
							point1.x += (lineThickness+8) * (linkIndex -1);
							point2.y += (lineThickness+8) * (linkIndex -1);
							point2.x += (lineThickness+8) * (linkIndex -1);
						} else {
							point1.y -= (lineThickness+8) * (linkIndex -1);
							point1.x += (lineThickness+8) * (linkIndex -1);
							point2.y -= (lineThickness+8) * (linkIndex -1);
							point2.x += (lineThickness+8) * (linkIndex -1);
						}
					} else {
						if(drawDirection == "RIGHT" || drawDirection == "LEFT") {
							point1.y -= (lineThickness+8) * linkIndex;
							point2.y -= (lineThickness+8) * linkIndex;
						} else if(drawDirection == "TOP" || drawDirection == "BOTTOM") {
							point1.x -= (lineThickness+8) * linkIndex;
							point2.x -= (lineThickness+8) * linkIndex;
						} else if(drawDirection == "LEFT_BOTTOM" || drawDirection == "RIGHT_TOP") {
							point1.y -= (lineThickness+8) * linkIndex;
							point1.x -= (lineThickness+8) * linkIndex;
							point2.y -= (lineThickness+8) * linkIndex;
							point2.x -= (lineThickness+8) * linkIndex;
						} else {
							point1.y += (lineThickness+8) * linkIndex;
							point1.x -= (lineThickness+8) * linkIndex;
							point2.y += (lineThickness+8) * linkIndex;
							point2.x -= (lineThickness+8) * linkIndex;
							
						}
					}
				}
				
			}
			this.fromPoint = point1;
			this.toPoint = point2;
			
			this.graphics.clear();
			//For easy event handling a transparent stronger line
			this.graphics.lineStyle(this.getStyle("lineThickness")+8, bottomColor, 0.1);
			this.graphics.moveTo(point1.x, point1.y);
			this.graphics.lineTo(point2.x, point2.y);
			//			
			this.graphics.lineStyle(this.getStyle("lineThickness")+2, bottomColor, 0.70);
			this.graphics.moveTo(point1.x, point1.y);
			this.graphics.lineTo(point2.x, point2.y);
			this.graphics.drawCircle(point1.x, point1.y, 4);
			this.graphics.lineStyle(this.getStyle("lineThickness"), topColor, 0.70);
			this.graphics.moveTo(point1.x, point1.y);
			this.graphics.lineTo(point2.x, point2.y);
			this.graphics.drawCircle(point1.x, point1.y, 2);
			
			drawArrow(point1.x, point1.y, point2.x, point2.y, bottomColor, topColor);	
		}
		
		protected function getDrawDirection(fromNode:BaseNode, toNode:BaseNode):String{
			return this.getDrawDirectionFromPoints(fromNode.x, fromNode.y, fromNode.width, fromNode.height, toNode.x, toNode.y, toNode.width, toNode.height);	
		}
		
		protected function getDrawDirectionFromPoints(fromX:Number, fromY:Number, fromW:Number, fromH:Number, toX:Number, toY:Number, toW:Number, toH:Number):String{
		    var drawDirection :String;
		    var boxFromX2:int = fromX+fromW;
		    var boxFromY2:int = fromY+fromH;
		    var boxToX2:int = toX+toW;
		    var boxToY2:int = toY+toH;
		  	
		    if (fromX>boxToX2 && boxFromY2<toY){
		  	  drawDirection = "RIGHT_TOP";
		    }
		    else if (fromX>boxToX2 && fromY>boxToY2){
		      drawDirection  = "RIGHT_BOTTOM";
		    }
		    else if (boxFromX2<toX && fromY>boxToY2){
		      drawDirection  = "LEFT_BOTTOM";
		    }
		    else if (boxFromX2<toX && boxFromY2<toY){
		      drawDirection  = "LEFT_TOP";
		    }
		    else if (fromX>boxToX2){
		      drawDirection  = "RIGHT";
		    }
		    else if (boxFromY2<toY){
		      drawDirection  = "TOP";
		    }
		    else if (fromY>boxToY2){
		      drawDirection  = "BOTTOM";
		    }
		    else if (boxFromX2<toX){
		      drawDirection  = "LEFT";
		    }
		    return drawDirection;
		}		
				
	  	protected function getBoundary(fromCenterPoint:Point, toCenterPoint:Point, node:BaseNode):Point{
			if(node != null) {
				var rl:Number = node.x + node.width;
				var ll:Number = node.x;
				var tl:Number = node.y;
				var bl:Number = node.y + node.height;
				
				var by:Number = 0;
				var bx:Number = 0;
				
				var drawDirection:String = null;
				if(this.toNode == node) {
					drawDirection = getDrawDirection(this.fromNode, this.toNode);
				} else {
					drawDirection = getDrawDirection(this.toNode, this.fromNode);
				}
				trace(drawDirection);
				if(drawDirection == "RIGHT" || drawDirection == "RIGHT_BOTTOM") {
					by = getYBoundary(rl, toCenterPoint.x, toCenterPoint.y, node);
					bx = getXBoundary(bl, toCenterPoint.x, toCenterPoint.y, node);
					if(by<bl && by>tl) {
						return new Point(rl,by);
					} else if(bx<rl){
						return new Point(bx,bl);
					}  
				} else if(drawDirection == "LEFT" || drawDirection == "LEFT_TOP"){
					by = getYBoundary(ll, toCenterPoint.x, toCenterPoint.y, node);
					bx = getXBoundary(tl, toCenterPoint.x, toCenterPoint.y, node);
					if(bx>ll && bx<bl || by < tl) {
						return new Point(bx,tl);
					} else {
						return new Point(ll,by);
					}  
				} else if(drawDirection == "LEFT_BOTTOM") {
					by = getYBoundary(ll, toCenterPoint.x, toCenterPoint.y, node);
					bx = getXBoundary(bl, toCenterPoint.x, toCenterPoint.y, node);
					if(by>bl) {
						return new Point(bx,bl);
					} else {
						return new Point(ll,by);
					}  
				} else if(drawDirection == "RIGHT_TOP") {
					by = getYBoundary(rl, toCenterPoint.x, toCenterPoint.y, node);
					bx = getXBoundary(tl, toCenterPoint.x, toCenterPoint.y, node);
					if(by>tl) {
						return new Point(rl,by);
					} else {
						return new Point(bx,tl);
					}  
				} else if(drawDirection == "BOTTOM") {
					bx = getXBoundary(bl, toCenterPoint.x, toCenterPoint.y, node);
					return new Point(bx,bl);
				} else if(drawDirection == "TOP") {
					bx = getXBoundary(tl, toCenterPoint.x, toCenterPoint.y, node);
					return new Point(bx, tl);
				}
			} 
			return new Point(toCenterPoint.x, toCenterPoint.y);
	  	}
		
	  	protected function drawArrow(x1:Number, y1:Number, x2:Number, y2:Number, bottomColor:Number, topColor:Number):void{
			this.performArrowDrawing(x1,y1,x2,y2,this.getStyle("lineThickness")+2,bottomColor,0.70);		
			this.performArrowDrawing(x1,y1,x2,y2,this.getStyle("lineThickness"),topColor,0.70);		
	  	}		
		
		protected function performArrowDrawing(x1:Number, y1:Number, x2:Number, y2:Number, lineThickness:Number, color:Number, alpha:Number):void{
			this.graphics.lineStyle(lineThickness, color, alpha);
			var arrowHeight:Number = 5;
			var arrowWidth:Number = 5;
			var angle:Number = Math.atan2(y2-y1, x2-x1);
			graphics.moveTo(x2-arrowHeight*Math.cos(angle)-arrowWidth*Math.sin(angle),
			  							y2-arrowHeight*Math.sin(angle)+arrowWidth*Math.cos(angle));
			graphics.lineTo(x2, y2);
			graphics.lineTo(x2-arrowHeight*Math.cos(angle)+arrowWidth*Math.sin(angle),	
			  							y2-arrowHeight*Math.sin(angle)-arrowWidth*Math.cos(angle));										
		}
		
	}
}