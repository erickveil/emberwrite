import QtQuick
import QtQuick.Controls
import QtQuick.Shapes

Window {
    id: mainWin
    width: 800
    height: 600
    visible: true
    title: qsTr("Hello World")
    color: "#202123"

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

        // TODO: This isn't formatting properly
        textItem.textFormat = Text.MarkdownText;
        textItem.rightPadding = 20;
        textItem.lineHeight = 1.5;
        textItem.text = text;
        textItem.color = "#D1D5DB";
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
        var bottomSpace = Qt.createQmlObject('import QtQuick 2.0; Rectangle {}',
                                      chatCol);
        bottomSpace.width = Qt.binding(function() { return chatCol.width * 0.9 });
        bottomSpace.height = 200
        bottomSpace.color = "transparent"
        msgList.push(bottomSpace);
        chatCol.children.push(bottomSpace);

        // set scrollview to bottom:
        // Note the presense of images from markdown messes this up and makes it
        // impossible to do.
        chatScroll.ScrollBar.vertical.position = chatScroll.contentItem.height;
    }

    function clearChatColumn() {
        for (var i = 0; i < msgList.length; i++) {
            msgList[i].destroy();
        }
        msgList = [];
    }

    function onApiResponded(response) {
        console.log("Signal caught: " + response);
        clearChatColumn();
        var chatData = contentLoader.loadChat();
        var chatList = JSON.parse(chatData);
        drawFullChat(chatList);
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
                var chatList = JSON.parse(chatData);
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

    }
}
