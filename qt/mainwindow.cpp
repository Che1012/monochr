#include "mainwindow.h"
#include "ui_mainwindow.h"
#include "usbhandler.h"
#include <QtCharts/QtCharts>


MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
{
    ui->setupUi(this);

    usbThread = new QThread();
    usbReader = new Reader(&usb, &scene);

    connect(usbReader, SIGNAL(resultChanged(QStringList)), this, SLOT(read()));
    connect(usbThread, SIGNAL(started()), usbReader, SLOT(readUsb()));
    connect(usbReader, SIGNAL(finished()), usbThread, SLOT(quit()));
    usbReader->moveToThread(usbThread);
}

MainWindow::~MainWindow()
{
   usbReader->stop();
    delete ui;
}


void MainWindow::on_showDevicesBtn_clicked()
{
    QString info;

    ui->deviceNumbText->display(usb.showDevices(&info));

    QTextStream deviceList(&info);
    QString desc;
    QStringList listDev;

    while (!deviceList.atEnd()) {
        deviceList >> desc;
        if (desc == "Description=") {
            QString str;

            desc = "";
            QTextStream stream(&desc);

            deviceList >> str;
            stream << str;
            deviceList >> str;

            while(str != "ftHandle=") {
                stream << " " << str;
                deviceList >> str;
            }

            deviceList >> str;
            listDev.push_back(desc);
        }
    }
    ui->deviceList->clear();
    ui->deviceList->addItems(listDev);

    ui->infoList->setPlainText(info);
}

void MainWindow::on_readBtn_clicked()
{
    usbThread->start();
}

void MainWindow::on_initBtn_clicked()
{
    constexpr int size_buffer = 65536;
    QString str = ui->deviceList->currentText();

    qDebug() << "device :" << str;
    QByteArray qb = str.toUtf8();
    char* desc = qb.data();

    usb.setSyncFIFO(size_buffer, size_buffer, desc);
}

void MainWindow::on_pushButton_clicked()
{
    usbReader->stop();
    usb.closeHandle();
}

void MainWindow::read()
{
    // Plot update here
    QStringList list = usbReader->result();
    QChart *linesChart  = new QChart();
    QLineSeries *series = new QLineSeries();



    //    for (int i = 0; i < list.size(); i++)


    qDebug() << "HERE";
}
