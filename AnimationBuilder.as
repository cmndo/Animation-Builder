/*
MIT License

Copyright (c) 2017 Aaron Sherrill

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

package {

	import flash.utils.*;
	import flash.geom.*;
	import flash.display.DisplayObject;

	public class AnimationBuilder {

		private var animations:Object = {};
		private var _targets:Object = {};
		private var _this = undefined;

		/*
			constructor
		*/
		public function AnimationBuilder(timeline, targets) {
			_this = timeline;
			_targets = targets;
		}

		/*
			private functions
		*/
		private function frameToTime(num) {
			return ((((num / _this.stage.frameRate)*100))/100)
		}

		/*
			find the percentage between the first and last frame where the current "index" is
			or if there are only 2 frames - use "from" and "to" instead of "0%" and "100%"
		*/
		private function frameToPerc(frames, index) {
			if(frames.length == 2){
				if(index == 0){
					return "from";
				}else{
					return "to";
				}
			}else{

				return 	(((frames[index].num - frames[0].num) / (frames[frames.length - 1].num - frames[0].num)) * 100) + "%"
			}
			return null;
		}

		/*
			public functions
		*/
		public function getAnchorPoint(o:DisplayObject):Object {
			var res:Object= {};
			var rect:Rectangle = o.getRect(o);
			res.x=-1*rect.x + "px";
			res.y=-1*rect.y + "px";
			return res;
		}

		/*old arguments - keyframeName:String, object:*, properties:*=undefined, ease:*=undefined*/
		public function add(keyframeName:String,properties:*= undefined, ease:*=undefined):void{

			//Establish the namespace for this group.
			if(animations[keyframeName] == undefined){
				animations[keyframeName] = {
					delay: 0,
					frames: [],
					duration: 0
				};
			}

			//Store the properties from this frame
			var tmpKeyframe:Object = {
				num: _this.currentFrame,
				props: [],
				ease: ease
			};

			//build each line of css
			//replace ^ character in value with property if it matches
			/*
				um, ok, so this is outdated. it looks great and works for the limited scope, but I want to use a really simple
				syntax and capture the object.transform.matrix properties.


				I've added in the possiblity to generate a 3D Matrix Transform if you've transformed your elements
				in 3d. I don't know if it's gonna work.
			*/

			//(a=0.8070220947265625, b=0.59051513671875, c=-0.59051513671875, d=0.8070220947265625, tx=290.95, ty=129.95)




			if (_targets[keyframeName].transform.matrix3D) {

				var matrix3d = JSON.stringify(_targets[keyframeName].transform.matrix3D.rawData);
				tmpKeyframe.props.push("transform: matrix3d("+ matrix3d.substr(1, matrix3d.length-2) +");\n");


			} else {

				var matrix = _targets[keyframeName].transform.matrix;
				tmpKeyframe.props.push("transform: matrix("+ matrix.a +","+matrix.b+","+matrix.c+","+matrix.d+","+matrix.tx+","+matrix.ty+");\n");

			}

			if(properties){
				for(var k in properties){
					if(properties[k].indexOf("^") === -1){
						tmpKeyframe.props.push(properties[k] +";\n");
					}else{
						if(k.indexOf(",") > -1) {
							var splitUp = k.split(",");
							var taint = properties[k];

							for(var l = 0; l < splitUp.length; l++) {
								if(taint.indexOf("^" + splitUp[l]) > -1) {
									taint = taint.replace("^" + splitUp[l], _targets[keyframeName][splitUp[l]]);
								}
							}

							tmpKeyframe.props.push(taint +";\n");

						} else {
							tmpKeyframe.props.push(properties[k].replace("^" , _targets[keyframeName][k]) +";\n");
						}
					}
				}
			} //end if



			//
			animations[keyframeName].frames.push(tmpKeyframe);

		}

		public function report():void {
			//loop through all the animations and pipe them through report
			for(var i in animations){
				reportSpecific(i);
			}
		}
		public function reportAll():void {
			//loop through all the animations and pipe them through report
			for(var i in animations){
				reportSpecific(i);
			}
		}
		/*
			This object now does much more lifting
			.determine animation length
			.determine delay based on when the first frame appears
		*/
		public function reportSpecific(keyframeName:String):void{

			if(animations[keyframeName].frames.length >= 2){
				var firstKeyFrame = animations[keyframeName].frames[0].num;
				var lastKeyFrame = animations[keyframeName].frames[animations[keyframeName].frames.length - 1].num;

				animations[keyframeName].duration = frameToTime(lastKeyFrame - firstKeyFrame);

				//delay is tricky cause we start at frame 1, but time starts with 0
				animations[keyframeName].delay = frameToTime(firstKeyFrame - 1);

			} else {
				return void;
			}



			// Loop through added keyframes and compile the css properties we stored.
			var reply = "@keyframes "+keyframeName+" {\n"


			for(var i in animations[keyframeName].frames){
				reply += "	" + frameToPerc(animations[keyframeName].frames, i) +" {\n";
				reply += "		" + animations[keyframeName].frames[i].props.join("		");
				reply += "		animation-timing-function: " + (animations[keyframeName].frames[i].ease || "linear") + ";\n";

				reply += "	}\n";
			}


			reply += "\n}";


			trace(reply);


			//delay the output of these 10 milliseconds for each frame (for big animations).
			setTimeout(function(){
				var implement;
				implement = "#" + _targets[keyframeName].name + " {\n";
				implement += "	animation: " + keyframeName + " " + animations[keyframeName].duration + "s infinite;\n";
				implement += "	animation-delay: " + animations[keyframeName].delay + "s;\n"
				implement += "}";
				trace(implement);

			}, animations[keyframeName].frames.length * 10);

			//END and Profit!
		}
	}
}
