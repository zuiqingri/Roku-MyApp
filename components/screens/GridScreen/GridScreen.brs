' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********
' inits grid Screen
' creates all children
' sets all observers
function Init()
    ? "[GridScreen] Init"

    m.scene = m.top.getScene()

    ' Initialize valus'
    m.value = 0
    m.index = 0

    m.rowList = m.top.findNode("RowList")
    m.description = m.top.findNode("Description")
    m.background = m.top.findNode("Background")

    m.top.observeField("visible", "onVisibleChange")
    m.top.observeField("focusedChild", "OnFocusedChildChange")
    m.carouselShow = m.top.findNode("carouselShow")
    m.sliderButton = m.top.findNode("sliderButton")
    m.sliderGroup = m.top.findNode("sliderGroup")
    ' Set theme
    m.rowList.focusBitmapUri = m.global.theme.focus_grid_uri
    m.rowList.rowLabelColor = m.global.theme.primary_text_color

    m.optionsLabel = m.top.findNode("OptionsLabel")
    m.optionsLabel.text = m.global.labels.menu_label
    m.optionsLabel.color = m.global.theme.primary_text_color

    m.optionsIcon = m.top.findNode("OptionsIcon")
    m.optionsIcon.blendColor = m.global.brand_color

    initializeVideoPlayer()
    m.top.videoPlayer.visible = false

    m.tVideoHeartBeatTimer = m.top.FindNode("tVideoHeartBeatTimer")
    m.tVideoHeartBeatTimer.observeField("fire", "OnVideoHeartBeatEventFired")
    m.tVideoHeartBeatTimer.duration = 5
end function

sub OnVideoHeartBeatEventFired()
    isSendEvent = false
    ' For Segment Analytics'
    if m.top.videoPlayer.state = "playing"
        if (m.global.enable_segment_analytics = true)
            if (m.global.segment_source_write_key <> invalid and m.global.segment_source_write_key <> "")
                if (m.top.videoPlayer.state = "playing" and m.firstTimeVideo = false)
                    isSendEvent = true
                end if
            else
                print "[HomeScene] ERROR : SEGMENT ANALYTICS > Missing Account ID. Please set 'segment_source_write_key' in config.json"
            end if
        else
            print "[HomeScene] INFO : SEGMENT ANALYTICS IS NOT ENABLED..."
        end if
    end if

    if (isSendEvent = true)
        scene = m.top.getScene()
        scene.segmentEvent = GetSegmentVideoEventInfo("playingHeartBeat")
    end if
end sub

function initializeVideoPlayer()
    print "initializeVideoPlayer"
    m.top.videoPlayer = m.top.createChild("Video")
    m.top.videoPlayer.translation = [0, 0]
    m.top.videoPlayer.width = 0
    m.top.videoPlayer.height = 0

    ' Event listener for video player state. Needed to handle video player errors and completion
    m.top.videoPlayer.observeField("state", "OnVideoPlayerStateChange")
    m.firstTimeVideo = true
end function

' event handler of Video player msg
sub OnVideoPlayerStateChange()
    live = (m.top.videoPlayer.content <> invalid and m.top.videoPlayer.content.live <> invalid and m.top.videoPlayer.content.live = true)
    ' Only close video player if error and VOD (not live stream)
    if m.top.videoPlayer.state = "error" and live = false
        ' error handling
        m.top.videoPlayer.visible = false
    else if m.top.videoPlayer.state = "playing"
        if m.top.getScene().autoplaytimer <> 2
            m.top.getScene().autoplaytimer = 1
        end if
        ' playback handling
        if(m.top.autoplay = true)
            m.top.triggerPlay = false
        end if
    else if m.top.videoPlayer.state = "finished" and live = false

        ' Try playing live stream again instead of closing by default.
        ' Video player tries to close at first sign of missing manifest chunks
    else if m.top.videoPlayer.state = "finished" and live = true
        m.top.videoPlayer.control = "play"
    end if

    isSendEvent = false
    ' For Segment Analytics'
    if m.top.videoPlayer.state = "playing" or m.top.videoPlayer.state = "finished"
        if (m.global.enable_segment_analytics = true)
            if (m.global.segment_source_write_key <> invalid and m.global.segment_source_write_key <> "")
                if (m.top.videoPlayer.state = "playing" and m.firstTimeVideo = true)
                    isSendEvent = true
                    m.firstTimeVideo = false
                    ' Start Timer for sending event periodically'
                    m.tVideoHeartBeatTimer.control = "start"
                else if (m.top.videoPlayer.state = "finished")
                    isSendEvent = true
                end if
            else
                print "[HomeScene] ERROR : SEGMENT ANALYTICS > Missing Account ID. Please set 'segment_source_write_key' in config.json"
            end if
        else
            print "[HomeScene] INFO : SEGMENT ANALYTICS IS NOT ENABLED..."
        end if
    end if

    if (isSendEvent = true)
        scene = m.top.getScene()
        scene.segmentEvent = GetSegmentVideoEventInfo(m.top.videoPlayer.state)
    end if
