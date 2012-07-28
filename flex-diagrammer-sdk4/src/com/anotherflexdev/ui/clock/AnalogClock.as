package com.anotherflexdev.ui.clock {

	import flash.display.*;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.utils.Timer;
	
	import mx.binding.utils.BindingUtils;
	import mx.controls.Image;
	import mx.controls.Label;
	import mx.core.*;
	import mx.formatters.DateFormatter;

	[IconFile("AnalogClock.png")]
	public class AnalogClock extends UIComponent {
	  
	  private var _date:Date;
	  public var dateFormatter:DateFormatter;
	  private var dial:Shape;
	  private var hoursHand:Image;
	  private var minutesHand:Shape;
	  private var secondsHand:Shape;
	  public var dayLabel:Label;
	  private var clockImage:Image;
	  [Embed(source='./clock-daynum.png')]
	  public var clockImg:Class;
	  [Embed(source='./sun-clock-daynum.png')]
	  public var sunClockImg:Class;
	  [Embed(source='./moon-clock-daynum.png')]
	  public var moonClockImg:Class;
	  private var timer:Timer;
	  public var sunriseTime:Date = new Date(0,0,0,7,0);
	  public var sunsetTime:Date = new Date(0,0,0,19,0);
	  [Bindable] public var showSunSetAndRiseImage:Boolean = true;
	  [Bindable] public var showDay:Boolean = true;
	  public var handsAxis:Point;
	  public var hourHandLength:Number = 0;
	  public var minuteHandLength:Number = 0;
	  
	  public function set date(value:Date):void {
	  	if(value) {
	  		this._date = value;
	  	} else {
	  		resetClock();
	  	}
	  	if(!timer) {
	  		createTimer();
	  	}
	  	if(timer && !timer.running) {
	  		timer.start();
	  	}
	  }
	  
	  public function get date():Date {
	  	return this._date;
	  }
	
	  override protected function createChildren():void {
	    super.createChildren();
	    if (!dial) {
	      dial = new Shape();
	      addChild(dial);
	    }
	
	    if (!hoursHand) {
	      hoursHand = new Image();
	      addChild(hoursHand);
	    }
	
	    if (!minutesHand) {
	      minutesHand = new Shape();
	      addChild(minutesHand);
	    }
	
	    if (!secondsHand) {
	      secondsHand = new Shape();
	      addChild(secondsHand);
	    }
	    
	    if(!dayLabel) {
	      dayLabel = new Label();
	      dayLabel.height = 15;
	      dayLabel.width = 15;
	      dayLabel.setStyle("fontWeight", "bold");
	      dayLabel.setStyle("fontSize", "7");
	      dayLabel.x = 74;
	      dayLabel.y = 44;
	      BindingUtils.bindProperty(dayLabel, "visible", this, "showDay");
	      addChild(dayLabel);
	    } else {
	      addChild(dayLabel);
	      BindingUtils.bindProperty(dayLabel, "visible", this, "showDay");
	    }
		
		if(!date) {
			resetClock();
		}
		
		if(!dateFormatter) {
			dateFormatter = new DateFormatter();
			dateFormatter.formatString = "DD";
		}
		
		if(!clockImage) {
			clockImage = new Image;
			var normalBMP:Bitmap = new this.clockImg(); 
			clockImage.source = normalBMP;
			clockImage.width = normalBMP.width;
			clockImage.height = normalBMP.height;
			addChildAt(clockImage, 0);
		}
		
	  }
	  
	  private function resetClock():void {
  		var dt:Date = new Date;
  		dt.setHours(0);
  		dt.setMinutes(0);
  		dt.setSeconds(0);
  		dt.setDate(1);
  		this._date = dt;
	  }
	
	  override protected function measure():void {
	    measuredWidth = this.clockImage.width;
	    measuredHeight = this.clockImage.height;
	  }
	
	  override protected function updateDisplayList(width:Number, height:Number):void {
	    super.updateDisplayList(width, height);
	    drawHands(width, height);
	    positionHands(date);
	    if(showDay) {
			dayLabel.text = dateFormatter.format(this.date);
	    }
		
		sunriseTime.setFullYear(this.date.fullYear, this.date.month, this.date.date);
		sunsetTime.setFullYear(this.date.fullYear, this.date.month, this.date.date);
		if(showSunSetAndRiseImage) {
			if(this.date >= sunriseTime && this.date < sunsetTime && !(this.clockImage.source is this.sunClockImg)) {
				var sunBMP:Bitmap = new this.sunClockImg();
				this.clockImage.source = sunBMP;
				clockImage.width = sunBMP.width;
				clockImage.height = sunBMP.height;
			} else if((this.date < sunriseTime || this.date >= sunsetTime) && !(this.clockImage.source is this.moonClockImg)) {
				var moonBMP:Bitmap = new this.moonClockImg();
				this.clockImage.source = moonBMP;
				clockImage.width = moonBMP.width;
				clockImage.height = moonBMP.height;
			}
		} else if(!(this.clockImage.source is this.clockImg)) {
			var normalBMP:Bitmap = new this.clockImg();
			this.clockImage.source = normalBMP;
			clockImage.width = normalBMP.width;
			clockImage.height = normalBMP.height;
		}
	  }
	
	  private function drawHands(width:Number, height:Number):void {
	  	if(!handsAxis) {
		    hoursHand.x = minutesHand.x = secondsHand.x = width / 2;
		    hoursHand.y = minutesHand.y = secondsHand.y = height / 2;
	  	} else {
		    hoursHand.x = minutesHand.x = secondsHand.x = this.handsAxis.x;
		    hoursHand.y = minutesHand.y = secondsHand.y = this.handsAxis.y;
	  	}
	
	    var g:Graphics;
	    g = hoursHand.graphics;
	    g.clear();
	    g.beginFill(0);
	    if(hourHandLength != 0) {
		    g.drawRect(-1, 2, 2, hourHandLength);
	    } else {
		    g.drawRect(-1, 2, 2, (height / 2) - 25);
	    }
    	g.endFill();
	
	    g = minutesHand.graphics;
	    g.clear();
	    g.beginFill(0);
		if(minuteHandLength != 0){
		    g.drawRect(-0.5, 2, 1, minuteHandLength);
		} else {
		    g.drawRect(-0.5, 2, 1, (height / 2) - 15);
		}
	    g.endFill();
	
	    g = secondsHand.graphics;
	    g.clear();
	    g.beginFill(0xFF0000);
		if(minuteHandLength != 0){
		    g.drawRect(-0.5, 2, 1, minuteHandLength);
		} else {
		    g.drawRect(-0.5, 2, 1, (height / 2) - 15);
		}
	    g.endFill();
	  }
	  
	  private function positionHands(time:Date):void {
	    hoursHand.rotation = ((time.getHours() % 12) + (1/60 * time.getMinutes())) / 12 * 360 + 180;
	    minutesHand.rotation = time.getMinutes() / 60 * 360 + 180;
	    secondsHand.rotation = time.getSeconds() / 60 * 360 + 180;
	  }
	 
	  private function createTimer():void {
	    timer = new Timer(1000);
	    timer.addEventListener(TimerEvent.TIMER, function(event:Event):void {
	      date = new Date(date.time + 1000);
	      invalidateDisplayList();
	    });
	  }
	  
	}

}
