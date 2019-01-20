
This iOS app tries to resemble the advanced feature of video trim-cut module in Video Crop application. Note that, this app varies from the original feature in some aspect and code may look a bit messy.

Overview

This app is created on the basis of ICGVideoTrimmerView (third party library).
Takes a sample video from app's bundle.
The assets are generated from the sample video using AVAssetImageGenerator, set to imageview then added to scrollview.
The UI is mostly implemented in Storyboard using autolayout, i extended UISegemntedControl to have the same look and feel rather than using asset. The scrubber view is created using UIBeizierPath.
The edited videos are saved in photos. Note, to see the cut video in your photos, you have to build the application in device.


Known Issues

The scrolling scrubber is not particularly synced with the thumb videos in all cases. I am certain, i will be able to make this feature even more perfect given enough time.
The tracker view for video differs a little bit from the original feature.


Future Plan  

To achieve the functionality of syncing thumb video with scrolling scrubber.
Code refactoring.




