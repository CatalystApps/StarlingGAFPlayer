This example is require Flash Player 15.0.0 and higher.

In order to compile this example and make it work correctly you have to use AIR SDK 15 and higher.

This example is using following libraries:
- GAF 4.0
- Starling 1.6
- Feathers 2.0.1

SWF source file was converted into GAF format by Standalone GAF Converter version 4.0

///////////////////////////////////////////////////

GAF Converter conversion settings:

☑ Compress *.Gaf
Conversion source: Main Timeline
Conversion mode: nesting

☑ Limit max bake scale = 1
Atlas max size: 2048x2048

Scale settings:
☑ Advanced
Scale = 0.4
CSF = 1

* Source fla file was originally designed for mobile devices with Full HD resolution (1920x1080). For web preview it is to big so that is why Scale = 0.4 is used. Web preview resolution is 768x432

* Limit max bake scale = 1 is used to decrease texture atlas size. Purple background, yellow glow behind slot machine and some other parts are baked in texture atlas in smaller size than they are used in animation. Upper scaling for that parts doesn't cause pixelation effect.

* Conversion mode "nesting" is used to save internal structure of the SWF animation in converted GAF asset. Internal timelines are managed by game code.
