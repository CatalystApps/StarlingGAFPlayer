Starling GAF Player
=================

What is Starling GAF Player?
-----------------

Starling GAF Player is an ActionScript 3 library that allows developer easily to playback animations in GAF format using [Starling][1] framework.


What is GAF?
-----------------

GAF is a technology that allows porting animations created in Flash Pro into an open format GAF and play them in different popular frameworks, such as Starling, Unity3d, Cocos2d-x and other. [More info...][2]

What are the main features of GAF?
-----------------
* Designed as “What you see in Flash is what you get in GAF”;
* Doesn’t require additional technical knowledge from animators, designers and artists;
* Allows to port existing Flash Animations without special preparation before porting;
* [Supports 99% of what can be created in Flash Pro][6];
* Small size due to storing only unique parts of the animation in a texture atlas and a highly compressed binary config file describing object positions and transformations;
* High performance due to numerous optimizations in conversion process and optimized playback libraries;

What are the integral parts of GAF?
-----------------

GAF consist of [SWF to GAF Converter][3], [GAF Format][4], and [GAF Playback Libraries][5].

What is SWF to GAF Converter?
-----------------

GAF Converter is a tool for conversion animations from the SWF files into the [GAF format][4]. It is available as [standalone application GAF Converter][7], Unity GAF Converter and GAF Publisher for Flash Pro. [More info…][3]

What is GAF Format?
-----------------

GAF stands for Generic Animation Format. It is an extended cut-out animation format. It was designed to store animations, converted from SWF format into open format, that can be played using any framework/technology on any platform. [More info…][4]

How do I create GAF animation?
-----------------

Use Flash Pro to create an animation in a way that you familiar with. There is no restrictions on document structure. Then you have to convert your animation using [Standalone GAF Converter][7].

What are the supported features of Flash Pro?
-----------------

GAF Converter can convert 99% of what can be done in Flash Pro. Vector and Raster graphics; Classic, Motion, Shape and Path(Guide) Tweens; Masks; Filters and [more…][6]

How does the conversion work?
-----------------

GAF Converter has two conversion modes: Plain and Nesting. Each mode is suited for certain tasks and has its own features. [More info…][8]

Where I can find examples of using GAF?
-----------------

You can find several demo projects in demo directory [here][9].

Links and resources:
-----------------

* [Official Homepage][10]
* [GAF documentation][13]
* [FAQ page][11]
* [Starling GAF library API Reference][12]

Distribution includes [Starling library][4] binary that is licensed under [Simplified BSD License][5]

[1]: http://www.starling-framework.org
[2]: http://gafmedia.com/documentation/what-is-gaf
[3]: http://gafmedia.com/documentation/what-is-gaf-converter
[4]: http://gafmedia.com/documentation/what-is-gaf-format
[5]: http://gafmedia.com/documentation/what-is-gaf-playback-library
[6]: http://gafmedia.com/documentation/supported-features-of-the-flash-pro
[7]: http://gafmedia.com/documentation/standalone/overview
[8]: http://gafmedia.com/documentation/how-does-the-conversion-work
[9]: https://github.com/CatalystApps/StarlingGAFPlayer/tree/master/demo
[10]: http://gafmedia.com
[11]: http://gafmedia.com/faq
[12]: http://gafmedia.com/docs/starling/trunk/index.html
[13]: http://gafmedia.com/documentation