end sub

function GetSegmentVideoEventInfo(state as dynamic)
    eventStr = GetSegmentVideoStateEventString(state)
    app_info = CreateObject("roAppInfo")
    percent = 0
    if (m.top.videoPlayer.position <> 0 and m.top.videoPlayer.content.LENGTH <> 0) then
        percent = m.top.videoPlayer.position / m.top.videoPlayer.content.LENGTH
    end if

    episodeNumber = ""
    if (type(m.top.content.episodeNumber) = "roString" and (m.top.content.episodeNumber = "" or m.top.content.episodeNumber = "0"))
        episodeNumber = ""
    else if (type(m.top.content.episodeNumber) <> "roString")
        if (m.top.content.episodeNumber <> 0)
            episodeNumber = m.top.content.episodeNumber.tostr()
        end if
    else
        episodeNumber = m.top.content.episodeNumber
    end if

    seasonNumber = ""
    if (type(m.top.content.seasonNumber) = "roString" and (m.top.content.seasonNumber = "" or m.top.content.seasonNumber = "0"))
        seasonNumber = ""
    else if (type(m.top.content.seasonNumber) <> "roString")
        if (m.top.content.seasonNumber <> 0)
            seasonNumber = m.top.content.seasonNumber.tostr()
        end if
    else
        seasonNumber = m.top.content.seasonNumber
    end if

    created_at = "null"
    if (m.top.content.created_at <> invalid)
        if (type(m.top.content.created_at) = "roString")
            created_at = m.top.content.created_at
        end if
    end if

    published_at = "null"
    if (m.top.content.published_at <> invalid)
        if (type(m.top.content.published_at) = "roString")
            published_at = m.top.content.published_at
        end if
    end if

    updated_at = "null"
    if (m.top.content.updated_at <> invalid)
        if (type(m.top.content.updated_at) = "roString")
            updated_at = m.top.content.updated_at
        end if
    end if

    currentPosition = m.top.videoPlayer.position
    if (m.top.videoPlayer.content.on_Air = true)
        ' TODO : Check here DVR case'
        currentPosition = 0
    end if

    videoContentDuration = m.top.videoPlayer.content.LENGTH
    if (m.top.videoPlayer.content.on_Air = true)
        videoContentDuration = "null"
    end if

    videoThumbnail = "null"
    if (m.top.videoPlayer.content.HDBACKGROUNDIMAGEURL <> invalid and m.top.videoPlayer.content.HDBACKGROUNDIMAGEURL <> "") then
        videoThumbnail = m.top.videoPlayer.content.HDBACKGROUNDIMAGEURL
    else if (m.top.videoPlayer.content.HDPOSTERURL <> invalid and m.top.videoPlayer.content.HDPOSTERURL <> "") then
        videoThumbnail = m.top.videoPlayer.content.HDPOSTERURL
    end if

    videoAdDuration = "null" ' TODO
    videoAdVolume = "null" ' TODO

    properties = {
        "session_id": m.scene.uniqueSessionID 'String (autogenerated for the user's session)
        "asset_id": m.top.videoPlayer.content.id,
        "title": m.top.videoPlayer.content.TITLE,
        "description": m.top.content.DESCRIPTION, 'String (Zype video_description, if available)
        "season": seasonNumber,
        "episode": episodeNumber,
        "publisher": app_info.GetTitle(), ' "String (App name)"
        "position": currentPosition 'Integer (current playhead position)
        "total_length": m.top.videoPlayer.content.LENGTH, 'Integer (total duration of video in seconds)
        "channel": app_info.GetTitle(), ' "String (App name)"
        "livestream": m.top.videoPlayer.content.on_Air, 'Boolean (true if on_air = true)
        "airdate": m.top.videoPlayer.content.RELEASEDATE, 'ISO 8601 Date String (Zype published_at date)
        ' "bitrate":      Integer (The current kbps, if available)
        ' "framerate":    Float (The average fps, if available)

        "contentCmsCategory": "null",
        "contentShownOnPlatform": "ott",
        "streaming_device": "Roku" + " " + createObject("roDeviceInfo").getModel(),
        "videoAccountId": "416418724",
        "videoAccountName": "People",

        "videoAdDuration": videoAdDuration,
        "videoAdVolume": videoAdVolume,

        "videoContentPercentComplete": percent,

        "videoCreatedAt": created_at,
        "videoPublishedAt": published_at,
        "videoUpdatedAt": updated_at,

        "videoFranchise": "null",
        "videoId": m.top.videoPlayer.content.id,
        "videoName": m.top.videoPlayer.content.TITLE,
        "videoSyndicate": "null",
        "videoThumbnail": videoThumbnail,
        "videoContentPosition": currentPosition,
        "videoContentDuration": videoContentDuration
    }

    adType = "null" ' TODO "pre-roll" “mid-roll” or “post-roll” if known
    properties["Ad Type"] = adType

    videoTagsString = "null"
    if (m.top.content.keywords <> invalid)
        if (type(m.top.content.keywords) = "roArray" and m.top.content.keywords.Count() > 0)
            videoTagsString = ""
            videoTags = m.top.content.keywords
            videoTags.sort()
            videoTagsCount = videoTags.Count() - 1

            for i = 0 to videoTagsCount
                videoTagsString += LCase(videoTags[i])
                if (i < videoTagsCount)
                    videoTagsString += " | "
                end if
            end for
        end if
    end if
    properties["videoTags"] = videoTagsString

    trackObj = {
        "action": "track",
        "event": eventStr,
        "userId": "",
    }

    trackObj.properties = properties
    print "GridScreen trackObj : " trackObj
    print "GridScreen trackObj.properties : " trackObj.properties
    print "GridScreen trackObj.properties.videoTags : " trackObj.properties.videoTags
    return trackObj
