#include <QGuiApplication>
#include <QQmlApplicationEngine>

#include "aiconnector.h"


int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    AiConnector connector;
    connector.sendSingleMessage("Hello World");

    QQmlApplicationEngine engine;
    const QUrl url(u"qrc:/EmberWrite/main.qml"_qs);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
