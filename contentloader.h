#ifndef CONTENTLOADER_H
#define CONTENTLOADER_H

#include <QObject>

#include "aiconnector.h"
#include "fileinterface.h"
#include "logger.h"

class ContentLoader : public QObject
{
    Q_OBJECT

    QObject *_qmlMainWindowObj;
    AiConnector _api;

public:
    explicit ContentLoader(QObject *parent = nullptr);

    void init(QObject *qmlObj);

    Q_INVOKABLE QString loadChat();

    Q_INVOKABLE void saveChat(QString chatJson);

    /**
     * @brief appendNewUserMessage
     * Will append the user message to the chat, save it to
     * the file, then return the full chat with the appended
     * message.
     * @param msg
     * @return
     */
    Q_INVOKABLE QString appendNewUserMessage(QString msg);

    /**
     * @brief requestNewResponse
     * Will use the currently saved chat to make an api call.
     * Will emit apiResponded(response) when the api gets back
     * to us.
     */
    Q_INVOKABLE void requestNewResponse();

    Q_INVOKABLE bool isOldestMsg(QString msg);


signals:

private slots:
    void onApiResponded(QString response);
};

#endif // CONTENTLOADER_H
