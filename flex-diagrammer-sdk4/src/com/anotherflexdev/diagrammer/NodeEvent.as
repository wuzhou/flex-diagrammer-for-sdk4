package com.anotherflexdev.diagrammer {
	import flash.events.Event;

	public class NodeEvent extends Event {
		
		public var node:BaseNode;
		
		public function NodeEvent(type:String, node:BaseNode, bubbles:Boolean=false, cancelable:Boolean=false) {
			super(type, bubbles, cancelable);
		}
		
	}
}