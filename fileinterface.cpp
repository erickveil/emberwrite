#include "fileinterface.h"

FileInterface::FileInterface(QObject *parent)
    : QObject{parent}
{
    _appDirPath =
            QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
}

void FileInterface::setFileLoadCb(std::function<void (QByteArray)> cb)
{
    _fileLoadedCb = cb;
}

void FileInterface::setFileWriteCb(std::function<void ()> cb)
{
    _fileWriteDoneCb = cb;
}

QByteArray FileInterface::loadFile(QString filepath)
{
    _file.setFileName(filepath);
    bool isOpen = _file.open(QIODevice::ReadOnly);
    if (!isOpen) {
        qWarning() << "Cannot open file for reading at: " << filepath
                   << " Error: " << _file.errorString();
        emit fileError(_file.errorString());
        return "";
    }
    return onFileReadyRead();
}

void FileInterface::writeFile(QString filepath, QByteArray data)
{
    _file.setFileName(filepath);
    bool isOpen = _file.open(QIODevice::WriteOnly);
    if (!isOpen) {
        qWarning() << "Cannot open file for writing at: " << filepath
                   << " Error: " << _file.errorString();
        emit fileError(_file.errorString());
        return;
    }

    qint64 bytesWritten = _file.write(data);
    onFileWriteComplete(bytesWritten);
}

QByteArray FileInterface::loadChatFile()
{
    QString chatPath = _appDirPath + "/chat.json";
    return loadFile(chatPath);
}

void FileInterface::saveChatFile(QJsonDocument chat)
{
    QString chatPath = _appDirPath + "/chat.json";
    writeFile(chatPath, chat.toJson());
}

QByteArray FileInterface::onFileReadyRead()
{
    QByteArray data = _file.readAll();
    emit fileLoaded(data);
    if (_fileLoadedCb) { _fileLoadedCb(data); }
    _file.close();
    return data;
}

void FileInterface::onFileWriteComplete(qint64 numBytes)
{
    emit fileWriteDone(numBytes);
    if (_fileWriteDoneCb) { _fileWriteDoneCb(); }
    _file.close();
}