end function

function GetSegmentVideoStateEventString(state as dynamic) as string
    eventStr = ""
    if (state = "playing")
        eventStr = "Video Content Started"
    else if (state = "playingHeartBeat")
        eventStr = "Video Content Playing"
    else if (state = "finished")
        eventStr = "Video Content Completed"
    end if

    return eventStr
end function

function ReinitializeVideoPlayer()
    print "m.top.RemakeVideoPlayer : " m.top.RemakeVideoPlayer
    print "m.top.videoPlayer : " m.top.videoPlayer
    if m.top.RemakeVideoPlayer = true
        m.top.removeChild(m.top.videoPlayer)
        initializeVideoPlayer()
    end if
end function

' handler of focused item in RowList
sub OnItemFocused()
    itemFocused = m.top.itemFocused
    ' item focused should be an intarray with row and col of focused element in RowList
    if itemFocused.Count() = 2 then
        focusedContent = m.top.content.getChild(itemFocused[0]).getChild(itemFocused[1])
        if focusedContent <> invalid then
            m.top.focusedContent = focusedContent
            m.description.content = focusedContent

            ' m.temp = focusedContent.description
            ' m.description.content.description = ""

            m.background.uri = focusedContent.hdBackgroundImageUrl
        end if
    end if
end sub

' set proper focus to RowList in case if return from Details Screen
sub onVisibleChange()
    m.description.content = m.top.focusedContent
    ' m.description.content.description = m.temp

    if m.top.visible = true then
        if m.top.heroCarouselShow = true
            m.carouselShow.visible = false
            m.sliderGroup.visible = true
            m.sliderButton.setFocus(true)
        else
            m.carouselShow.visible = true
            m.sliderGroup.visible = false
            m.rowList.setFocus(true)
        end if
    end if
end sub



