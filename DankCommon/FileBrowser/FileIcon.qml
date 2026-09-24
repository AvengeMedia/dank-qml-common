pragma ComponentBehavior: Bound

import QtQuick
import qs.DankCommon.Common
import qs.DankCommon.Widgets

Item {
    id: root

    property string iconName: ""
    property string thumbnail: ""
    property int size: Style.iconSize
    property color color: Style.surfaceText

    readonly property string themeIconPath: Paths.resolveIconPath(iconName)
    readonly property real devicePixelRatio: Window.window?.devicePixelRatio ?? Screen.devicePixelRatio
    readonly property int rasterSize: Style.iconRasterSize(size * devicePixelRatio)

    implicitWidth: size
    implicitHeight: size

    function glyphFor(name) {
        switch (true) {
        case name.startsWith("folder"):
        case name.startsWith("user-"):
        case name === "inode-directory":
            return "folder";
        case name === "inode-symlink":
            return "link";
        case name === "emblem-unreadable":
        case name === "lock":
            return "lock";
        case name.startsWith("drive-removable"):
            return "usb";
        case name.startsWith("drive-"):
            return "hard_drive";
        case name === "media-optical":
            return "album";
        case name === "multimedia-player":
        case name === "phone":
            return "smartphone";
        case name === "camera-photo":
            return "photo_camera";
        case name === "application-pdf":
            return "picture_as_pdf";
        case name.startsWith("image"):
            return "image";
        case name.startsWith("video"):
            return "movie";
        case name.startsWith("audio"):
            return "music_note";
        case name.startsWith("text"):
            return "description";
        case name.startsWith("application-x-executable"):
        case name.startsWith("application-x-shellscript"):
            return "terminal";
        case name.startsWith("application-zip"):
        case name.startsWith("application-gzip"):
        case name.startsWith("application-zstd"):
        case name.startsWith("application-x-7z"):
        case name.startsWith("application-x-tar"):
            return "folder_zip";
        default:
            return "draft";
        }
    }

    Image {
        anchors.fill: parent
        visible: root.thumbnail !== ""
        source: root.thumbnail === "" ? "" : FilePaths.toFileUrl(root.thumbnail)
        sourceSize.width: root.rasterSize
        sourceSize.height: root.rasterSize
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        cache: true
        smooth: true
    }

    DankSVGIcon {
        anchors.fill: parent
        visible: root.thumbnail === "" && root.themeIconPath !== ""
        source: root.themeIconPath
        size: root.size
    }

    DankIcon {
        anchors.centerIn: parent
        visible: root.thumbnail === "" && root.themeIconPath === ""
        name: root.glyphFor(root.iconName)
        size: root.size
        color: root.color
    }
}
