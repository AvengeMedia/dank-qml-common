pragma ComponentBehavior: Bound

import QtQuick
import qs.DankCommon.Common
import qs.DankCommon.Widgets

DankTextField {
    id: field

    required property string name

    readonly property string trimmed: text.trim()
    readonly property bool valid: FileFormat.validName(text)

    signal committed(string name)
    signal cancelled

    function begin() {
        text = name;
        forceActiveFocus();
        selectAll();
    }

    function commit() {
        if (!valid) {
            invalidHint.showNow();
            return;
        }
        if (trimmed === name) {
            field.cancelled();
            return;
        }
        field.committed(trimmed);
    }

    height: Style.buttonHeightXXS
    outlined: true
    isError: text !== "" && !valid
    onAccepted: commit()
    Keys.onEscapePressed: event => {
        event.accepted = true;
        field.cancelled();
    }
    Keys.onReturnPressed: event => event.accepted = true
    Keys.onEnterPressed: event => event.accepted = true

    DankTooltipHost {
        id: invalidHint

        target: field
        side: "bottom"
        text: I18n.tr("A name cannot be empty or contain a slash", "inline rename validation message")
    }
}