' set proper focus to RowList in case if return from Details Screen
sub OnFocusedChildChange()
    if m.top.isInFocusChain() and not m.rowList.hasFocus() then
        if m.top.heroCarouselShow = true
            if m.scene.IsShowAutoPlayBackground = false and m.top.VideoPlayer.visible = false
                print "OnFocusedChildChange >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
                m.sliderButton.setFocus(true)
            end if
            m.sliderGroup.visible = true
            m.carouselShow.visible = false

            if (m.sliderTimer <> invalid)
                m.sliderTimer.control = "stop"
                m.sliderTimer.control = "start"
            end if
        else
            m.carouselShow.visible = true
            m.sliderGroup.visible = false
            m.rowList.setFocus(true)
        end if
    end if
end sub

sub showHeroCarousel()
    'for each item in m.top.heroCarouselData

    '' ?item.pictures[0]
    'end for
    m.sliderData = []
    m.index = 0
    m.sliderValuesHome = {}
    m.sliderValuesHome.height = 380
    m.sliderValuesHome.width = 923
    m.sliderValuesHome.translation1 = [-794.5, 0]
    m.sliderValuesHome.translation2 = [178.5, 0]
    m.sliderValuesHome.translation3 = [1151.5, 0]

    m.sliderFocusValuesHome = {}
    m.sliderFocusValuesHome.height = 390
    m.sliderFocusValuesHome.width = 933
    m.sliderFocusValuesHome.translation = [173.5, -6]


    m.sliderGroup.translation = [0, 5]

    m.slider1 = m.top.findNode("slider1")
    m.slider1.Height = m.sliderValuesHome.height
    m.slider1.Width = m.sliderValuesHome.width
    m.slider1.LoadHeight = m.sliderValuesHome.height
    m.slider1.LoadWidth = m.sliderValuesHome.width
    m.slider1.loadDisplayMode = "scaleToZoom"
    m.slider1.translation = m.sliderValuesHome.translation1
    m.slider1.uri = m.top.heroCarouselData[m.index].pictures[0].url

    m.index += 1
    m.value = m.index
    if m.top.heroCarouselData[m.index] = invalid
        m.index = 0
    end if
    m.slider2 = m.top.findNode("slider2")
    m.slider2.Height = m.sliderValuesHome.height
    m.slider2.Width = m.sliderValuesHome.width
    m.slider2.LoadHeight = m.sliderValuesHome.height
    m.slider2.LoadWidth = m.sliderValuesHome.width
    m.slider2.loadDisplayMode = "scaleToZoom"
    'm.slider2.loadDisplayMode="scaleToFill"
    m.slider2.translation = m.sliderValuesHome.translation2
    m.slider2.uri = m.top.heroCarouselData[m.index].pictures[0].url
    m.valueSelection = m.index

    m.index += 1
    if m.top.heroCarouselData[m.index] = invalid
        m.index = 0
    end if
    m.slider3 = m.top.findNode("slider3")
    m.slider3.Height = m.sliderValuesHome.height
    m.slider3.Width = m.sliderValuesHome.width
    m.slider3.LoadHeight = m.sliderValuesHome.height
    m.slider3.LoadWidth = m.sliderValuesHome.width
    m.slider3.loadDisplayMode = "scaleToZoom"
    'm.slider3.loadDisplayMode="scaleToFill"
    m.slider3.translation = m.sliderValuesHome.translation3
    m.slider3.uri = m.top.heroCarouselData[m.index].pictures[0].url

    m.sliderFocus = m.top.findNode("sliderFocus")
    m.sliderFocus.uri = m.global.theme.slider_focus
    m.sliderFocus.height = m.sliderFocusValuesHome.height
    m.sliderFocus.width = m.sliderFocusValuesHome.width
    m.sliderFocus.translation = m.sliderFocusValuesHome.translation

    m.sliderButton = m.top.findNode("sliderButton")
    m.sliderButton.observeField("buttonSelected", "selectSlider")
    m.sliderTimer = m.top.findNode("sliderTimer")
    m.sliderTimer.control = "start"
    m.sliderTimer.ObserveField("fire", "changeSliderImage")
end sub

sub selectSlider()
    ?m.top.heroCarouselData[m.valueSelection]
    m.top.carouselSelectData = m.top.heroCarouselData[m.valueSelection]
