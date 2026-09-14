import QtQuick
import qs.DankCommon.Common

Item {
    id: root

    property var text: null
    property Item target: null
    property MouseArea hoverArea: null
    property string side: "bottom"
    property bool shown: false

    function schedule() {
        present(Style.tooltipDelay);
    }

    function showNow() {
        present(0);
    }

    function refresh() {
        if (shown)
            showNow();
    }

    function dismiss() {
        tooltipLoader.item?.hide();
        shown = false;
    }

    function present(delay) {
        const tooltip = tooltipLoader.item;
        if (!tooltip || !enabled || !visible || !text || !target?.visible)
            return;
        tooltip.delay = delay;
        tooltip.show(text, target, 0, 0, side);
        shown = true;
    }

    onTextChanged: text ? refresh() : dismiss()
    onTargetChanged: target ? refresh() : dismiss()

    onEnabledChanged: {
        if (!enabled)
            dismiss();
    }

    onVisibleChanged: {
        if (!visible)
            dismiss();
    }

    Connections {
        target: root.hoverArea

        function onEntered() {
            root.schedule();
        }

        function onExited() {
            root.dismiss();
        }
    }

    Loader {
        id: tooltipLoader
        active: !!root.text
        sourceComponent: DankTooltipV2 {}
    }
}
