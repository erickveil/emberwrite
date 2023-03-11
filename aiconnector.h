#ifndef AICONNECTOR_H
#define AICONNECTOR_H

#include <functional>

#include <QByteArray>
#include <QDebug>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QObject>
#include <QStandardPaths>
#include <QString>
#include <QTextStream>
#include <QUrl>

#include "fileinterface.h"

class AiConnector : public QObject
{
    Q_OBJECT

    QString _appDirPath;
    QNetworkAccessManager *_manager = nullptr;

    std::function<void (QString)> _successCallback;
    // TODO: Setter for this and also use it where errors happen.
    std::function<void (QString, QAbstractSocket::SocketError)> _errorCallback;

    QJsonDocument _latestChat;

    FileInterface _chatPreloader;
    FileInterface _chatSaver;

    QString _key;

public:
    explicit AiConnector(QObject *parent = nullptr);
    ~AiConnector();

    void sendSingleMessage(QString msg);

    void setSuccessCallback(std::function<void (QString)> cb);

    /**
     * @brief requestChatCompletion
     * Sends the full chat to OpenAI to get completion.
     * Loads the chat from the chat file.
     * Saves the full result chat to the chat file.
     * @param newUserMsg
     */
    void requestChatCompletion(QString newUserMsg);

    void requestChatCompletion();

    QString loadKey();
    void saveKey(QString key);

    QJsonDocument loadChatFromFileAndAppend(QString newUserMsg);
private:
    QJsonDocument appendNewUserMsg(QJsonDocument fullChat, QString newMsg);
    QJsonDocument appendNewAssistantMsg(QJsonDocument fullChat, QString newMsg);
    QJsonDocument appendNewMsg(QJsonDocument fullChat, QString newMsg,
                               QString role);
    void saveChat(QJsonDocument chatDoc);
    void deliverToApi(QJsonDocument chatDoc);

    QByteArray createJsonPayload(QJsonDocument chatDoc);
    QString createAuthHeaderVal();
    QNetworkRequest createApiRequest(QString authVal);
    void onNetworkReplyFinished(QNetworkReply *reply);
    void parseApiResponse(QByteArray response);
    void parseResponseChoiceList(QJsonDocument responseDoc);
    void parseTokenUse(QJsonDocument responseDoc);
    void parseResponseChoice(QJsonValue choiceVal);

signals:

    void apiResponded(QString response);

};

#endif // AICONNECTOR_H
