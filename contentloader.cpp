#include "contentloader.h"

ContentLoader::ContentLoader(QObject *parent)
    : QObject{parent}
{

}

QString ContentLoader::loadChat()
{
    FileInterface file;
    return file.loadChatFile();
}