end sub

sub moveFocusToheroCarousel()
    m.top.moveFocusToheroCarousel = false
    m.sliderButton.setFocus(true)
    m.sliderGroup.visible = true
    m.carouselShow.visible = false
end sub

sub changeSliderImage()
    if m.top.visible and m.top.videoPlayer.visible = false
        print "============================================sliderchange==================================================>"m.index
        m.value = m.value + 1
        m.index = m.value
        if m.top.heroCarouselData[m.index] = invalid
            m.index = 0
        end if
        m.slider2.uri = m.top.heroCarouselData[m.index].pictures[0].url
        m.valueSelection = m.index
        m.value = m.index
        m.index += 1
        if m.top.heroCarouselData[m.index] = invalid
            m.index = 0
        end if
        m.slider3.uri = m.top.heroCarouselData[m.index].pictures[0].url

        m.index += 1
        if m.top.heroCarouselData[m.index] = invalid
            m.index = 0
        end if
        m.slider1.uri = m.top.heroCarouselData[m.index].pictures[0].url
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    result = false
    if press then
        if key = "back"
            m.top.getScene().autoplaytimer = 2
            if (m.top.videoPlayer.visible = true)
                m.top.videoPlayer.control = "stop"
                m.tVideoHeartBeatTimer.control = "stop"
                m.top.videoPlayer.visible = false
                if m.top.heroCarouselShow = true
                    m.sliderButton.setFocus(true)
                else
                    m.rowList.setFocus(true)
                end if
                result = true
            end if
        else if key = "down"
            if m.sliderButton.hasFocus()
                m.carouselShow.visible = true
                m.sliderGroup.visible = false
                m.rowList.setFocus(true)
                result = true
            end if
        else if key = "up"
            if m.rowList.hasFocus() and m.top.heroCarouselShow = true
                m.carouselShow.visible = false
                m.sliderGroup.visible = true
                m.sliderButton.setFocus(true)
                result = true
            end if
        else if key = "right"
            if m.sliderGroup.visible = true
                m.value = m.value + 1
                m.index = m.value
                if m.top.heroCarouselData[m.index] = invalid
                    m.index = 0
                end if
                m.slider2.uri = m.top.heroCarouselData[m.index].pictures[0].url
                m.valueSelection = m.index
                m.value = m.index
                m.index += 1
                if m.top.heroCarouselData[m.index] = invalid
                    m.index = 0
                end if
                m.slider3.uri = m.top.heroCarouselData[m.index].pictures[0].url

                m.index += 1
                if m.top.heroCarouselData[m.index] = invalid
                    m.index = 0
                end if
                m.slider1.uri = m.top.heroCarouselData[m.index].pictures[0].url

                result = true

                if (m.sliderTimer <> invalid)
                    m.sliderTimer.control = "stop"
                    m.sliderTimer.control = "start"
                end if

            end if
        else if key = "left"
            if m.sliderGroup.visible = true
                m.value = m.value - 1
                m.index = m.value
                if m.top.heroCarouselData[m.index] = invalid
                    m.index = m.top.heroCarouselData.Count() - 1
                end if
                m.slider2.uri = m.top.heroCarouselData[m.index].pictures[0].url
                m.valueSelection = m.index
                m.value = m.index
                m.index -= 1
                if m.top.heroCarouselData[m.index] = invalid
                    m.index = m.top.heroCarouselData.Count() - 1
                end if
                m.slider1.uri = m.top.heroCarouselData[m.index].pictures[0].url
                m.index -= 1
                if m.top.heroCarouselData[m.index] = invalid
                    m.index = m.top.heroCarouselData.Count() - 1
                end if
                m.slider3.uri = m.top.heroCarouselData[m.index].pictures[0].url

                result = true

                if (m.sliderTimer <> invalid)
                    m.sliderTimer.control = "stop"
                    m.sliderTimer.control = "start"
                end if

            end if
        end if
    end if
    return result
end function

' Content change handler
sub OnContentChange()
    if m.top.content <> invalid
        m.top.videoPlayer.content = m.top.content
        print "GridScreen OnContentChange ====> m.top.content : " m.top.content
    end if
end sub
