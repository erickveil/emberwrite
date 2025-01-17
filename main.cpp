#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlComponent>
#include <QQmlContext>

#include <functional>

#include "aiconnector.h"
#include "contentloader.h"
#include "logger.h"

Logger *Logger::_instance = nullptr;

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
                     &app, [&](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);

        Logger *logger = Logger::Instance();
        logger->init(obj);
        loader.init(obj);

    }, Qt::QueuedConnection);

    engine.load(url);

    return app.exec();
}
