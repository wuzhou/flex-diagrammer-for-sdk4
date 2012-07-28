package com.anotherflexdev.diagrammer {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.ui.Keyboard;
	
	import mx.binding.utils.BindingUtils;
	import mx.collections.ArrayCollection;
	import mx.collections.IList;
	import mx.containers.Canvas;
	import mx.controls.Image;
	import mx.controls.Text;
	import mx.controls.TextInput;
	import mx.core.DragSource;
	import mx.core.FlexGlobals;
	import mx.core.IFactory;
	import mx.core.UIComponent;
	import mx.events.MoveEvent;
	import mx.events.ResizeEvent;
	import mx.managers.DragManager;
	import mx.styles.CSSStyleDeclaration;
	import mx.styles.IStyleManager2;
	import mx.styles.StyleManager;



	[Style(name="linkingGlowColor", type="uint", format="Color")]
	[Style(name="labelFontFamily", type="String")]
	[Style(name="labelFontSize", type="String")]
	[Style(name="labelFontColor", type="uint", format="Color")]
	public class  BaseNode extends Canvas implements DiagramElement {
		
		[Bindable] public var textMargin:Number = 1;
		[Bindable] public var nodeName:String = "No Name";
		[Bindable] public var editable:Boolean = true;
		public var customLink:IFactory;
		
		protected var lblNodeName:Text;
		public var nodeContextPanel:UIComponent;
		public var propertyPanel:UIComponent;
		
		protected var txNodeName:TextInput;
		private var linkingGlowFilter:GlowFilter;
		private var arrivingLinks:ArrayCollection;
		private var leavingLinks:ArrayCollection;
		private var canDrag:Boolean;
		
        private static var classConstructed:Boolean = classConstruct();
        
        private static function classConstruct():Boolean {
			var styleManager:IStyleManager2 = FlexGlobals.topLevelApplication.styleManager;
            return true;
        }		
		
		public function BaseNode() {
			super();
			this.clipContent = false;
			this.addEventListener(MouseEvent.MOUSE_DOWN, handleMouseDown);
			this.addEventListener(MouseEvent.MOUSE_MOVE, handleMouseMove);
			this.addEventListener(MouseEvent.ROLL_OVER, handleMouseRollOver);
			this.addEventListener(MouseEvent.ROLL_OUT, handleMouseRollOut);
			this.addEventListener(MoveEvent.MOVE, handleMove);			
			this.addEventListener(ResizeEvent.RESIZE, handleResize);
			this.addEventListener(MouseEvent.CLICK, handleClick);
						
			this.arrivingLinks = new ArrayCollection;
			this.leavingLinks = new ArrayCollection;
			this.minWidth = 50;
		}
		
		override protected function createChildren():void {
			super.createChildren();
			if(!this.lblNodeName) {
				this.lblNodeName = new Text;
				BindingUtils.bindProperty(this.lblNodeName, "text", this, "nodeName");
				this.lblNodeName.setStyle("verticalCenter", 0);
				this.lblNodeName.selectable = false;
				this.lblNodeName.setStyle("textAlign","center"); 
				this.lblNodeName.setStyle("fontWeight","bold");
			}
			this.addChild(this.lblNodeName);
			this.lblNodeName.addEventListener(MouseEvent.CLICK, handleLblNodeNameClick);
			if(!this.txNodeName) {
				this.txNodeName = new TextInput;
				this.txNodeName.maxWidth = 150;
				this.txNodeName.setStyle("horizontalCenter", 0);
			}
			this.txNodeName.addEventListener(KeyboardEvent.KEY_UP, handleTxNodeNameKeyUp);
			if(!this.nodeContextPanel) {
				this.nodeContextPanel = new NodeContextPanel;
			}
			this.nodeContextPanel.addEventListener(MouseEvent.ROLL_OVER, handleMouseRollOver);
			this.nodeContextPanel.addEventListener(MouseEvent.ROLL_OUT, handleMouseRollOut);
			this.nodeContextPanel.addEventListener("removeNode", handleRemoveNode);
			this.nodeContextPanel.addEventListener("linkNode", handleLinkNode);
			if(!this.linkingGlowFilter){
				this.linkingGlowFilter = new GlowFilter;
				this.linkingGlowFilter.blurX = 12; 
				this.linkingGlowFilter.blurY = 9;
			}
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			this.lblNodeName.x = this.textMargin;
			this.lblNodeName.width = this.width - this.textMargin * 2;
			this.lblNodeName.setStyle("fontFamily", this.getStyle("labelFontFamily"));
			this.lblNodeName.setStyle("fontSize", this.getStyle("labelFontSize"));
			this.lblNodeName.setStyle("color",this.getStyle("labelFontColor"));
			this.lblNodeName.setStyle("fontWeight",this.getStyle("labelFontWeight"));
			this.txNodeName.y = this.lblNodeName.y; 
			
			this.linkingGlowFilter.color = this.getStyle("linkingGlowColor");
			//Draw a trasparent rectangle for correct behavior of roll_over event
			this.graphics.beginFill(0xFFFFFF, 0.0);
			this.graphics.drawRect(0, 0, this.width, this.height);
			super.updateDisplayList(unscaledWidth, unscaledHeight);
		}
		
		private function handleRemoveNode(event:Event):void {
			var diagram:Diagram = Diagram(parent);
			if(diagram.contains(this.nodeContextPanel)) {
				this.nodeContextPanel.removeEventListener(MouseEvent.ROLL_OUT, handleMouseRollOut);
				diagram.removeChild(this.nodeContextPanel);
			}
			diagram.removeNode(this);
		}
		
		private function handleLinkNode(event:MouseEvent):void {
			Diagram(parent).beginLink(this);
		}
		
		private function handleMove(event:MoveEvent):void {
			redrawLinks();
		}
		
		private function redrawLinks():void {
			var linkNumMap:Object = new Object;
			for each(var arrivingLink:Link in this.arrivingLinks) {
				var i:Number = linkNumMap[arrivingLink.fromNode];
				if(isNaN(i)) i = 0;
				arrivingLink.linkNum = ++i;
				arrivingLink.invalidateDisplayList();
				linkNumMap[arrivingLink.fromNode] = i;
			}
			for each(var leavingLink:Link in this.leavingLinks) {
				i= linkNumMap[leavingLink.toNode];
				if(isNaN(i)) i = 0;
				leavingLink.linkNum = ++i;
				leavingLink.invalidateDisplayList();
				linkNumMap[leavingLink.toNode] = i;
			}
		}
		
		private function handleMouseClick(event:MouseEvent):void {
			if(Diagram(parent).isLinking) {
				this.filters = null;
				this.removeEventListener(MouseEvent.CLICK, handleMouseClick);
				Diagram(parent).endLink();
			}
		}
		
		
		private function handleMouseDown(event:MouseEvent):void {
			this.canDrag = true;
		}
		
		private function handleMouseMove(event:MouseEvent):void {
			if(canDrag && !DragManager.isDragging && event.buttonDown) {
				doDrag(event);
			}
		}
		
		private function doDrag(event:MouseEvent):void {
			this.canDrag = false;
			this.currentState = null;
			var initiator:UIComponent = this;
			var dragImg:Image = new Image();  
			
			var UIBData:BitmapData = new BitmapData(this.width, this.height, true, 0xFFFFFF);
			var UIMatrix:Matrix = new Matrix();
			UIBData.draw(this, UIMatrix);  
			dragImg.source = new Bitmap(UIBData);  
			  
			var dsource:DragSource = new DragSource();
			dsource.addData(this, 'node');
			dsource.addData(this.mouseX, 'mouseX');
			dsource.addData(this.mouseY, 'mouseY');
			parent.addChild(dragImg);
			DragManager.doDrag(initiator, dsource, event, dragImg);
		}	
		
		private function handleResize(event:ResizeEvent):void {
			this.nodeContextPanel.y = this.y + ((this.height / 2) - (this.nodeContextPanel.height / 2));
			this.nodeContextPanel.x = this.x + (this.width - 10);
			this.redrawLinks();
		}
					
		private function handleClick(event:MouseEvent):void {
			if(this.propertyPanel != null && !Diagram(parent).contains(this.propertyPanel) && !Diagram(parent).isLinking) {
				this.propertyPanel.y = this.y + ((this.height / 2) - (this.propertyPanel.height / 2));
				this.propertyPanel.x = this.x + (this.width - 10);
				Diagram(parent).addChild(this.propertyPanel);
				systemManager.addEventListener(MouseEvent.CLICK, handleSysManagerClick, true);
			}
		}
		
		private function handleSysManagerClick(event:MouseEvent):void {
			if(this.propertyPanel != null && !this.propertyPanel.hitTestPoint(event.stageX, event.stageY)) {
				systemManager.removeEventListener(MouseEvent.CLICK, handleSysManagerClick, true);
				if(Diagram(parent).contains(this.propertyPanel)) {
					Diagram(parent).removeChild(this.propertyPanel);
				}
			}
		}
		
		private function handleMouseRollOver(event:MouseEvent):void {
			if(!Diagram(parent).contains(this.nodeContextPanel)) {
				this.nodeContextPanel.y = this.y + ((this.height / 2) - (this.nodeContextPanel.height / 2));
				this.nodeContextPanel.x = this.x + (this.width - 10);
				Diagram(parent).addChild(this.nodeContextPanel);
			}
			if(Diagram(parent).isLinking) {
				this.filters = [this.linkingGlowFilter];
				this.addEventListener(MouseEvent.CLICK, handleMouseClick);
			}
		}
		
		private function handleMouseRollOut(event:MouseEvent):void {
			if(Diagram(parent).contains(this.nodeContextPanel)) {
				Diagram(parent).removeChild(this.nodeContextPanel);
			}
			if(Diagram(parent).isLinking) {
				this.filters = null;
				this.removeEventListener(MouseEvent.CLICK, handleMouseClick);
			}
		}			
			
		private function editNodeName():void {
			this.txNodeName.text = this.nodeName;
			this.removeChild(this.lblNodeName);
			this.addChild(this.txNodeName);
			this.txNodeName.selectionBeginIndex = 0;
			this.txNodeName.selectionEndIndex = this.nodeName.length;
			this.txNodeName.setFocus();				
		}
		
		private function unEditNodeName():void {
			this.removeChild(this.txNodeName);
			this.addChild(this.lblNodeName);
		}
		
		private function handleTxNodeNameKeyUp(event:KeyboardEvent):void {
			if(event.keyCode == Keyboard.ENTER) {
				this.nodeName = this.txNodeName.text;
				unEditNodeName();
			} else if(event.keyCode == Keyboard.ESCAPE) {
				unEditNodeName();
			}
		}
		
		private function handleLblNodeNameClick(event:MouseEvent):void {
			if(!Diagram(parent).isLinking && this.editable) {
				this.editNodeName();
			}
		}
		
		public function addArrivingLink(link:Link):void {
			this.arrivingLinks.addItem(link);
			this.redrawLinks();
		}

		public function addLeavingLink(link:Link):void {
			this.leavingLinks.addItem(link);
			this.redrawLinks();
		}
		
		public function removeLink(link:Link):void {
			if(this.arrivingLinks.contains(link)) {
				this.arrivingLinks.removeItemAt(this.arrivingLinks.getItemIndex(link));
			}
			if(this.leavingLinks.contains(link)){
				this.leavingLinks.removeItemAt(this.leavingLinks.getItemIndex(link));
			}
		}
		
		public function getAllLinks():ArrayCollection {
			var result:ArrayCollection = new ArrayCollection;
			for each(var arrivingLink:Link in this.arrivingLinks) {
				result.addItem(arrivingLink);
			}
			for each(var leavingLink:Link in this.leavingLinks) {
				result.addItem(leavingLink);
			}			
			return result;
		}
		
		public function getAllLeavingLinks():IList {
			return this.leavingLinks;
		}
		
		public function getAllLeavingLinksTo(node:BaseNode):IList {
			var list:IList = new ArrayCollection;
			for each(var link:Link in this.leavingLinks) {
				if(link.toNode == node) {
					list.addItem(link);
				}
			}
			return list;
		}
		
		public function getAllArrivingLinks():IList {
			return this.arrivingLinks;
		}

		public function getAllArrivingLinksFrom(node:BaseNode):IList {
			var list:IList = new ArrayCollection;
			for each(var link:Link in this.arrivingLinks) {
				if(link.fromNode == node) {
					list.addItem(link);
				}
			}
			return list;
		}
		
		public function removeOverEvent():void{
			this.removeEventListener(MouseEvent.ROLL_OVER, handleMouseRollOver);
			this.removeEventListener(MouseEvent.ROLL_OUT, handleMouseRollOut);
		}
	}
}