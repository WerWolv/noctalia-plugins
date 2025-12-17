import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.Commons
import qs.Widgets

Dialog {
    id: runImageDialog

    property string imageRepo: ""
    property string imageTag: ""
    property string placeholderPort: ""
    property string errorMessage: ""
    property var pluginApi: null

    signal requestRun(string image, string port, string network)
    signal requestPortCheck(string port, string network)

    title: "Run Container"
    modal: true
    parent: Overlay.overlay
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2

    // Helper to reset fields
    function resetFields(repo, tag, port) {
        imageRepo = repo
        imageTag = tag
        errorMessage = ""
        placeholderPort = port
        exposePortCheck.checked = true
        networkField.text = (pluginApi && pluginApi.pluginSettings && pluginApi.pluginSettings.defaultNetwork) || "bridge"
        if (portField) portField.text = port
    }

    ColumnLayout {
        spacing: 10

        Text {
            text: "Run " + runImageDialog.imageRepo + ":" + runImageDialog.imageTag
            font.bold: true
            color: Color.mOnSurface
        }

        CheckBox {
            id: exposePortCheck
            text: "Expose Port to Host"
            checked: true
        }

        GridLayout {
            columns: 2
            rowSpacing: 10
            columnSpacing: 10

            Text {
                text: "Host Port:"
                color: Color.mOnSurfaceVariant
                opacity: exposePortCheck.checked ? 1 : 0.5
            }

            TextField {
                id: portField
                enabled: exposePortCheck.checked
                placeholderText: "Default: " + runImageDialog.placeholderPort
                text: runImageDialog.placeholderPort

                validator: IntValidator {
                    bottom: 1
                    top: 65535
                }
            }

            Text {
                text: "Network:"
                color: Color.mOnSurfaceVariant
            }

            TextField {
                id: networkField
                text: (pluginApi && pluginApi.pluginSettings && pluginApi.pluginSettings.defaultNetwork) || "bridge"
                placeholderText: "bridge"
            }
        }

        Text {
            text: runImageDialog.errorMessage
            color: Color.mError
            visible: text !== ""
            font.bold: true
        }

        Text {
            text: exposePortCheck.checked ? "Mapped to localhost:" + (portField.text || runImageDialog.placeholderPort) : "Internal only. Accessible by other containers on '" + (networkField.text || "bridge") + "'."
            color: Color.mOnSurfaceVariant
            font.pixelSize: 11
            Layout.maximumWidth: 300
            wrapMode: Text.WordWrap
        }
    }

    footer: DialogButtonBox {
        Button {
            text: "Cancel"
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            onClicked: runImageDialog.close()
        }

        Button {
            text: "Run"
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            onClicked: {
                var port = portField.text
                var network = networkField.text
                if (!exposePortCheck.checked || port.trim() === "") {
                    // Start immediately if no port check needed
                    requestRun(runImageDialog.imageRepo + ":" + runImageDialog.imageTag, "", network)
                    runImageDialog.close()
                    return
                }
                
                // Otherwise request port check
                runImageDialog.errorMessage = ""
                requestPortCheck(port, network)
            }
        }
    }
}
