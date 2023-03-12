#include "aiconnector.h"

AiConnector::AiConnector(QObject *parent)
    : QObject{parent}
{
    _appDirPath =
            QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    _manager = new QNetworkAccessManager(this);
    _key = loadKey();
}

AiConnector::~AiConnector()
{
    if (_manager != nullptr) {
        delete _manager;
        _manager = nullptr;
    }
}

void AiConnector::setSuccessCallback(std::function<void (QString)> cb)
{
    _successCallback = cb;
}

void AiConnector::requestChatCompletion(QString newUserMsg)
{
    loadChatFromFileAndAppend(newUserMsg);
    saveChat(_latestChat);
    deliverToApi(_latestChat);
}

void AiConnector::requestChatCompletion()
{
    FileInterface file;
    QByteArray latestChat = file.loadChatFile();
    // TODO: Check for error?
    _latestChat = QJsonDocument::fromJson(latestChat);
    deliverToApi(_latestChat);
}

QString AiConnector::loadKey()
{
    QString keyPath = _appDirPath + "/apikey";
    QFile file(keyPath);
    bool isOpen = file.open(QIODevice::ReadOnly);
    if (!isOpen) {
        QString errMsg = "Cannot open key file for reading at: " + keyPath;
        Logger::Instance()->warning(errMsg);
        return "";
    }
    QTextStream fileStream(&file);
    // Maybe make this async too if we get hangs.
    file.waitForReadyRead(10000);
    QString key = fileStream.readAll();
    file.close();

    return key.trimmed();
}

void AiConnector::saveKey(QString key)
{
    QString keyPath = _appDirPath + "/apikey";
    QFile file(keyPath);
    bool isOpen = file.open(QIODevice::WriteOnly);
    if (!isOpen) {
        QString errMsg = "Cannot open key file for writing at: " + keyPath;
        Logger::Instance()->warning(errMsg);
        return;
    }
    QTextStream fileStream(&file);
    fileStream << key;
    file.close();
}

QJsonDocument AiConnector::loadChatFromFileAndAppend(QString newUserMsg)
{
    QByteArray fullChat = _chatPreloader.loadChatFile();
    QJsonDocument chatDoc = QJsonDocument::fromJson(fullChat);
    QJsonDocument appendedChat = appendNewUserMsg(chatDoc, newUserMsg);
    _latestChat = appendedChat;
    return _latestChat;
}

QJsonDocument AiConnector::appendNewUserMsg(QJsonDocument fullChat,
                                            QString newMsg)
{
    return appendNewMsg(fullChat, newMsg, "user");
}

QJsonDocument AiConnector::appendNewAssistantMsg(QJsonDocument fullChat, QString newMsg)
{
    return appendNewMsg(fullChat, newMsg, "assistant");
}

QJsonDocument AiConnector::appendNewMsg(QJsonDocument fullChat, QString newMsg, QString role)
{
    QJsonObject msgObj;
    msgObj.insert("role", role);
    msgObj.insert("content", newMsg);

    QJsonArray msgList = fullChat.array();
    msgList.append(msgObj);

    QJsonDocument appendedChat(msgList);
    return appendedChat;
}

void AiConnector::saveChat(QJsonDocument chatDoc)
{
    QString chatPath = _appDirPath + "/chat.json";
    QByteArray chatContents = chatDoc.toJson();
    _chatSaver.writeFile(chatPath, chatContents);
    _latestChat = chatDoc;
}

void AiConnector::deliverToApi(QJsonDocument chatDoc)
{
    QByteArray postData = createJsonPayload(chatDoc);
    QString authVal = createAuthHeaderVal();
    if (authVal == "") { return; }
    QNetworkRequest request = createApiRequest(authVal);

    QNetworkReply *reply = _manager->post(request, postData);

    connect(reply, &QNetworkReply::finished,
            [=]() { onNetworkReplyFinished(reply); });
}

