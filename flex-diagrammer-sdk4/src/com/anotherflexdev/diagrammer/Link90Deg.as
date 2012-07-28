package com.anotherflexdev.diagrammer {
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	
	import mx.binding.utils.BindingUtils;
	import mx.controls.Label;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.events.ResizeEvent;
	import mx.styles.CSSStyleDeclaration;
	import mx.styles.StyleManager;
	
	[Style(name="templateBottomLineColor", type="uint", format="Color")]
	[Style(name="tempalteLineColor", type="uint", format="Color")]
	[Style(name="bottomLineColor", type="uint", format="Color")]
	[Style(name="lineColor", type="uint", format="Color")]
	[Style(name="lineThickness", type="Number")]
	public class Link90Deg extends Link {
		
		override protected function getMidlePoint():Point {
			var fromNodeCenterPoint:Point = new Point(this.fromNode.x+this.fromNode.width/2, this.fromNode.y+this.fromNode.height/2);
			var toNodeCenterPoint:Point = new Point(this.toNode.x + this.toNode.width/2, this.toNode.y + this.toNode.height/2);
			var point1:Point = this.getBoundary(fromNodeCenterPoint, toNodeCenterPoint, this.fromNode);
			var point2:Point = this.getBoundary(toNodeCenterPoint, fromNodeCenterPoint, this.toNode);
			var x:Number;
			var y:Number;
			var direction:String = getDrawDirectionFromPoints(fromNode.x, fromNode.y, fromNode.width, fromNode.height, toNode.x, toNode.y, toNode.width, toNode.height);
			if(direction == "RIGHT_BOTTOM" || direction == "RIGHT_TOP" || direction == "LEFT_BOTTOM" || direction == "LEFT_TOP") {
				x = point2.x;
				y = point1.y;
			} else {
				x = point1.x == point2.x ? point1.x : point1.x + ((point2.x-point1.x)/2);
				y = point1.x == point2.x ? point1.y + (point2.y - point1.y)/2 : this.getYBoundary(x, point2.x, point2.y, this.fromNode);
			}
			return new Point(x,y);			
		}
		
		override protected function drawLine(fromNodeCenterPoint:Point, toNodeCenterPoint:Point, bottomColor:uint, topColor:uint):void {
			var point1:Point = null;
			var point2:Point = null;
			
			if(this.toNode == null) {
				point1 = fromNodeCenterPoint;
				point2 = toNodeCenterPoint;
			} else {
				point1 = this.getBoundary(fromNodeCenterPoint, toNodeCenterPoint, this.fromNode);
				point2 = this.getBoundary(toNodeCenterPoint, fromNodeCenterPoint, this.toNode);
			}
			
			this.graphics.clear();
			
			var direction:String = getDrawDirectionFromPoints(fromNode.x, fromNode.y, fromNode.width, fromNode.height, toNode == null ? toNodeCenterPoint.x: toNode.x, toNode == null ? toNodeCenterPoint.y : toNode.y, toNode == null ? 10 : toNode.width, toNode == null ? 10 : toNode.height);
			var deltaX:Number = -1;
			var deltaY:Number = -1;
			var _90DegAngle:Boolean = false;
			if(direction == "RIGHT_BOTTOM" || direction == "RIGHT_TOP" || direction == "LEFT_BOTTOM" || direction == "LEFT_TOP") {
				_90DegAngle = true;
				if(direction == "RIGHT_BOTTOM"  || direction == "LEFT_BOTTOM") {
					deltaX = point1.x;
					deltaY = point2.y;
				} else {
					deltaX = point2.x;
					deltaY = point1.y;
				}
			} 
			this.graphics.lineStyle(this.getStyle("lineThickness")+2, bottomColor, 0.70);
			this.graphics.moveTo(point1.x, point1.y);
			if(_90DegAngle) 
				this.graphics.lineTo(deltaX, deltaY);
			this.graphics.lineTo(point2.x, point2.y);
			this.graphics.drawCircle(point1.x, point1.y, 4);
			
			this.graphics.lineStyle(this.getStyle("lineThickness"), topColor, 0.70);
			this.graphics.moveTo(point1.x, point1.y);
			if(_90DegAngle) 
				this.graphics.lineTo(deltaX, deltaY);
			this.graphics.lineTo(point2.x, point2.y);
			this.graphics.drawCircle(point1.x, point1.y, 2);
			if(_90DegAngle) 
				drawArrow(deltaX, deltaY, point2.x, point2.y, bottomColor, topColor);
			else	
				drawArrow(point1.x, point1.y, point2.x, point2.y, bottomColor, topColor);
		}

	  	override protected function getBoundary(fromCenterPoint:Point, toCenterPoint:Point, node:BaseNode):Point{
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
				if(drawDirection == "RIGHT" || drawDirection == "RIGHT_BOTTOM") {
					if(drawDirection == "RIGHT_BOTTOM") {
						by = tl + node.height/2;
						bx = rl;
						return new Point(bx, by);
					} else {
						by = getYBoundary(rl, toCenterPoint.x, toCenterPoint.y, node);
						bx = getXBoundary(bl, toCenterPoint.x, toCenterPoint.y, node);
						if(by<bl && by>tl) {
							return new Point(rl,by);
						} else if(bx<rl){
							return new Point(bx,bl);
						}  
					}
				} else if(drawDirection == "LEFT" || drawDirection == "LEFT_TOP"){
					if(drawDirection == "LEFT_TOP") {
						by = tl;
						bx = ll + node.width/2;
						return new Point(bx, by);
					} else {
						by = getYBoundary(ll, toCenterPoint.x, toCenterPoint.y, node);
						bx = getXBoundary(tl, toCenterPoint.x, toCenterPoint.y, node);
						if(bx>ll && bx<bl || by < tl) {
							return new Point(bx,tl);
						} else {
							return new Point(ll,by);
						}  
					}
				} else if(drawDirection == "LEFT_BOTTOM") {
					by = tl + node.height/2;
					bx = ll;
					return new Point(bx, by);
				} else if(drawDirection == "RIGHT_TOP") {
					by = tl;
					bx = ll + node.width/2;
					return new Point(bx, by);
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
		
	}
}