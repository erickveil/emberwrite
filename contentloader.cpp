#include "contentloader.h"

ContentLoader::ContentLoader(QObject *parent)
    : QObject{parent}
{
    std::function<void (QString)> callback = [&] (QString response){
        onApiResponded(response);
    };
    _api.setSuccessCallback(callback);
}

void ContentLoader::init(QObject *qmlObj)
{
    _qmlMainWindowObj = qmlObj;
}

QString ContentLoader::loadChat()
{
    FileInterface file;
    return file.loadChatFile();
}

QString ContentLoader::appendNewUserMessage(QString msg)
{
    AiConnector api(this);
    QJsonDocument latestChat = api.loadChatFromFileAndAppend(msg);
    FileInterface file;
    file.saveChatFile(latestChat);
    return latestChat.toJson();
}

void ContentLoader::requestNewResponse()
{
    _api.requestChatCompletion();
}

void ContentLoader::onApiResponded(QString response)
{
    QMetaObject::invokeMethod(_qmlMainWindowObj, "onApiResponded",
                              Q_ARG(QVariant, response));
}
