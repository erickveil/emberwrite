#ifndef LOGGER_H
#define LOGGER_H

#include <QDebug>
#include <QMetaObject>
#include <QObject>
#include <QStandardPaths>
#include <QString>
#include <QVariant>

#include "fileinterface.h"

class Logger
{
    static Logger *_instance;

    QObject *_qmlObj;

public:
    static Logger * Instance();

    void init(QObject *qmlObj);

    void warning(QString msg);

private:
    Logger();
    static void instantiate();
};

#endif // LOGGER_H
