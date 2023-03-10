#ifndef CONTENTLOADER_H
#define CONTENTLOADER_H

#include <QObject>

#include "fileinterface.h"

class ContentLoader : public QObject
{
    Q_OBJECT
public:
    explicit ContentLoader(QObject *parent = nullptr);

    Q_INVOKABLE QString loadChat();


signals:

};

#endif // CONTENTLOADER_H
