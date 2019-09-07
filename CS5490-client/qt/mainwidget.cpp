/****************************************************************************
** This file is part of the CS5490 UEXT energy monitor project hosted at
** github.com/ec1oud/cs5490-uext-energy-monitor
** Copyright (C) 2019 Shawn Rutledge
**
** This file is free software; you can redistribute it and/or
** modify it under the terms of the GNU General Public License
** version 3 as published by the Free Software Foundation
** and appearing in the file LICENSE included in the packaging
** of this file.
**
** This code is distributed in the hope that it will be useful,
** but WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
** GNU General Public License for more details.
****************************************************************************/
#include "mainwidget.h"
#include "ui_mainwidget.h"
#include <QSerialPortInfo>
#include <QDebug>
#include <QThread>
#include <math.h>

static const QString temperatureFormat = QStringLiteral(u"%1.%2°C");

MainWidget::MainWidget(QWidget *parent) :
    QWidget(parent),
    ui(new Ui::MainWidget)
{
    ui->setupUi(this);
    const auto infos = QSerialPortInfo::availablePorts();
    for (const QSerialPortInfo &info : infos)
        ui->portComboBox->addItem(info.portName());
}

MainWidget::~MainWidget()
{
    delete ui;
}

void MainWidget::on_goButton_clicked()
{
    if (m_serial.portName() != ui->portComboBox->currentText()) {
        m_serial.close();
        m_serial.setPortName(ui->portComboBox->currentText());

        if (!m_serial.open(QIODevice::ReadWrite)) {
            error(tr("Can't open %1, error code %2")
                  .arg(m_serial.portName()).arg(m_serial.error()));
            return;
        }
        if (!m_serial.setBaudRate(600)) {
            error(tr("Can't set baud rate, error code %1")
                  .arg(m_serial.error()));
            return;
        }
    }
    qDebug() << "here goes";
//    sendInstruction(0x01); // reset
//    sendInstruction(0x03); // wake up
//    readRegister(0, 24); // chip status 1
//    readRegister(0, 25); // chip status 2
    uint32_t v = readRegister(16, 27); // temperature
    ui->temperatureValue->setText(temperatureFormat.arg(v >> 16).arg(v & 0xFFFF));
    ui->instCurrentValue->setText(fixedPoint1dot23ToString(readRegister(16, 2)));
    ui->instVoltageValue->setText(fixedPoint1dot23ToString(readRegister(16, 3)));
    ui->instActivePowerValue->setText(fixedPoint1dot23ToString(readRegister(16, 4)));
    ui->activePowerValue->setText(fixedPoint1dot23ToString(readRegister(16, 5)));
    ui->rmsCurrentValue->setText(fixedPoint1dot23ToString(readRegister(16, 6)));
    ui->rmsVoltageValue->setText(fixedPoint1dot23ToString(readRegister(16, 7)));
    ui->reactivePowerValue->setText(fixedPoint1dot23ToString(readRegister(16, 14)));
    ui->peakCurrentValue->setText(fixedPoint1dot23ToString(readRegister(0, 37)));
    ui->peakVoltageValue->setText(fixedPoint1dot23ToString(readRegister(0, 36)));
    ui->apparentPowerValue->setText(fixedPoint1dot23ToString(readRegister(16, 20)));
    ui->powerFactorValue->setText(fixedPoint1dot23ToString(readRegister(16, 21)));
    ui->totalActivePowerValue->setText(fixedPoint1dot23ToString(readRegister(16, 29)));
    ui->totalApparentPowerValue->setText(fixedPoint1dot23ToString(readRegister(16, 30)));
    ui->totalReactivePowerValue->setText(fixedPoint1dot23ToString(readRegister(16, 31)));
    sendInstruction(0x15); // continuous conversion
}

QString MainWidget::fixedPoint1dot23ToString(uint32_t fp)
{
    // https://en.wikipedia.org/wiki/Q_%28number_format%29
    if (fp >> 23)
        fp |= 0xff000000; // sign-extend it from 24 to 32 bits
    double value = double(int(fp)) * exp2(-23);
    return QString::number(value, 'f');
}

uint32_t MainWidget::readRegister(uint8_t page, uint8_t address)
{
    QByteArray sendBuf;
    sendBuf.append(char(page | 0x80));
    sendBuf.append(char(address));
    m_serial.write(sendBuf);

    int polls = 0;
    while (m_serial.bytesAvailable() < 3 && polls < 1000) {
        m_serial.waitForReadyRead(10);
        QCoreApplication::processEvents();
        ++polls;
    }
    qint64 len = m_serial.bytesAvailable();
    QByteArray recvBuf = m_serial.readAll();
    uint32_t ret = 0;
    if (len != 3) {
        error(tr("Expected 3 bytes, got %1").arg(recvBuf.size()));
    } else {
        ret = uint32_t(uint8_t(recvBuf[2]) << 16) + uint32_t(uint8_t(recvBuf[1]) << 8) + uint32_t(recvBuf[0]);
        qDebug() << page << address << "->" << len << recvBuf.toHex() << hex << ret;
    }
    return ret;
}

void MainWidget::sendInstruction(uint8_t i)
{
    QByteArray sendBuf;
    i |= 0xC0; // make it into an Instruction
    qDebug() << hex << i;
    sendBuf.append(char(i));
    m_serial.write(sendBuf);
}

void MainWidget::error(const QString &error)
{
    qWarning() << error;
    ui->textOutput->appendPlainText(error);
}
