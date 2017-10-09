// Copyright (c) 2017 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.2
import QtQuick.Controls 1.2
import QtQuick.Layouts 1.1
import QtQuick.Controls.Styles 1.1

import UM 1.0 as UM
import Cura 1.0 as Cura

Item {
    id: sliderRoot

    // handle properties
    property real handleSize: 10
    property real handleRadius: handleSize / 2
    property real minimumRangeHandleSize: handleSize / 2
    property color upperHandleColor: "black"
    property color lowerHandleColor: "black"
    property color rangeHandleColor: "black"
    property real handleLabelWidth: width

    // track properties
    property real trackThickness: 4 // width of the slider track
    property real trackRadius: trackThickness / 2
    property color trackColor: "white"
    property real trackBorderWidth: 1 // width of the slider track border
    property color trackBorderColor: "black"

    // value properties
    property real maximumValue: 100
    property real minimumValue: 0
    property real minimumRange: 0 // minimum range allowed between min and max values
    property bool roundValues: true
    property real upperValue: maximumValue
    property real lowerValue: minimumValue

    property bool layersVisible: true

    function getUpperValue () {
        return upperHandle.getValue()
    }

    function setUpperValue (value) {
        upperHandle.setValue(value)
        updateRangeHandle()
    }

    function getLowerValue () {
        return lowerHandle.getValue()
    }

    function setLowerValue (value) {
        lowerHandle.setValue(value)
        updateRangeHandle()
    }

    function updateRangeHandle () {
        rangeHandle.height = lowerHandle.y - (upperHandle.y + upperHandle.height)
    }

    // slider track
    Rectangle {
        id: track

        width: sliderRoot.trackThickness
        height: sliderRoot.height - sliderRoot.handleSize
        radius: sliderRoot.trackRadius
        anchors.centerIn: sliderRoot
        color: sliderRoot.trackColor
        border.width: sliderRoot.trackBorderWidth
        border.color: sliderRoot.trackBorderColor
        visible: sliderRoot.layersVisible
    }

    // Range handle
    Item {
        id: rangeHandle

        y: upperHandle.y + upperHandle.height
        width: sliderRoot.handleSize
        height: sliderRoot.minimumRangeHandleSize
        anchors.horizontalCenter: sliderRoot.horizontalCenter
        visible: sliderRoot.layersVisible

        // set the new value when dragging
        // the range slider is only dragged when the upper and lower sliders collide
        function onHandleDragged () {
            upperHandle.y = y - upperHandle.height
            lowerHandle.y = y + height

            var upperValue = sliderRoot.getUpperValue()
            var lowerValue = upperValue - (sliderRoot.upperValue - sliderRoot.lowerValue)

            // update the Python values
            // TODO: improve this?
            UM.LayerView.setCurrentLayer(upperValue)
            UM.LayerView.setMinimumLayer(lowerValue)
        }

        Rectangle {
            width: sliderRoot.trackThickness - 2 * sliderRoot.trackBorderWidth
            height: parent.height + sliderRoot.handleSize
            anchors.centerIn: parent
            color: sliderRoot.rangeHandleColor
        }

        MouseArea {
            anchors.fill: parent

            drag {
                target: parent
                axis: Drag.YAxis
                minimumY: upperHandle.height
                maximumY: sliderRoot.height - (parent.heigth + lowerHandle.height)
            }

            onPositionChanged: parent.onHandleDragged()
        }
    }

    // Upper handle
    Rectangle {
        id: upperHandle

        y: sliderRoot.height - (sliderRoot.minimumRangeHandleSize + 2 * sliderRoot.handleSize)
        width: sliderRoot.handleSize
        height: sliderRoot.handleSize
        anchors.horizontalCenter: sliderRoot.horizontalCenter
        radius: sliderRoot.handleRadius
        color: sliderRoot.upperHandleColor
        visible: sliderRoot.layersVisible

        function onHandleDragged () {

            // don't allow the lower handle to be heigher than the upper handle
            if (lowerHandle.y - (y + height) < sliderRoot.minimumRangeHandleSize) {
                lowerHandle.y = y + height + sliderRoot.minimumRangeHandleSize
            }

            // update the rangle handle
            sliderRoot.updateRangeHandle()

            // TODO: improve this?
            UM.LayerView.setCurrentLayer(getValue())
        }

        // get the upper value based on the slider position
        function getValue () {
            var result = y / (sliderRoot.height - (2 * sliderRoot.handleSize + sliderRoot.minimumRangeHandleSize))
            result = sliderRoot.maximumValue + result * (sliderRoot.minimumValue - (sliderRoot.maximumValue - sliderRoot.minimumValue))
            result = sliderRoot.roundValues ? Math.round(result) : result
            return result
        }

        // set the slider position based on the upper value
        function setValue (value) {
            var diff = (value - sliderRoot.maximumValue) / (sliderRoot.minimumValue - sliderRoot.maximumValue)
            var newUpperYPosition = Math.round(diff * (sliderRoot.height - (2 * sliderRoot.handleSize + sliderRoot.minimumRangeHandleSize)))
            y = newUpperYPosition

            // update the rangle handle
            sliderRoot.updateRangeHandle()

            // TODO: improve this?
            UM.LayerView.setCurrentLayer(getValue())
        }

        // dragging
        MouseArea {
            anchors.fill: parent

            drag {
                target: parent
                axis: Drag.YAxis
                minimumY: 0
                maximumY: sliderRoot.height - (2 * sliderRoot.handleSize + sliderRoot.minimumRangeHandleSize)
            }

            onPositionChanged: parent.onHandleDragged()
        }

        LayerSliderLabel {
            id: upperHandleLabel

            height: sliderRoot.handleSize + UM.Theme.getSize("default_margin").height
            x: parent.x - width - UM.Theme.getSize("default_margin").width
            anchors.verticalCenter: parent.verticalCenter
            target: Qt.point(sliderRoot.width, y + height / 2)
            visible: sliderRoot.layersVisible

            // custom properties
            maximumValue: sliderRoot.maximumValue
            value: sliderRoot.getUpperValue()
            busy: UM.LayerView.busy
            setValue: sliderRoot.setUpperValue // connect callback functions
        }
    }

    // Lower handle
    Rectangle {
        id: lowerHandle

        y: sliderRoot.height - sliderRoot.handleSize
        width: parent.handleSize
        height: parent.handleSize
        anchors.horizontalCenter: parent.horizontalCenter
        radius: sliderRoot.handleRadius
        color: sliderRoot.lowerHandleColor

        visible: slider.layersVisible

        function onHandleDragged () {

            // don't allow the upper handle to be lower than the lower handle
            if (y - (upperHandle.y + upperHandle.height) < sliderRoot.minimumRangeHandleSize) {
                upperHandle.y = y - (upperHandle.heigth + sliderRoot.minimumRangeHandleSize)
            }

            // update the range handle
            rangeHandle.height = y - (upperHandle.y + upperHandle.height)

            // TODO: improve this?
            UM.LayerView.setMinimumLayer(getValue())
        }

        // get the lower value from the current slider position
        function getValue () {
            var result = (y - (sliderRoot.handleSize + sliderRoot.minimumRangeHandleSize)) / (sliderRoot.height - (2 * sliderRoot.handleSize + sliderRoot.minimumRangeHandleSize));
            result = sliderRoot.maximumValue - sliderRoot.minimumRange + result * (sliderRoot.minimumValue - (sliderRoot.maximumValue - sliderRoot.minimumRange))
            result = sliderRoot.roundValues ? Math.round(result) : result
            return result
        }

        // set the slider position based on the lower value
        function setValue (value) {
            var diff = (value - sliderRoot.maximumValue) / (sliderRoot.minimumValue - sliderRoot.maximumValue)
            var newLowerYPosition = Math.round((sliderRoot.handleSize + sliderRoot.minimumRangeHandleSize) + diff * (sliderRoot.height - (2 * sliderRoot.handleSize + sliderRoot.minimumRangeHandleSize)))
            y = newLowerYPosition

            // update the rangle handle
            sliderRoot.updateRangeHandle()

            // TODO: improve this?
            UM.LayerView.setMinimumLayer(getValue())
        }

        // dragging
        MouseArea {
            anchors.fill: parent

            drag {
                target: parent
                axis: Drag.YAxis
                minimumY: upperHandle.height + sliderRoot.minimumRangeHandleSize
                maximumY: sliderRoot.height - parent.height
            }

            onPositionChanged: parent.onHandleDragged()
        }

        LayerSliderLabel {
            id: lowerHandleLabel

            height: sliderRoot.handleSize + UM.Theme.getSize("default_margin").height
            x: parent.x - width - UM.Theme.getSize("default_margin").width
            anchors.verticalCenter: parent.verticalCenter
            target: Qt.point(sliderRoot.width, y + height / 2)
            visible: sliderRoot.layersVisible

            // custom properties
            maximumValue: sliderRoot.maximumValue
            value: sliderRoot.getLowerValue()
            busy: UM.LayerView.busy
            setValue: sliderRoot.setLowerValue // connect callback functions
        }
    }
}
