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
#ifndef MAINWIDGET_H
#define MAINWIDGET_H

#include <QWidget>
#include <QSerialPort>

namespace Ui {
class MainWidget;
}

class MainWidget : public QWidget
{
    Q_OBJECT

public:
    explicit MainWidget(QWidget *parent = nullptr);
    ~MainWidget();

private slots:
    void on_goButton_clicked();

private:
    uint32_t readRegister(uint8_t page, uint8_t address);
    void sendInstruction(uint8_t i);
    void error(const QString &error);
    QString fixedPoint1dot23ToString(uint32_t fp);

private:
    Ui::MainWidget *ui;
    QSerialPort m_serial;
};

#endif // MAINWIDGET_H
