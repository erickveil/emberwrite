import QtQuick
import QtQuick.Controls
import QtQuick.Shapes

Window {
    id: mainWin
    width: 1000
    height: 1000
    visible: true
    title: qsTr("Hello World")
    color: "#202123"

    property var msgList: [];

    function createMsgBubble(text, isRightAligned, role, isRemembered) {
        var rect = Qt.createQmlObject('import QtQuick 2.0; Rectangle {}',
                                      chatCol);

        // Text replacement therapy here
        text = text.replace(/(?:\r\n|\r|\n)/g, '<br/>');

        // these values get saved when edited
        Object.defineProperty(rect, 'role', { value: role });

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

        /*
          // if we're doing TextArea instead of Text:
        var textBack =
                Qt.createQmlObject('import QtQuick; Rectangle {}', textItem);
        textBack.color = "transparent";
        textItem.background = textBack;
        */


        msgList.push(rect);
        return rect;
    }


    function drawFullChat(chatList) {
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
                                            msgRole, isRemembered);
            chatCol.children.push(msgBubble);
        }
        var bottomSpace = Qt.createQmlObject('import QtQuick 2.0; Rectangle {}',
                                             chatCol);
        bottomSpace.width = Qt.binding(function() { return chatCol.width * 0.9 });
        bottomSpace.height = 200
        bottomSpace.color = "transparent"
        msgList.push(bottomSpace);
        chatCol.children.push(bottomSpace);

        // set scrollview to bottom:
        // Note the presense of images from markdown messes this up and makes it
        // impossible to do right.
        chatScroll.ScrollBar.vertical.position = chatScroll.contentItem.height;
    }

    function clearChatColumn() {
        for (var i = 0; i < msgList.length; i++) {
            msgList[i].destroy();
        }
        msgList = [];
    }

    function onApiResponded(response) {
        reloadChatFromDisk();
    }

    function reloadChatFromDisk() {
        clearChatColumn();
        var chatData = contentLoader.loadChat();
        var chatList = JSON.parse(chatData);
        drawFullChat(chatList);
    }

    function saveExistingChat() {
        var msgList = [];
        for (var i = 0; i < msgList.length; i++) {
            var savedObj = msgList[i];
            var isNotRoleObj = savedObj.role = undefined;
            if (isNotRoleObj) { continue; }

            var msgObj = {};
            msgObj.roll = savedObj.roll;
            msgObj.content = savedObj.textObj.text;

            msgList.push(msgObj);
        }

        var msgListStr = JSON.stringify(msgList);
        // TODO: Replace the '<br>' back to '/n' and save to disk.
    }

    function popUpWarning(msg) {
        warningText.text = msg;
        warningDialog.visible = true;
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

                var isEmptyChat = (chatList.length === 0);
                if (isEmptyChat) {
                    console.log("New, empty chat.");
                    return;
                }

                drawFullChat(chatList);
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
            height: Math.min(contentHeight + 20, 200)
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
                    clearChatColumn();
                    var chatList = JSON.parse(newChatData);
                    drawFullChat(chatList);

                    // clear chat window
                    messageInput.text = "";


                    // get assistant message and display
                    contentLoader.requestNewResponse();
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
