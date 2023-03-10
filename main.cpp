#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include <functional>

#include "aiconnector.h"
#include "contentloader.h"


int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // -----====================================----------
    // Testing

    /*
    AiConnector connector;
    std::function<void(QString)> doneCb = [&](QString response) {
        qDebug() << "Response at main: " << response;
    };
    connector.setSuccessCallback(doneCb);
    connector.requestChatCompletion("Hello world");
    //connector.sendSingleMessage("Hello world");
    */

    // -----====================================----------

    QQmlApplicationEngine engine;

    QQmlContext *context = engine.rootContext();
    ContentLoader loader;
    context->setContextProperty("contentLoader", &loader);


    const QUrl url(u"qrc:/EmberWrite/main.qml"_qs);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
