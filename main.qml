import QtQuick
import QtQuick.Controls

Window {
    id: mainWin
    width: 800
    height: 600
    visible: true
    title: qsTr("Hello World")
    color: "black"

    property var msgList: [];

    function createMsgBubble(text, isRightAligned) {
        var rect = Qt.createQmlObject('import QtQuick 2.0; Rectangle {}',
                                      chatCol);

        rect.radius = 10;
        // note can't bind this value the the parent Column type.
        // must go to the column's parent.
        rect.width = Qt.binding(function() { return chatScroll.width * 0.9 });
        rect.height = 0;

        var textItem =
                Qt.createQmlObject('import QtQuick 2.0; Text {}', rect);

        textItem.text = text;
        textItem.color = "black";
        textItem.font.family = "StoneSansStd-Medium";
        textItem.font.pixelSize = 16;
        textItem.verticalAlignment = Text.AlignVCenter;
        textItem.wrapMode = Text.WordWrap;
        textItem.width = Qt.binding(function() { return rect.width });
        textItem.height = textItem.contentHeight;
        textItem.x = rect.x + 10;

        if (isRightAligned) {
            rect.x = Qt.binding(function() {
                return chatScroll.width - rect.width
            });
            rect.color = "lightblue";
        } else {
            rect.x = 0;
            rect.color = "lightgreen";
        }

        textItem.anchors.top = Qt.binding(function() { return rect.top });
        textItem.anchors.bottom = Qt.binding(function() { return rect.bottom });

        rect.height = Qt.binding(function() {
            return textItem.contentHeight + 20;
        });


        msgList.push(rect);
        return rect;
    }

    function drawFullChat(chatList) {
        for (let i=0; i < chatList.length; i++) {
            var msgObj = chatList[i];
            var msgRole = msgObj.role;
            var isRightAligned = msgRole === "user";
            var msgContent = msgObj.content;
            var msgBubble = createMsgBubble(msgContent, isRightAligned);
            chatCol.children.push(msgBubble);
        }
    }

    function clearChatColumn() {
        for (var i = 0; i < msgList.length; i++) {
            msgList[i].destroy();
        }
    }

    function onApiResponded(response) {
        console.log("Signal caught: " + response);
    }

    ScrollView {
        id: chatScroll
        width: parent.width
        height: parent.height
        anchors.fill: parent
        clip: true

        Column {
            id: chatCol
            width: parent.width
            height: parent.height
            anchors.fill: parent
            spacing: 20

            Component.onCompleted: {
                var chatData = contentLoader.loadChat();
                var chatList = JSON.parse(chatData);
                drawFullChat(chatList);
            }
        }
    }

    ScrollView {
        id: inputScroller
        width: parent.width * 0.8
        height: Math.min(contentHeight + 20, 200)
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 10

        TextArea {
            id: messageInput
            wrapMode: TextArea.WrapAnywhere
            font.family: "StoneSansStd-Medium"
            font.pointSize: 12
            color: "black"
            padding: 10
            placeholderText: qsTr("Enter message...")
            background: Rectangle {
                radius: 10
                color: "grey"
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

}
