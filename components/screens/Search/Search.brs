' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********
' inits search
' creates all children
' sets all observers
function Init()
    ? "[Search] Init"

    m.keyboard = m.top.findNode("Keyboard")
    m.gridScreen = m.top.findNode("Grid")

    m.videoTitle = m.top.findNode("VideoTitle")
    m.videoTitle.text = ""

    if (m.global.inline_title_text_display = true)
        m.gridScreen.itemComponentName = "SearchScreenItem"
        m.gridScreen.itemSize = [1327, 262]
        m.videoTitle.visible = false
    end if

    m.gridScreen.content = invalid

    m.detailsScreen = m.top.findNode("SearchDetailsScreen")
    m.resultsText = m.top.findNode("resultsText")

    m.keyboard.textEditBox.textColor = "0x777777"
    m.top.observeField("visible", "OnTopVisibilityChange")
    m.top.observeField("rowItemSelected", "OnRowItemSelected")

    ' Set theme
    m.AppBackground = m.top.findNode("AppBackground")
    m.AppBackground.color = m.global.theme.background_color

    m.keyboard.keyColor = m.global.theme.primary_text_color
    m.keyboard.focusedKeyColor = m.global.brand_color

    m.gridScreen.focusBitmapUri = m.global.theme.focus_grid_uri
    m.VideoTitle.color = m.global.theme.primary_text_color

    m.resultsString = m.top.findNode("ResultsString")
    m.resultsString.color = m.global.theme.secondary_text_color
end function

function OnRowItemSelected()
    ' On select any item on home scene, show Details node and hide Grid
    m.gridScreen.visible = false
    m.detailsScreen.content = m.top.focusedContent
    m.detailsScreen.setFocus(true)
    m.detailsScreen.visible = true
    m.detailsScreen.IsOptionsLabelVisible = "false"
    m.detailsScreen.autoplay = false

    m.top.isChildrensVisible = true
end function

' handler of focused item in RowList
sub OnItemFocused()
    itemFocused = m.top.itemFocused
    ' item focused should be an intarray with row and col of focused element in RowList
    if itemFocused.Count() = 2 then
        focusedContent = m.top.content.getChild(itemFocused[0]).getChild(itemFocused[1])
        if focusedContent <> invalid then
            m.top.focusedContent = focusedContent

            ? "print: ", focusedContent
            m.videoTitle.text = focusedContent.title
        end if
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    ? ">>> Search >> onKeyEvent"
    result = false
    if press then
        ? "key == "; key
        if key = "down" then
            if m.gridScreen.content <> invalid then m.gridScreen.setFocus(true)
            result = true
        else if key = "up" then
            m.keyboard.setFocus(true)
            result = true
        else if key = "options" then
            result = true
        else if key = "back"
            ' if Details opened
            if m.gridScreen.visible = false and m.detailsScreen.videoPlayerVisible = false then
                m.detailsScreen.visible = false
                m.gridScreen.setFocus(true)
                m.gridScreen.visible = true
                m.top.isChildrensVisible = false
                result = true

                ' if video player opened
            else if m.detailsScreen.videoPlayerVisible = true then
                m.detailsScreen.videoPlayerVisible = false
                result = true
            end if

        end if
    end if


    if not press then
        ? "press: "; press
        if key = "back"
            ' if HomeScene.Details opened
            if m.gridScreen.visible = false and m.detailsScreen.videoPlayerVisible = false then
                itemFocused = m.top.itemFocused

                m.detailsScreen.visible = false
                m.gridScreen.setFocus(true)

                m.gridScreen.jumpToRowItem = itemFocused

                m.gridScreen.visible = true
                m.top.isChildrensVisible = false
                result = true

                ' if video player opened
            else if m.detailsScreen.videoPlayerVisible = true then
                m.detailsScreen.videoPlayerVisible = false
                result = true
            end if

        end if
    end if

    return result
end function

sub OnTopVisibilityChange()
    if m.top.visible = true
        m.keyboard.setFocus(true)
        m.gridScreen.visible = true
    end if
end sub
