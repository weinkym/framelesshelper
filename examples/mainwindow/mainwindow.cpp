/*
 * MIT License
 *
 * Copyright (C) 2022 by wangwenx190 (Yuhang Zhao)
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#include "mainwindow.h"
#include "ui_MainWindow.h"
#include "ui_TitleBar.h"
#include <Utils>

FRAMELESSHELPER_USE_NAMESPACE

using namespace Global;

MainWindow::MainWindow(QWidget *parent, const Qt::WindowFlags flags) : FramelessMainWindow(parent, flags)
{
    setupUi();
}

MainWindow::~MainWindow() = default;

void MainWindow::changeEvent(QEvent *event)
{
    FramelessMainWindow::changeEvent(event);
    if (event->type() == QEvent::WindowStateChange) {
        Q_EMIT windowStateChanged();
    }
}

void MainWindow::setupUi()
{
    mainWindow.reset(new Ui::MainWindow);
    mainWindow->setupUi(this);

    const auto titleBarWidget = new QWidget(this);
    titleBar.reset(new Ui::TitleBar);
    titleBar->setupUi(titleBarWidget);

    const SystemTheme theme = SystemTheme::Light;
    const ResourceType resource = ResourceType::Icon;
    titleBar->minimizeButton->setIcon(qvariant_cast<QIcon>(Utils::getSystemButtonIconResource(SystemButtonType::Minimize, theme, resource)));
    titleBar->maximizeButton->setIcon(qvariant_cast<QIcon>(Utils::getSystemButtonIconResource(SystemButtonType::Maximize, theme, resource)));
    titleBar->closeButton->setIcon(qvariant_cast<QIcon>(Utils::getSystemButtonIconResource(SystemButtonType::Close, theme, resource)));

    QMenuBar *mb = menuBar();
    titleBar->horizontalLayout->insertWidget(1, mb);

    // This call to the setMenuWidget() function is only needed by this example
    // application to achieve some special effects, don't use it in your own
    // code if you don't know what's it for!
    setMenuWidget(titleBarWidget);

    setTitleBarWidget(titleBarWidget);

    setHitTestVisible(titleBar->iconButton);
    setHitTestVisible(titleBar->minimizeButton);
    setHitTestVisible(titleBar->maximizeButton);
    setHitTestVisible(titleBar->closeButton);

    connect(titleBar->minimizeButton, &QPushButton::clicked, this, &MainWindow::showMinimized);
    connect(titleBar->maximizeButton, &QPushButton::clicked, this, &MainWindow::toggleMaximized);
    connect(titleBar->closeButton, &QPushButton::clicked, this, &MainWindow::close);
    connect(this, &MainWindow::windowIconChanged, titleBar->iconButton, &QPushButton::setIcon);
    connect(this, &MainWindow::windowTitleChanged, titleBar->titleLabel, &QLabel::setText);
    connect(this, &MainWindow::windowStateChanged, this, [this](){
        const bool zoomed = isZoomed();
        const SystemTheme theme = SystemTheme::Light;
        const SystemButtonType button = (zoomed ? SystemButtonType::Restore : SystemButtonType::Maximize);
        const ResourceType resource = ResourceType::Icon;
        titleBar->maximizeButton->setIcon(qvariant_cast<QIcon>(Utils::getSystemButtonIconResource(button, theme, resource)));
        titleBar->maximizeButton->setToolTip(zoomed ? tr("Restore") : tr("Maximize"));
    });

    setWindowTitle(tr("Hello, World! - Qt MainWindow"));
}
