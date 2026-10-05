pragma ComponentBehavior: Bound

import QtQuick
import qs.DCommon.Common
import qs.DCommon.Widgets

Item {
    id: pane

    property var entry: null
    property var backend: null
    property real imageSizeLimit: -1

    readonly property string path: entry?.path ?? ""
    readonly property string mime: entry?.mime ?? ""
    readonly property bool imageLike: mime.startsWith("image/") && (imageSizeLimit < 0 || (entry?.size ?? 0) <= imageSizeLimit)
    readonly property bool textLike: mime.startsWith("text/") || mime.startsWith("application/")
    readonly property bool canPreview: textLike && backend !== null && typeof backend.preview === "function"
    readonly property var details: ["type", "size", "modified", "created", "owner", "permissions"]

    property string text: ""
    property bool binary: false
    property bool truncated: false
    property bool loading: false
    property int request: 0

    function load() {
        text = "";
        binary = false;
        truncated = false;
        const current = ++request;
        if (!canPreview || path === "") {
            loading = false;
            return;
        }
        loading = true;
        backend.preview(path, FileBrowserMetrics.previewBytes, result => {
            if (current !== pane.request)
                return;
            pane.loading = false;
            if (result.error) {
                pane.binary = true;
                return;
            }
            pane.text = result.text ?? "";
            pane.binary = result.binary === true;
            pane.truncated = result.truncated === true;
        });
    }

    onPathChanged: debounce.restart()
    Component.onCompleted: debounce.restart()

    Timer {
        id: debounce

        interval: FileBrowserMetrics.settleInterval
        onTriggered: pane.load()
    }

    DFlickable {
        anchors.fill: parent
        anchors.margins: Style.spacingL
        contentWidth: width
        contentHeight: body.implicitHeight
        clip: true

        Column {
            id: body

            width: parent.width
            spacing: Style.spacingM

            Item {
                width: parent.width
                height: FileBrowserMetrics.previewIconSize

                Image {
                    anchors.fill: parent
                    visible: pane.imageLike
                    source: pane.imageLike ? "file://" + pane.path : ""
                    asynchronous: true
                    cache: false
                    fillMode: Image.PreserveAspectFit
                    sourceSize.width: width * 2
                    sourceSize.height: height * 2
                }

                FileItemVisual {
                    anchors.centerIn: parent
                    visible: !pane.imageLike
                    iconSize: FileBrowserMetrics.previewIconSize
                    iconName: pane.entry?.iconName ?? ""
                    thumbnail: pane.entry?.thumbnail ?? ""
                    path: pane.path
                    mime: pane.mime
                    isDir: false
                    isSymlink: pane.entry?.isSymlink ?? false
                    symlinkBroken: pane.entry?.symlinkBroken ?? false
                    untrusted: pane.entry?.untrusted ?? false
                    hidden: pane.entry?.hidden ?? false
                }
            }

            StyledText {
                width: parent.width
                text: pane.entry?.name ?? ""
                color: Style.surfaceText
                font.pixelSize: Style.fontSizeLarge
                font.weight: Style.fontWeightMedium
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WrapAnywhere
                maximumLineCount: 3
                elide: Text.ElideMiddle
            }

            Column {
                width: parent.width
                spacing: Style.spacingXS

                Repeater {
                    model: pane.details

                    Item {
                        id: detail

                        required property string modelData

                        readonly property string value: pane.entry ? FileColumns.value(modelData, pane.entry) : ""

                        width: parent.width
                        height: visible ? Math.max(label.implicitHeight, content.implicitHeight) : 0
                        visible: value !== ""

                        StyledText {
                            id: label

                            anchors.left: parent.left
                            width: parent.width * 0.4
                            text: FileColumns.label(detail.modelData)
                            color: Style.surfaceVariantText
                            font.pixelSize: Style.fontSizeSmall
                            elide: Text.ElideRight
                        }

                        StyledText {
                            id: content

                            anchors.left: label.right
                            anchors.leftMargin: Style.spacingS
                            anchors.right: parent.right
                            text: detail.value
                            color: Style.surfaceText
                            font.pixelSize: Style.fontSizeSmall
                            wrapMode: Text.WrapAnywhere
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: Style.dividerWidth
                visible: pane.canPreview
                color: Style.outlineVariant
            }

            StyledText {
                width: parent.width
                visible: pane.canPreview && !pane.loading && (pane.binary || pane.truncated)
                text: pane.binary ? I18n.tr("Binary file", "preview column note for files without readable text") : I18n.tr("First %1 of %2", "preview column note when only the start of the file is shown").arg(FileFormat.size(pane.text.length)).arg(FileFormat.size(pane.entry?.size ?? 0))
                color: Style.surfaceVariantText
                font.pixelSize: Style.fontSizeSmall
                elide: Text.ElideRight
            }

            StyledText {
                width: parent.width
                visible: pane.canPreview && pane.text !== ""
                text: pane.text
                color: Style.surfaceText
                font.family: Style.monoFontFamily
                font.pixelSize: Style.fontSizeSmall
                wrapMode: Text.WrapAnywhere
                textFormat: Text.PlainText
            }
        }
    }
}
