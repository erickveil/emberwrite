#ifndef AICONNECTOR_H
#define AICONNECTOR_H

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

class AiConnector : public QObject
{
    Q_OBJECT

    QString _appDirPath;

public:
    explicit AiConnector(QObject *parent = nullptr);

    void sendSingleMessage(QString msg);
    QString loadKey();
    void saveKey(QString key);

signals:

};

#endif // AICONNECTOR_H
