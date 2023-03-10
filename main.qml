import QtQuick
import QtQuick.Controls

Window {
    id: mainWin
    width: 800
    height: 600
    visible: true
    title: qsTr("Hello World")
    color: "black"

    function createMsgBubble(text, isRightAligned) {
        var rect = Qt.createQmlObject('import QtQuick 2.0; Rectangle {}',
                                      chatCol);

        rect.radius = 10;
        // note can't bind this value the the parent Column type.
        // must go to the column's parent.
        rect.width = Qt.binding(function() { return chatScroll.width * 0.9 });
        rect.height = 0; // Set height to 0 to fit its contents

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

        rect.height = textItem.height + 20; // Add some padding

        return rect;
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

                for (let i=0; i < chatList.length; i++) {
                    var msgObj = chatList[i];
                    var msgRole = msgObj.role;
                    var isRightAligned = msgRole === "user";
                    console.log(msgRole);
                    console.log(isRightAligned);
                    var msgContent = msgObj.content;
                    var msgBubble = createMsgBubble(msgContent, isRightAligned);
                    chatCol.children.push(msgBubble);
                }
            }
        }
    }

    ScrollView {
        width: parent.width * 0.8
        height: Math.min(contentHeight + 20, 200)
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter

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

}
