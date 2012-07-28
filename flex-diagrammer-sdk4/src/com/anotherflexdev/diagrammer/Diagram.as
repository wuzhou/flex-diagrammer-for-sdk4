package com.anotherflexdev.diagrammer {
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.net.FileReference;
	import flash.utils.ByteArray;
	
	import mx.collections.ArrayCollection;
	import mx.containers.Canvas;
	import mx.core.ClassFactory;
	import mx.core.IFactory;
	import mx.core.UIComponent;
	import mx.events.DragEvent;
	import mx.events.FlexEvent;
	import mx.graphics.codec.IImageEncoder;
	import mx.graphics.codec.JPEGEncoder;
	import mx.graphics.codec.PNGEncoder;
	import mx.managers.DragManager;
	import mx.managers.PopUpManager;
	

	[Event(name="nodeAdded", type="com.anotherflexdev.diagrammer.NodeEvent")] 
	[Event(name="nodeRemoved", type="com.anotherflexdev.diagrammer.NodeEvent")] 
	public class Diagram extends Canvas {
		
		private var templateLine:Link;
		public var defaultLinkClass:IFactory = new ClassFactory(Link);
		[Bindable] public var numNodes:Number = 0;
		
		public function Diagram() {
			super();
			this.addEventListener(DragEvent.DRAG_ENTER, handleDragEnter);
			this.addEventListener(DragEvent.DRAG_DROP, handleDragDrop);
			this.addEventListener(MouseEvent.MOUSE_MOVE, handleMouseMove);
			this.addEventListener(Event.ADDED, handleAdded);
			this.addEventListener(Event.REMOVED, handleRemoved);
		}
		
		public function get isLinking():Boolean {
			return this.templateLine.fromNode != null;
		}
		
		override protected function createChildren():void {
			if(!this.templateLine) {
				this.templateLine = this.defaultLinkClass.newInstance() as Link;
			}
			super.createChildren();
		}
		
		private function handleAdded(event:Event):void {
			if(event.target is BaseNode) {
				var node:BaseNode = BaseNode(event.target);
				node.addEventListener(MouseEvent.ROLL_OVER, handleNodeRollOver);
				node.addEventListener(MouseEvent.ROLL_OUT, handleNodeRollOut);
				this.numNodes++;
				dispatchEvent(new NodeEvent("nodeAdded", event.target as BaseNode));
			}
		}
		
		private function handleRemoved(event:Event):void {
				if(event.target is BaseNode) {
					var node:BaseNode = BaseNode(event.target);
					node.removeEventListener(MouseEvent.ROLL_OVER, handleNodeRollOver);
					node.removeEventListener(MouseEvent.ROLL_OUT, handleNodeRollOut);
					this.numNodes--;
					dispatchEvent(new NodeEvent("nodeRemoved", event.target as BaseNode));
				}
		}
		
		private function handleNodeRollOver(event:MouseEvent):void {
			if(this.isLinking) {
				this.templateLine.toNode = BaseNode(event.currentTarget);
			}
		}
		
		private function handleNodeRollOut(event:MouseEvent):void {
			if(this.isLinking) {
				this.templateLine.toNode = null;
			}
		}
		
		private function handleDragDrop(event:DragEvent):void {
			var node:BaseNode = event.dragSource.dataForFormat("node") as BaseNode;
			var pt:Point = new Point(event.localX, event.localY);  
			pt = event.target.localToContent(pt);
			node.x = pt.x - Number(event.dragSource.dataForFormat("mouseX"));//.stageX
			node.y = pt.y - Number(event.dragSource.dataForFormat("mouseY"));//.stageY
		}		
				
		private function handleDragEnter(event:DragEvent):void {
		  	DragManager.acceptDragDrop(UIComponent(event.currentTarget));			
		}		
		
		private function handleMouseMove(event:MouseEvent):void {
			if(this.isLinking) {
				this.templateLine.invalidateDisplayList();
			}
		}
		
		public function beginLink(fromNode:BaseNode):void {
			this.templateLine = this.defaultLinkClass.newInstance() as Link;
			this.templateLine.fromNode = fromNode;
			this.addChildAt(this.templateLine, 0);
		}
		
		public function endLink():void {
			this.removeChild(this.templateLine);
			this.addLink(this.templateLine.fromNode, this.templateLine.toNode);
			this.templateLine.fromNode = null;
			this.templateLine.toNode = null;
		}
		
		public function addLink(fromNode:BaseNode, toNode:BaseNode):Link {
			var link:Link = null;
			if(toNode.customLink != null) {
				link = toNode.customLink.newInstance();
			} else {
				link = this.defaultLinkClass.newInstance() as Link;
			}
			link.fromNode = fromNode;
			link.toNode = toNode;
			fromNode.addLeavingLink(link);
			toNode.addArrivingLink(link);
			this.addChildAt(link, 0);
			return link;
		}
		
		public function removeNode(node:BaseNode):void {
			this.removeChild(node);
			var nodeLinks:ArrayCollection = node.getAllLinks();
			for each(var nodeLink:Link in nodeLinks){
				if(this.contains(nodeLink)){
					this.removeChild(nodeLink);
				}
				nodeLink.fromNode.removeLink(nodeLink);
			}
		}
				
		public function removeLink(link:Link):void {
			this.removeChild(link);
			link.fromNode.removeLink(link);
			link.toNode.removeLink(link);
		}
		
		[Bindable("nodeAdded")]
		[Bindable("nodeRemoved")]
		public function get isEmpty():Boolean {
			return this.numNodes == 0;
		}
		
		private function export(filename:String, encoder:IImageEncoder):void {
			var printCanvas:Canvas = new Canvas;
			printCanvas.width = unscaledWidth;
			printCanvas.height = unscaledHeight;
			printCanvas.y = screen.height -1;
			printCanvas.x = 0;
			var self:Canvas = this;
			var w:Number = 0;
			var h:Number = 0;
			printCanvas.addEventListener(FlexEvent.ADD, function(e:Event):void {
				for each(var ui:DisplayObject in self.getChildren()) {
					if(!(ui is Link)) {
						var bmpData:BitmapData = new BitmapData(ui.width, ui.height, true, 0XFFFFFF);
						bmpData.draw(ui);
						var image:UIComponent = new UIComponent;
						image.x = ui.x;
						image.y = ui.y;
						image.width = ui.width;
						image.height = ui.height;
						if(image.x + image.width > w) {
							w = image.x + image.width;
						}
						if(image.y + image.height > h) {
							h = image.y + image.height;
						} 
						image.graphics.beginBitmapFill(bmpData);
						image.graphics.drawRect(0, 0, image.width, image.height);
						image.graphics.endFill();
						printCanvas.addChild(image);
					}
				}
				var linksBmpData:BitmapData = new BitmapData(w, h, true, 0xFFFFFF);
				for each(ui in self.getChildren()) {
					if(ui is Link) {
						linksBmpData.draw(ui);
					}
				}
				printCanvas.width = w;
				printCanvas.height = h;
				printCanvas.validateNow();
				var printBMPData:BitmapData = new BitmapData(w, h, encoder is PNGEncoder, 0XFFFFFF);
				printBMPData.draw(linksBmpData);
				printBMPData.draw(printCanvas);
				var byteArray:ByteArray = encoder.encode(printBMPData);
				var file:FileReference = new FileReference();
				//file.save(byteArray, filename);
				try {
					PopUpManager.removePopUp(printCanvas);
				}catch(err:Error) {
					trace(err.message);
				}
			}, false, 0, true);
			PopUpManager.addPopUp(printCanvas, this);
		}
				
		public function exportToJpeg(filename:String="diagram.jpeg"):void {
			this.export(filename, new JPEGEncoder);
		}		
		
		public function exportToPng(filename:String="diagram.png"):void {
			this.export(filename, new PNGEncoder);
		}		
		
	}
}