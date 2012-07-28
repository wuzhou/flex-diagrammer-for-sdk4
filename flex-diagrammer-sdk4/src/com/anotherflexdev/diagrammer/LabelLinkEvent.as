package com.anotherflexdev.diagrammer {
	import flash.events.Event;

	public class LabelLinkEvent extends Event {
		public static const LABEL_LINK:String = "labelLink";
		public var value:String;
		
		public function LabelLinkEvent(value:String) {
			super(LABEL_LINK);
			this.value = value;
		}
		
	}
}