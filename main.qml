import QtQuick
import QtQuick.Controls
import QtQuick.Shapes
import QtMultimedia

Window {
    id: mainWin
    width: 1000
    height: 1000
    visible: true
    title: qsTr("EmberWrite")
    color: "#202123"

    property var msgBubbleObjList: [];
    property var msgJsonList: [];

    function createMsgBubble(text, isRightAligned, role, isRemembered, index) {
        var rect = Qt.createQmlObject('import QtQuick 2.0; Rectangle {}',
                                      chatCol);

        // Text replacement therapy here
        text = text.replace(/(?:\r\n|\r|\n)/g, '<br/>');

        // these values get saved when edited
        Object.defineProperty(rect, 'role', { value: role });
        Object.defineProperty(rect, 'index', { value: index });

        rect.radius = 10;
        // note can't bind this value the the parent Column type.
        // must go to the column's parent.
        rect.width = Qt.binding(function() { return chatScroll.width * 0.9 });
        rect.height = 0;

        var textItem =
             //Qt.createQmlObject('import QtQuick.Controls; TextArea {}', rect);
                Qt.createQmlObject('import QtQuick; Text {}', rect);

        // Maybe we want to save the loaded text instead so we don't have to
        // fudge around with formatting changes?
        Object.defineProperty(rect, 'textObj', { value: textItem });

        //textItem.textFormat = Text.MarkdownText;
        textItem.textFormat = Text.RichText;
        textItem.rightPadding = 20;
        textItem.lineHeight = 1.5;
        textItem.text = text;

        textItem.color = isRemembered ? "#D1D5DB" : "gray";

        textItem.font.family = "StoneSansStd-Medium";
        textItem.font.pointSize = 14;
        textItem.verticalAlignment = Text.AlignVCenter;
        textItem.wrapMode = Text.WordWrap;
        textItem.width = Qt.binding(function() { return rect.width });
        textItem.height = textItem.contentHeight;
        textItem.x = rect.x + 10;

        if (isRightAligned) {
            // arbitrary, but it works:
            var scrollbarWidth = 40;
            rect.x = Qt.binding(function() {
                return chatScroll.width - rect.width - scrollbarWidth
            });
            rect.color = "#343541";
        } else {
            rect.x = Qt.binding(function() { return chatScroll.width * 0.02 });
            rect.color = "#444653";
        }

        textItem.anchors.top = Qt.binding(function() { return rect.top });
        textItem.anchors.bottom = Qt.binding(function() { return rect.bottom });

        rect.height = Qt.binding(function() {
            return textItem.contentHeight + 20;
        });

        var clickZone =
                Qt.createQmlObject('import QtQuick; MouseArea {}', rect);
        clickZone.anchors.fill = rect;
        clickZone.onClicked.connect(function() {
            startEdit(rect);
        });

        msgBubbleObjList.push(rect);
        return rect;
    }

    function drawFullChat(chatList) {

        var isChatEmpty = (chatList.length === 0);
        if (isChatEmpty) {
            console.log("Empty chat. Skipping draw.");
            return;
        }

        mainWin.msgJsonList = chatList;
        var isRemembered = false;
        for (let i=0; i < chatList.length; i++) {
            var msgObj = chatList[i];
            var msgRole = msgObj.role;
            var isPrintableRole =
                    (msgRole === "user" || msgRole === "assistant");
            if (!isPrintableRole) { continue; }
            var isRightAligned = msgRole === "user";
            var msgContent = msgObj.content;

            if (contentLoader.isOldestMsg(msgContent)) { isRemembered = true; }

            var msgBubble = createMsgBubble(msgContent, isRightAligned,
                                            msgRole, isRemembered, i);
            chatCol.children.push(msgBubble);
        }
        var bottomSpace = Qt.createQmlObject('import QtQuick 2.0; Rectangle {}',
                                             chatCol);
        bottomSpace.width = Qt.binding(function() { return chatCol.width * 0.9 });
        bottomSpace.height = 200
        bottomSpace.color = "transparent"
        msgBubbleObjList.push(bottomSpace);
        chatCol.children.push(bottomSpace);

        // set scrollview to bottom:
        // Note the presense of images from markdown messes this up and makes it
        // impossible to do right.
        chatScroll.ScrollBar.vertical.position = chatScroll.contentItem.height;
    }

    function clearChatColumn() {
        for (var i = 0; i < msgBubbleObjList.length; i++) {
            msgBubbleObjList[i].destroy();
        }
        msgBubbleObjList = [];
    }

    function onApiResponded(response) {
        reloadChatFromDisk();
        receiveSound.play();
    }

    function reloadChatFromDisk() {
        clearChatColumn();
        var chatData = contentLoader.loadChat();
        var isNewChat = (chatData === "");
        if (isNewChat) {
            console.log("No chat to refresh.");
            return;
        }
        var chatList = JSON.parse(chatData);
        mainWin.msgJsonList = chatList;
        drawFullChat(chatList);
    }

    function saveExistingChat() {
        var msgList = mainWin.msgJsonList;
        var msgListStr = JSON.stringify(msgList);
        contentLoader.saveChat(msgListStr);
    }

    function popUpWarning(msg) {
        warningText.text = msg;
        warningDialog.visible = true;
    }

    // When click edit save button
    function editMessage(msgIndex) {
        var newMsg = editInput.text;
        mainWin.msgJsonList[msgIndex].content= newMsg;
        saveExistingChat();
        clearChatColumn();
        drawFullChat(mainWin.msgJsonList);
        editScroller.visible = false;
    }

    function startEdit(bubbleObj) {
        var index = bubbleObj.index;
        var msgObj = mainWin.msgJsonList[index];
        var msgText = msgObj["content"];

        console.log("Editing index #" + index + " content: " + msgText);

        editInput.text = msgText;
        editScroller.msgBubbleOrigin = bubbleObj;
        editScroller.msgIndex = index;
        editScroller.visible = true;
    }

    SoundEffect {
        id: sendSound
        source: "qrc:/send.wav"
    }

    SoundEffect {
        id: receiveSound
        source: "qrc:/redeive.wav"
    }

    Rectangle {
        id: warningDialog
        width: parent.width * 0.75
        height: warningText.contentHeight + 20
        color: "yellow"
        border.color: "red"
        border.width: 3
        radius: 15
        visible: false
        anchors.centerIn: parent
        z: 2

        Text {
            id: warningText
            anchors.fill: parent
            wrapMode: TextArea.Wrap
            font.family: "StoneSansStd-Medium"
            font.pointSize: 14
            color: "black"
            padding: 10
            horizontalAlignment: Text.AlignHCenter
        }
        MouseArea {
            anchors.fill: parent
            onClicked: {
                warningDialog.visible = false;
            }
        }
    }

    ScrollView {
        id: chatScroll
        width: parent.width
        height: parent.height
        anchors.fill: parent
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ScrollBar.vertical: ScrollBar {
            id: chatScrollBar
            width: 10
            anchors.top: chatScroll.top
            anchors.right: chatScroll.right
            anchors.bottom: chatScroll.bottom
            background: Rectangle {
                color: "#444653"
            }
        }


        Column {
            id: chatCol
            width: parent.width
            height: parent.height;
            anchors.fill: parent
            spacing: 20

            Component.onCompleted: {
                var chatData = contentLoader.loadChat();
                var isNoChatYet = (chatData === "");
                if (isNoChatYet) {
                    console.log("New chat file.");
                    return;
                }
                var chatList = JSON.parse(chatData);
                drawFullChat(chatList);
            }
        }
    }

    ScrollView {
        id: editScroller
        width: parent.width * 0.8
        height: Math.min(editInput.contentHeight + 40, 400)
        anchors.centerIn: parent
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        visible: false
        property int msgIndex;
        property var msgBubbleOrigin;

        ScrollBar.vertical: ScrollBar {
            id: editScrollbar
            width: 10
            height: editScroller.height
            anchors.top: editScroller.top
            anchors.bottom: editScroller.bottom
            anchors.right: editScroller.right
            background: Rectangle {
                color: "#444653"
            }
        }
        TextArea {
            id: editInput
            wrapMode: TextArea.Wrap
            font.family: "StoneSansStd-Medium"
            font.pointSize: 14
            color: "#D1D5DB"
            padding: 10
            placeholderText: qsTr("Enter message...")
            background: Rectangle {
                radius: 10
                //color: "#343541"
                color: "black"
                border.color: "dark grey"
                border.width: 4
            }
        }

        Rectangle {
            id: editSaveButton
            anchors.right: editInput.right
            anchors.bottom: editInput.bottom
            radius: 20
            width: 30
            height: 30
            color: "black"
            border.color: "light blue"
            border.width: 3
            anchors.rightMargin: 10
            anchors.bottomMargin: 10

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: {
                    editSaveButton.color = "grey"
                }
                onExited: {
                    editSaveButton.color = "black"
                }
                onClicked: {
                    editMessage(editScroller.msgIndex);
                }
            }

            Image {
                id: saveIcon
                source: "qrc:/save.png"
                width: 15
                height: 15
                anchors.centerIn: parent
            }
        }

        Rectangle {
            id: editCloseButton
            anchors.right: editSaveButton.left
            anchors.bottom: editInput.bottom
            radius: 20
            width: 30
            height: 30
            color: "black"
            border.color: "pink"
            border.width: 3
            anchors.rightMargin: 10
            anchors.bottomMargin: 10

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: {
                    editCloseButton.color = "grey"
                }
                onExited: {
                    editCloseButton.color = "black"
                }
                onClicked: {
                    editScroller.visible = false
                }
            }

            Image {
                id: closeIcon
                source: "qrc:/close.png"
                width: 20
                height: 20
                anchors.centerIn: parent
            }
        }
    }

    Rectangle {
        id: inputFade
        width: parent.width
        height: 200
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter

        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: "transparent"
            }
            GradientStop {
                position: 0.75
                color: "black"
            }

        }

        ScrollView {
            id: inputScroller
            width: parent.width * 0.8
            height: Math.min(messageInput.contentHeight + 40, 200)
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 10
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ScrollBar.vertical: ScrollBar {
                id: inputScrollBar
                width: 10
                anchors.top: inputScroller.top
                anchors.right: inputScroller.right
                anchors.bottom: inputScroller.bottom
                background: Rectangle {
                    color: "#444653"
                }
            }
            TextArea {
                id: messageInput
                wrapMode: TextArea.Wrap
                font.family: "StoneSansStd-Medium"
                font.pointSize: 14
                color: "#D1D5DB"
                padding: 10
                placeholderText: qsTr("Enter message...")
                background: Rectangle {
                    radius: 10
                    color: "#343541"
                }
            }
        }

        Rectangle {
            id: sendButton
            anchors.left: inputScroller.right
            anchors.bottom: inputScroller.bottom
            radius: 20
            width: 30
            height: 30
            color: "black"
            border.color: "light blue"
            border.width: 3
            anchors.leftMargin: 10
            anchors.bottomMargin: 10

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: {
                    sendButton.color = "grey"
                }
                onExited: {
                    sendButton.color = "black"
                }
                onClicked: {
                    if (messageInput.text === "") { return; }

                    // set user message and display
                    var newChatData =
                          contentLoader.appendNewUserMessage(messageInput.text);

                    var isNoChatData = (newChatData === "");
                    if (isNoChatData) {
                        console.log("Chat file is empty.");
                    }
                    else {
                        clearChatColumn();
                        var chatList = JSON.parse(newChatData);
                        drawFullChat(chatList);
                    }

                    // clear chat input window
                    messageInput.text = "";

                    // get assistant message and display
                    contentLoader.requestNewResponse();

                    sendSound.play();
                }


            }

            Image {
                id: sendIcon
                source: "qrc:/paper-plane-icon.png"
                width: 20
                height: 20
                anchors.centerIn: parent
            }
        }

        Rectangle {
            id: loadButton
            anchors.left: sendButton.left
            anchors.bottom: sendButton.top
            radius: 20
            width: 30
            height: 30
            color: "black"
            border.color: "light blue"
            border.width: 3
            anchors.leftMargin: 10
            anchors.bottomMargin: 10

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: {
                    loadButton.color = "grey"
                }
                onExited: {
                    loadButton.color = "black"
                }
                onClicked: { reloadChatFromDisk(); }
            }

            Image {
                id: loadIcon
                source: "qrc:/open.png"
                width: 15
                height: 15
                anchors.centerIn: parent
            }
        }
    }

}
