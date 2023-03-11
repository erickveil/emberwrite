#ifndef CONTENTLOADER_H
#define CONTENTLOADER_H

#include <QObject>

#include "aiconnector.h"
#include "fileinterface.h"

class ContentLoader : public QObject
{
    Q_OBJECT

    QObject *_qmlMainWindowObj;

public:
    explicit ContentLoader(QObject *parent = nullptr);

    void init(QObject *qmlObj);

    Q_INVOKABLE QString loadChat();

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


signals:

private slots:
    void onApiResponded(QString response);
};

#endif // CONTENTLOADER_H
