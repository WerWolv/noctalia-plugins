import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "dockerUtils.js" as DockerUtils
import qs.Commons
import qs.Services.System
import qs.Widgets

Item {
    id: root

    property var pluginApi: null
    readonly property var geometryPlaceholder: panelContainer
    readonly property bool allowAttach: true
    property real contentPreferredWidth: 850 * Style.uiScaleRatio
    property real contentPreferredHeight: 600 * Style.uiScaleRatio
    property bool sidebarExpanded: false
    property int currentTabIndex: 0
    property var _cachedContainers: []
    property var _pendingCallback: null

    function refreshAll() {
        containerProcess.running = true;
        volumeProcess.running = true;
        networkProcess.running = true;
    }

    function runCommand(cmdArgs, callback) {
        if (commandRunner.running) {
            console.warn("Command runner busy, ignoring:", cmdArgs);
            return ;
        }
        root._pendingCallback = callback;
        commandRunner.command = cmdArgs;
        commandRunner.running = true;
    }

    function startContainer(id) {
        runCommand(["docker", "start", id], refreshAll);
    }

    function stopContainer(id) {
        runCommand(["docker", "stop", id], refreshAll);
    }

    function removeContainer(id) {
        runCommand(["docker", "rm", id], refreshAll);
    }

    function removeImage(id) {
        runCommand(["docker", "rmi", id], refreshAll);
    }

    function removeVolume(name) {
        runCommand(["docker", "volume", "rm", name], refreshAll);
    }

    function removeNetwork(id) {
        runCommand(["docker", "network", "rm", id], refreshAll);
    }

    function attemptRunImage(repo, tag) {
        runImageDialog.imageRepo = repo;
        runImageDialog.imageTag = tag;
        runImageDialog.errorMessage = "";
        exposePortCheck.checked = true;
        networkField.text = "";
        inspectProcess.targetImage = repo + ":" + tag;
        inspectProcess.running = true;
    }

    function finalizeRunImage(image, port, network) {
        var cmd = ["docker", "run", "-d"];
        if (exposePortCheck.checked && port && port.trim() !== "") {
            cmd.push("-p");
            cmd.push(port + ":" + port);
        }
        if (network && network.trim() !== "" && network !== "bridge") {
            cmd.push("--network");
            cmd.push(network);
        }
        cmd.push(image);
        runCommand(cmd, refreshAll);
    }

    anchors.fill: parent
    Component.onCompleted: refreshAll()

    ListModel {
        id: containersModel
    }

    ListModel {
        id: imagesModel
    }

    ListModel {
        id: volumesModel
    }

    ListModel {
        id: networksModel
    }

    Rectangle {
        id: panelContainer

        anchors.fill: parent
        color: Color.transparent

        Rectangle {
            anchors.fill: parent
            anchors.margins: Style.marginL
            color: Color.mSurface
            radius: Style.radiusL
            border.color: Color.mOutline
            border.width: Style.borderS
            clip: true

            RowLayout {
                anchors.fill: parent
                spacing: 0

                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: root.sidebarExpanded ? 200 * Style.uiScaleRatio : 56 * Style.uiScaleRatio
                    color: Color.mSurfaceVariant
                    clip: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Style.marginS
                        spacing: Style.marginS

                        NButton {
                            icon: root.sidebarExpanded ? "layout-sidebar-right-expand" : "layout-sidebar-left-expand"
                            Layout.preferredWidth: 40 * Style.uiScaleRatio
                            Layout.preferredHeight: 40 * Style.uiScaleRatio
                            onClicked: root.sidebarExpanded = !root.sidebarExpanded
                        }

                        Item {
                            height: Style.marginS
                            width: 1
                        }

                        SidebarItem {
                            iconName: "brand-docker"
                            itemText: "Containers"
                            idx: 0
                        }

                        SidebarItem {
                            iconName: "photo"
                            itemText: "Images"
                            idx: 1
                        }

                        SidebarItem {
                            iconName: "database"
                            itemText: "Volumes"
                            idx: 2
                        }

                        SidebarItem {
                            iconName: "network"
                            itemText: "Networks"
                            idx: 3
                        }

                        Item {
                            Layout.fillHeight: true
                        }

                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 1
                        color: Color.mOutline
                        opacity: 0.5
                    }

                    Behavior on Layout.preferredWidth {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.InOutQuad
                        }

                    }

                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 0

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 60 * Style.uiScaleRatio
                        color: Color.transparent

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Style.marginL
                            spacing: Style.marginM

                            Text {
                                text: {
                                    if (root.currentTabIndex === 0)
                                        return "Containers";

                                    if (root.currentTabIndex === 1)
                                        return "Images";

                                    if (root.currentTabIndex === 2)
                                        return "Volumes";

                                    return "Networks";
                                }
                                font.bold: true
                                font.pixelSize: 20
                                color: Color.mOnSurface
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            NButton {
                                icon: "refresh"
                                text: "Refresh"
                                onClicked: refreshAll()
                            }

                        }

                    }

                    StackLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        currentIndex: root.currentTabIndex

                        Item {
                            ListView {
                                id: containersList

                                anchors.fill: parent
                                anchors.margins: Style.marginM
                                model: containersModel
                                delegate: containerDelegate
                                spacing: Style.marginS
                                clip: true

                                ScrollBar.vertical: ScrollBar {
                                    policy: ScrollBar.AsNeeded
                                    active: containersList.moving
                                }

                            }

                            Text {
                                anchors.centerIn: parent
                                visible: containersModel.count === 0
                                text: "No containers found"
                                color: Color.mOnSurfaceVariant
                            }

                        }

                        Item {
                            ListView {
                                id: imagesList

                                anchors.fill: parent
                                anchors.margins: Style.marginM
                                model: imagesModel
                                delegate: imageDelegate
                                spacing: Style.marginS
                                clip: true

                                ScrollBar.vertical: ScrollBar {
                                    policy: ScrollBar.AsNeeded
                                    active: imagesList.moving
                                }

                            }

                            Text {
                                anchors.centerIn: parent
                                visible: imagesModel.count === 0
                                text: "No images found"
                                color: Color.mOnSurfaceVariant
                            }

                        }

                        Item {
                            ListView {
                                id: volumesList

                                anchors.fill: parent
                                anchors.margins: Style.marginM
                                model: volumesModel
                                delegate: volumeDelegate
                                spacing: Style.marginS
                                clip: true

                                ScrollBar.vertical: ScrollBar {
                                    policy: ScrollBar.AsNeeded
                                    active: volumesList.moving
                                }

                            }

                            Text {
                                anchors.centerIn: parent
                                visible: volumesModel.count === 0
                                text: "No volumes found"
                                color: Color.mOnSurfaceVariant
                            }

                        }

                        Item {
                            ListView {
                                id: networksList

                                anchors.fill: parent
                                anchors.margins: Style.marginM
                                model: networksModel
                                delegate: networkDelegate
                                spacing: Style.marginS
                                clip: true

                                ScrollBar.vertical: ScrollBar {
                                    policy: ScrollBar.AsNeeded
                                    active: networksList.moving
                                }

                            }

                            Text {
                                anchors.centerIn: parent
                                visible: networksModel.count === 0
                                text: "No networks found"
                                color: Color.mOnSurfaceVariant
                            }

                        }

                    }

                }

            }

        }

    }

    Process {
        id: commandRunner

        onExited: {
            if (root._pendingCallback) {
                root._pendingCallback();
                root._pendingCallback = null;
            }
        }

        stdout: StdioCollector {
        }

    }

    Process {
        id: containerProcess

        command: ["docker", "ps", "-a", "--format", "json"]

        stdout: StdioCollector {
            onStreamFinished: {
                var data = DockerUtils.parseContainers(this.text);
                root._cachedContainers = data;
                containersModel.clear();
                data.forEach(function(c) {
                    containersModel.append(c);
                });
                imageProcess.running = true;
            }
        }

    }

    Process {
        id: imageProcess

        command: ["docker", "images", "--format", "json"]

        stdout: StdioCollector {
            onStreamFinished: {
                var data = DockerUtils.parseImages(this.text, root._cachedContainers);
                imagesModel.clear();
                data.forEach(function(img) {
                    imagesModel.append(img);
                });
            }
        }

    }

    Process {
        id: volumeProcess

        command: ["docker", "volume", "ls", "--format", "json"]

        stdout: StdioCollector {
            onStreamFinished: {
                var data = DockerUtils.parseVolumes(this.text);
                volumesModel.clear();
                data.forEach(function(v) {
                    volumesModel.append(v);
                });
            }
        }

    }

    Process {
        id: networkProcess

        command: ["docker", "network", "ls", "--format", "json"]

        stdout: StdioCollector {
            onStreamFinished: {
                var data = DockerUtils.parseNetworks(this.text);
                networksModel.clear();
                data.forEach(function(n) {
                    networksModel.append(n);
                });
            }
        }

    }

    Process {
        id: inspectProcess

        property string targetImage

        command: ["docker", "inspect", targetImage]

        stdout: StdioCollector {
            onStreamFinished: {
                var detectedPort = DockerUtils.parseExposedPorts(this.text);
                if (!detectedPort)
                    detectedPort = DockerUtils.guessDefaultPort(runImageDialog.imageRepo);

                portField.text = detectedPort;
                runImageDialog.placeholderPort = detectedPort;
                runImageDialog.open();
            }
        }

    }

    Process {
        id: portCheckProcess

        property string pendingPort
        property string pendingNetwork

        command: ["bash", "-c", "ss -tln | grep :" + pendingPort]

        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "") {
                    runImageDialog.errorMessage = "Port " + portCheckProcess.pendingPort + " is occupied on host.";
                } else {
                    runImageDialog.close();
                    finalizeRunImage(runImageDialog.imageRepo + ":" + runImageDialog.imageTag, portCheckProcess.pendingPort, portCheckProcess.pendingNetwork);
                }
            }
        }

    }

    Dialog {
        id: runImageDialog

        property string imageRepo: ""
        property string imageTag: ""
        property string placeholderPort: ""
        property string errorMessage: ""

        title: "Run Container"
        modal: true
        parent: Overlay.overlay
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2

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

                    text: (pluginApi && pluginApi.pluginSettings) ? pluginApi.pluginSettings.defaultNetwork : "bridge"
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
                    var port = portField.text;
                    var network = networkField.text;
                    if (!exposePortCheck.checked || port.trim() === "") {
                        runImageDialog.close();
                        finalizeRunImage(runImageDialog.imageRepo + ":" + runImageDialog.imageTag, "", network);
                        return ;
                    }
                    runImageDialog.errorMessage = "";
                    portCheckProcess.pendingPort = port;
                    portCheckProcess.pendingNetwork = network;
                    portCheckProcess.command = ["bash", "-c", "ss -tln | grep :" + port];
                    portCheckProcess.running = true;
                }
            }

        }

    }

    Component {
        id: containerDelegate

        Rectangle {
            width: containersList.width - (containersList.ScrollBar.vertical ? 10 : 0)
            height: 70 * Style.uiScaleRatio
            color: Color.mSurfaceVariant
            radius: Style.radiusM

            RowLayout {
                anchors.fill: parent
                anchors.margins: Style.marginM
                spacing: Style.marginM

                Rectangle {
                    width: 10
                    height: 10
                    radius: 5
                    color: DockerUtils.getStatusColor(model.state)
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "" + model.name
                        font.bold: true
                        color: Color.mOnSurface
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "" + model.image + " (" + model.status + ")"
                        color: Color.mOnSurfaceVariant
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                }

                Row {
                    spacing: 5

                    NButton {
                        icon: model.state === "running" ? "player-stop" : "player-play"
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        onClicked: model.state === "running" ? stopContainer(model.id) : startContainer(model.id)
                    }

                    NButton {
                        icon: "trash"
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        visible: model.state !== "running"
                        onClicked: removeContainer(model.id)
                    }

                }

            }

        }

    }

    Component {
        id: imageDelegate

        Rectangle {
            width: imagesList.width - (imagesList.ScrollBar.vertical ? 10 : 0)
            height: 60 * Style.uiScaleRatio
            color: Color.mSurfaceVariant
            radius: Style.radiusM

            RowLayout {
                anchors.fill: parent
                anchors.margins: Style.marginM
                spacing: Style.marginM

                NIcon {
                    icon: "photo"
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "" + model.repository + ":" + model.tag
                        font.bold: true
                        color: Color.mOnSurface
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "" + model.size + " • " + model.created
                        color: Color.mOnSurfaceVariant
                        font.pixelSize: 11
                        Layout.fillWidth: true
                    }

                }

                Row {
                    spacing: 5

                    NButton {
                        text: "Run"
                        icon: "player-play"
                        Layout.preferredHeight: 32
                        onClicked: attemptRunImage(model.repository, model.tag)
                    }

                    NButton {
                        icon: "trash"
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        visible: !model.isRunning
                        onClicked: removeImage(model.id)
                    }

                }

            }

        }

    }

    Component {
        id: volumeDelegate

        Rectangle {
            width: volumesList.width - (volumesList.ScrollBar.vertical ? 10 : 0)
            height: 50 * Style.uiScaleRatio
            color: Color.mSurfaceVariant
            radius: Style.radiusM

            RowLayout {
                anchors.fill: parent
                anchors.margins: Style.marginM
                spacing: Style.marginM

                NIcon {
                    icon: "database"
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "" + model.name
                        font.bold: true
                        color: Color.mOnSurface
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "" + model.driver
                        color: Color.mOnSurfaceVariant
                        font.pixelSize: 11
                    }

                }

                NButton {
                    icon: "trash"
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    onClicked: removeVolume(model.name)
                }

            }

        }

    }

    Component {
        id: networkDelegate

        Rectangle {
            width: networksList.width - (networksList.ScrollBar.vertical ? 10 : 0)
            height: 50 * Style.uiScaleRatio
            color: Color.mSurfaceVariant
            radius: Style.radiusM

            RowLayout {
                anchors.fill: parent
                anchors.margins: Style.marginM
                spacing: Style.marginM

                NIcon {
                    icon: "network"
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "" + model.name
                        font.bold: true
                        color: Color.mOnSurface
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "" + model.driver + " (" + model.scope + ")"
                        color: Color.mOnSurfaceVariant
                        font.pixelSize: 11
                    }

                }

                NButton {
                    icon: "trash"
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    visible: !model.isDefault
                    onClicked: removeNetwork(model.id)
                }

            }

        }

    }

    component SidebarItem: Rectangle {
        id: sideItem

        property string iconName
        property string itemText
        property int idx

        Layout.fillWidth: true
        Layout.preferredHeight: 40 * Style.uiScaleRatio
        color: root.currentTabIndex === idx ? Color.mSurface : Color.transparent
        radius: Style.radiusS

        Rectangle {
            visible: root.currentTabIndex === idx
            width: 3
            height: 16
            radius: 2
            color: Color.mPrimary
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 4
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            spacing: 12

            NIcon {
                icon: iconName
                color: Color.mOnSurface
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
            }

            Text {
                text: sideItem.itemText
                color: Color.mOnSurface
                font.weight: root.currentTabIndex === idx ? Font.DemiBold : Font.Normal
                opacity: root.sidebarExpanded ? 1 : 0
                Layout.fillWidth: true
                elide: Text.ElideRight

                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }

                }

            }

        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.currentTabIndex = idx
            onEntered: {
                if (root.currentTabIndex !== idx) {
                    parent.color = Qt.rgba(1, 1, 1, 0.05);
                }
            }
            onExited: {
                if (root.currentTabIndex !== idx) {
                    parent.color = Color.transparent;
                }
            }
        }

    }

}
