#ifndef FILEINTERFACE_H
#define FILEINTERFACE_H

#include <functional>

#include <QDebug>
#include <QFile>
#include <QJsonDocument>
#include <QObject>
#include <QStandardPaths>

class FileInterface : public QObject
{
    Q_OBJECT

    QFile _file;

    std::function<void (QByteArray)> _fileLoadedCb;
    std::function<void ()> _fileWriteDoneCb;

    QString _appDirPath;

public:
    explicit FileInterface(QObject *parent = nullptr);
    void setFileLoadCb(std::function<void (QByteArray)> cb);
    void setFileWriteCb(std::function<void ()> cb);

    QByteArray loadFile(QString filepath);
    void writeFile(QString filepath, QByteArray data);
    void appendFile(QString filepath, QByteArray data);

    QByteArray loadChatFile();
    void saveChatFile(QJsonDocument chat);

signals:
    void fileLoaded(QByteArray data);
    void fileWriteDone(qint64 numBytes);
    void fileError(QString error);

private:
// No signals for files.
// See: https://doc.qt.io/qt-5/qfile.html
//private slots:

    QByteArray onFileReadyRead();
    void onFileWriteComplete(qint64 numBytes);

};

#endif // FILEINTERFACE_H
