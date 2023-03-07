#include "aiconnector.h"

AiConnector::AiConnector(QObject *parent)
    : QObject{parent}
{
    _appDirPath =
            QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
}

void AiConnector::sendSingleMessage(QString msg)
{
    qDebug() << "Sending: " << msg;

    QNetworkAccessManager *manager = new QNetworkAccessManager(this);

    // create json payload
    QJsonObject messageObj;
    messageObj.insert("role", "user");
    messageObj.insert("content", msg);

    QJsonArray messageList;
    messageList.append(messageObj);

    QJsonObject rootDataObj;
    rootDataObj.insert("model", "gpt-3.5-turbo");
    rootDataObj.insert("messages", messageList);
    rootDataObj.insert("frequency_penalty", 0);
    rootDataObj.insert("max_tokens", 256);
    rootDataObj.insert("presence_penalty", 0);
    rootDataObj.insert("temperature", 0.7);
    rootDataObj.insert("top_p", 1);
    rootDataObj.insert("stream", false);

    // serialize data
    QJsonDocument jsonDoc(rootDataObj);
    QByteArray postData = jsonDoc.toJson();

    // Construct authorization key
    QString key = loadKey();
    if (key == "") { return; }

    QString authVal = "Bearer " + key;

    // Create request and set the headers
    QUrl url("https://api.openai.com/v1/chat/completions");
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", authVal.toLocal8Bit());

    // Send POST request
    QNetworkReply *reply = manager->post(request, postData);

    connect(reply, &QNetworkReply::finished, [=]() {
        if (reply->error() != QNetworkReply::NoError) {
            qDebug() << "Error: " << reply->errorString();
        }
        else {
            QByteArray response = reply->readAll();

            // Parse out the response:

            QJsonParseError responseParseError;
            auto responseDoc =
                    QJsonDocument::fromJson(response, &responseParseError);
            bool isParseError = (responseDoc.isNull());
            if (isParseError) {
                qDebug() << "Error parsing response: " << response
                         << " Error string: "
                         << responseParseError.errorString();
            }
            else {
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

                QJsonValue choiceValue = responseDoc["choices"];
                QJsonArray choiceList = choiceValue.toArray();

                // Maybe validate list size > 0
                for (int i = 0; i < choiceList.size(); ++i) {
                    QJsonValue choiceVal = choiceList[i];
                    QJsonObject choiceObj = choiceVal.toObject();
                    QJsonValue respMsgVal = choiceObj["message"];
                    QJsonObject respMsgObj = respMsgVal.toObject();
                    // Maybe validate that respMsgObj["role"] == "assistant"
                    QJsonValue respContVal = respMsgObj["content"];
                    QString respContStr = respContVal.toString().trimmed();
                    qDebug() << "Response: " << respContStr;
                }
            }

        }
        reply->deleteLater();
    });
}

QString AiConnector::loadKey()
{
    QString keyPath = _appDirPath + "/apikey";
    QFile file(keyPath);
    bool isOpen = file.open(QIODevice::ReadOnly);
    if (!isOpen) {
        qWarning() << "Cannot open key file for reading at: " << keyPath;
        return "";
    }
    QTextStream fileStream(&file);
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
        qWarning() << "Cannot open key file for writing at: " << keyPath;
        return;
    }
    QTextStream fileStream(&file);
    fileStream << key;
    file.close();
}