QByteArray AiConnector::createJsonPayload(QJsonDocument chatDoc)
{
    // TODO: a config can set most of these values
    QJsonArray messageList = chatDoc.array();
    QJsonObject rootDataObj;
    rootDataObj.insert("model", "gpt-3.5-turbo");
    rootDataObj.insert("messages", messageList);
    rootDataObj.insert("frequency_penalty", 0);
    rootDataObj.insert("max_tokens", 256);
    rootDataObj.insert("presence_penalty", 0);
    rootDataObj.insert("temperature", 0.7);
    rootDataObj.insert("stream", false);
    QJsonDocument jsonDoc(rootDataObj);
    QByteArray postData = jsonDoc.toJson();

    return postData;
}

QString AiConnector::createAuthHeaderVal()
{
    if (_key == "") {
        QString errMsg = "Can't send. No key.";
        Logger::Instance()->warning(errMsg);
        return "";
    }
    QString authVal = "Bearer " + _key;
    return authVal;
}

QNetworkRequest AiConnector::createApiRequest(QString authVal)
{
    QUrl url("https://api.openai.com/v1/chat/completions");
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", authVal.toLocal8Bit());
    return request;
}

void AiConnector::onNetworkReplyFinished(QNetworkReply *reply)
{
    // I see this connected each call, do the slot calls multiply with each
    // call?
    qDebug() << "Network Reply Finished.";

    if (reply->error() != QNetworkReply::NoError) {
        QByteArray response = reply->readAll();
        qDebug() << "API Error Response: " << response;

        QString errWarning = "QNetworkReply Error: " + reply->errorString()
                + " || The response is: " + response;
        Logger::Instance()->warning(errWarning);

    }
    else {
        QByteArray response = reply->readAll();
        qDebug() << "API Response: " << response;
        parseApiResponse(response);
    }
    reply->deleteLater();
}

void AiConnector::parseApiResponse(QByteArray response)
{
    QJsonParseError responseParseError;
    auto responseDoc = QJsonDocument::fromJson(response, &responseParseError);
    bool isParseError = (responseDoc.isNull());
    if (isParseError) {
        QString errMsg = "Error parsing response: " + response
                 + " Error string: "
                 + responseParseError.errorString();
        Logger::Instance()->warning(errMsg);
    }
    else {
        parseResponseChoiceList(responseDoc);
    }
}

void AiConnector::parseResponseChoiceList(QJsonDocument responseDoc)
{
    parseTokenUse(responseDoc);

    QJsonValue choiceValue = responseDoc["choices"];
    QJsonArray choiceList = choiceValue.toArray();

    if (choiceList.size() > 1) {
        // I haven't seen this before. (you can explicitly request this in the
        // api).
        qDebug() << "The response choice list size came back greater than 1!";
    }
    if (choiceList.size() <= 0) {
        // I also haven't seen this.
        qDebug() << "The response choice list did not have a single choice.";
        return;
    }

    QJsonValue choiceVal = choiceList[0];
    parseResponseChoice(choiceVal);
}

void AiConnector::parseTokenUse(QJsonDocument responseDoc)
{
    QJsonValue usageVal = responseDoc["usage"];
    QJsonObject usageObj = usageVal.toObject();
    int errorVal = -1;
    int promptTokens = usageObj["prompt_tokens"].toInt(errorVal);
    int responseTokens =
            usageObj["completion_tokens"].toInt(errorVal);
    int totalTokens = usageObj["total_tokens"].toInt(errorVal);

    qDebug() << "Useage: prompt tokens - " << promptTokens
             << " | response tokens - " << responseTokens
             << " | total - " << totalTokens;
}

void AiConnector::parseResponseChoice(QJsonValue choiceVal)
{
    QJsonObject choiceObj = choiceVal.toObject();
    QJsonValue respMsgVal = choiceObj["message"];
    QJsonObject respMsgObj = respMsgVal.toObject();
    // Maybe validate that respMsgObj["role"] == "assistant"?
    QJsonValue respContVal = respMsgObj["content"];
    QString resp = respContVal.toString().trimmed();
    qDebug() << "Final Response Text: " << resp;

    _latestChat = appendNewAssistantMsg(_latestChat, resp);
    saveChat(_latestChat);

    // We emit here instead of return, because the value comes back
    // asyncronously. You'll have to catch this signal to get the response.
    emit apiResponded(resp);

    // Alternatively, we can just use the callback:
    if (_successCallback) { _successCallback(resp); }
}


