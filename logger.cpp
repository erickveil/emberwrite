#include "logger.h"

Logger *Logger::Instance()
{
    instantiate();
    return _instance;
}

void Logger::instantiate()
{
    if (_instance == nullptr) {
        _instance = new Logger();
    }
}

void Logger::init(QObject* qmlObj)
{
    _qmlObj = qmlObj;
}

void Logger::warning(QString msg)
{
    Logger::instantiate();

    // to console
    qWarning() << msg;

    // to file
    FileInterface file;
    QString logPath =
            QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) +
            "/warnings.txt";
    file.appendFile(logPath, (msg + "\n").toLocal8Bit());

    // pop-up
    QMetaObject::invokeMethod(_qmlObj, "popUpWarning", Q_ARG(QVariant, msg));

}

Logger::Logger()
{

}
