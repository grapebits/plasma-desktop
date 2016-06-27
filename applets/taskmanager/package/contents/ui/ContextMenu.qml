/***************************************************************************
 *   Copyright (C) 2012-2016 by Eike Hein <hein@kde.org>                   *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .        *
 ***************************************************************************/

import QtQuick 2.0

import org.kde.plasma.plasmoid 2.0

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents

PlasmaComponents.ContextMenu {
    id: menu

    placement: {
        if (plasmoid.location == PlasmaCore.Types.LeftEdge) {
            return PlasmaCore.Types.RightPosedTopAlignedPopup;
        } else if (plasmoid.location == PlasmaCore.Types.TopEdge) {
            return PlasmaCore.Types.BottomPosedLeftAlignedPopup;
        } else {
            return PlasmaCore.Types.TopPosedLeftAlignedPopup;
        }
    }

    minimumWidth: visualParent.width

    onStatusChanged: {
        if (visualParent && visualParent.m.LauncherUrlWithoutIcon != null && status == PlasmaComponents.DialogStatus.Open) {
            launcherToggleAction.checked = (tasksModel.launcherPosition(visualParent.m.LauncherUrlWithoutIcon) != -1);
        } else if (status == PlasmaComponents.DialogStatus.Closed) {
            menu.destroy();
        }
    }

    function show() {
        loadDynamicLaunchActions(visualParent.m.LauncherUrlWithoutIcon);
        backend.ungrabMouse(visualParent);
        openRelative();
    }

    function newMenuItem(parent) {
        return Qt.createQmlObject(
            "import org.kde.plasma.components 2.0 as PlasmaComponents;" +
            "PlasmaComponents.MenuItem {}",
            parent);
    }

    function newSeparator(parent) {
        return Qt.createQmlObject(
            "import org.kde.plasma.components 2.0 as PlasmaComponents;" +
            "PlasmaComponents.MenuItem { separator: true }",
            parent);
    }

    function loadDynamicLaunchActions(launcherUrl) {
        var actionList = backend.jumpListActions(launcherUrl, menu);

        for (var i = 0; i < actionList.length; ++i) {
            var item = newMenuItem(menu);
            item.action = actionList[i];
            menu.addMenuItem(item, virtualDesktopsMenuItem);
        }

        if (actionList.length > 0) {
            menu.addMenuItem(newSeparator(menu), virtualDesktopsMenuItem);
        }

        var actionList = backend.recentDocumentActions(launcherUrl, menu);

        for (var i = 0; i < actionList.length; ++i) {
            var item = newMenuItem(menu);
            item.action = actionList[i];
            menu.addMenuItem(item, virtualDesktopsMenuItem);
        }

        if (actionList.length > 0) {
            menu.addMenuItem(newSeparator(menu), virtualDesktopsMenuItem);
        }
    }

    PlasmaComponents.MenuItem {
        id: virtualDesktopsMenuItem

        visible: virtualDesktopInfo.numberOfDesktops > 1
            && (visualParent && visualParent.m.IsLauncher !== true
            && visualParent.m.IsStartup !== true
            && visualParent.m.IsVirtualDesktopChangeable === true)

        enabled: visible

        text: i18n("Move To Desktop")

        Connections {
            target: virtualDesktopInfo

            onNumberOfDesktopsChanged: virtualDesktopsMenu.refresh()
            onDesktopNamesChanged: virtualDesktopsMenu.refresh()
        }

        PlasmaComponents.ContextMenu {
            id: virtualDesktopsMenu

            visualParent: virtualDesktopsMenuItem.action

            function refresh() {
                clearMenuItems();

                if (virtualDesktopInfo.numberOfDesktops <= 1) {
                    return;
                }

                var menuItem = menu.newMenuItem(virtualDesktopsMenu);
                menuItem.text = i18n("Move To Current Desktop");
                menuItem.enabled = Qt.binding(function() {
                    return menu.visualParent && menu.visualParent.m.VirtualDesktop != virtualDesktopInfo.currentDesktop;
                });
                menuItem.clicked.connect(function() {
                    tasksModel.requestVirtualDesktop(menu.visualParent.modelIndex(), 0);
                });

                menuItem = menu.newMenuItem(virtualDesktopsMenu);
                menuItem.text = i18n("All Desktops");
                menuItem.checkable = true;
                menuItem.checked = Qt.binding(function() {
                    return menu.visualParent && menu.visualParent.m.IsOnAllVirtualDesktops === true;
                });
                menuItem.clicked.connect(function() {
                    tasksModel.requestVirtualDesktop(menu.visualParent.modelIndex(), 0);
                });
                backend.setActionGroup(menuItem.action);

                menu.newSeparator(virtualDesktopsMenu);

                for (var i = 0; i < virtualDesktopInfo.desktopNames.length; ++i) {
                    menuItem = menu.newMenuItem(virtualDesktopsMenu);
                    menuItem.text = i18nc("1 = number of desktop, 2 = desktop name", "%1 Desktop %2", i + 1, virtualDesktopInfo.desktopNames[i]);
                    menuItem.checkable = true;
                    menuItem.checked = Qt.binding((function(i) {
                        return function() { return menu.visualParent && menu.visualParent.m.VirtualDesktop == (i + 1) };
                    })(i));
                    menuItem.clicked.connect((function(i) {
                        return function() { return tasksModel.requestVirtualDesktop(menu.visualParent.modelIndex(), i + 1); };
                    })(i));
                    backend.setActionGroup(menuItem.action);
                }

                menu.newSeparator(virtualDesktopsMenu);

                menuItem = menu.newMenuItem(virtualDesktopsMenu);
                menuItem.text = i18n("New Desktop");
                menuItem.clicked.connect(function() {
                    tasksModel.requestVirtualDesktop(menu.visualParent.modelIndex(), virtualDesktopInfo.numberOfDesktops + 1)
                });
            }

            Component.onCompleted: refresh()
        }
    }

     PlasmaComponents.MenuItem {
        id: activitiesDesktopsMenuItem

        visible: activityInfo.numberOfRunningActivities > 1
            && (visualParent && !visualParent.isLauncher
            && !visualParent.isStartup)

        enabled: visible

        text: i18n("Move To Activity")

        Connections {
            target: activityInfo

            onNumberOfRunningActivitiesChanged: activitiesDesktopsMenu.refresh()
        }

        PlasmaComponents.ContextMenu {
            id: activitiesDesktopsMenu

            visualParent: activitiesDesktopsMenuItem.action

            function refresh() {
                clearMenuItems();

                if (activityInfo.numberOfRunningActivities <= 1) {
                    return;
                }

                var menuItem = menu.newMenuItem(activitiesDesktopsMenu);
                menuItem.text = i18n("Add To Current Activity");
                menuItem.enabled = Qt.binding(function() {
                    return menu.visualParent && menu.visualParent.m.Activities.length > 0 &&
                           menu.visualParent.m.Activities.indexOf(activityInfo.currentActivity) < 0;
                });
                menuItem.clicked.connect(function() {
                    tasksModel.requestActivities(menu.visualParent.modelIndex(), menu.visualParent.m.Activities.concat(activityInfo.currentActivity));
                });

                menuItem = menu.newMenuItem(activitiesDesktopsMenu);
                menuItem.text = i18n("All Activities");
                menuItem.checkable = true;
                menuItem.checked = Qt.binding(function() {
                    return menu.visualParent && menu.visualParent.m.Activities.length === 0;
                });
                menuItem.clicked.connect(function() {
                    var checked = menuItem.checked;
                    var newActivities = undefined; // will cast to an empty QStringList i.e all activities
                    if (!checked) {
                        newActivities = new Array(activityInfo.currentActivity);
                    }
                    tasksModel.requestActivities(menu.visualParent.modelIndex(), newActivities);
                });

                menu.newSeparator(activitiesDesktopsMenu);

                var runningActivities = activityInfo.runningActivities();
                for (var i = 0; i < runningActivities.length; ++i) {
                    var activityId = runningActivities[i];

                    menuItem = menu.newMenuItem(activitiesDesktopsMenu);
                    menuItem.text = activityInfo.activityName(runningActivities[i]);
                    menuItem.checkable = true;
                    menuItem.checked = Qt.binding( (function(activityId) {
                        return function() {
                            return menu.visualParent && menu.visualParent.m.Activities.indexOf(activityId) >= 0;
                        };
                    })(activityId));
                    menuItem.clicked.connect((function(activityId) {
                        return function () {
                            var checked = menuItem.checked;
                            var newActivities = menu.visualParent.m.Activities;
                            if (checked) {
                                newActivities = newActivities.concat(activityId);
                            } else {
                                var index = newActivities.indexOf(activityId)
                                if (index < 0) {
                                    return;
                                }
                                newActivities = newActivities.splice(index, 1);
                            }
                            return tasksModel.requestActivities(menu.visualParent.modelIndex(), newActivities);
                        };
                    })(activityId));
                }

                menu.newSeparator(activitiesDesktopsMenu);
            }

            Component.onCompleted: refresh()
        }
    }


    PlasmaComponents.MenuItem {
        visible: (visualParent && visualParent.m.IsLauncher !== true && visualParent.m.IsStartup !== true)

        enabled: visualParent && visualParent.m.IsMinimizable === true

        checkable: true
        checked: visualParent && visualParent.m.IsMinimized === true

        text: i18n("Minimize")

        onClicked: tasksModel.requestToggleMinimized(visualParent.modelIndex())
    }

    PlasmaComponents.MenuItem {
        visible: (visualParent && visualParent.m.IsLauncher !== true && visualParent.m.IsStartup !== true)

        enabled: visualParent && visualParent.m.IsMaximizable === true

        checkable: true
        checked: visualParent && visualParent.m.IsMaximized === true

        text: i18n("Maximize")

        onClicked: tasksModel.requestToggleMaximized(visualParent.modelIndex())
    }

    PlasmaComponents.MenuItem {
        visible: (visualParent && visualParent.m.IsLauncher !== true && visualParent.m.IsStartup !== true)

        enabled: visualParent && visualParent.m.LauncherUrlWithoutIcon != null

        text: i18n("Start New Instance")
        icon: "system-run"

        onClicked: tasksModel.requestNewInstance(visualParent.modelIndex())
    }

    PlasmaComponents.MenuItem {
        id: launcherToggleAction

        visible: (visualParent && visualParent.m.IsLauncher !== true && visualParent.m.IsStartup !== true)

        enabled: visualParent && visualParent.m.LauncherUrlWithoutIcon != null

        checkable: true

        text: i18n("Show A Launcher When Not Running")

        onClicked: {
            if (tasksModel.launcherPosition(visualParent.m.LauncherUrlWithoutIcon) != -1) {
                tasksModel.requestRemoveLauncher(visualParent.m.LauncherUrlWithoutIcon);
            } else {
                tasksModel.requestAddLauncher(visualParent.m.LauncherUrl);
            }
        }
    }

    PlasmaComponents.MenuItem {
        visible: (visualParent && visualParent.m.IsLauncher === true)

        text: i18n("Remove Launcher")

        onClicked: tasksModel.requestRemoveLauncher(visualParent.m.LauncherUrlWithoutIcon);
    }


    PlasmaComponents.MenuItem {
        id: moreActionsMenuItem

        visible: (visualParent && visualParent.m.IsLauncher !== true && visualParent.m.IsStartup !== true)

        enabled: visible

        text: i18n("More Actions")

        PlasmaComponents.ContextMenu {
            visualParent: moreActionsMenuItem.action

            PlasmaComponents.MenuItem {
                enabled: menu.visualParent && menu.visualParent.m.IsMovable === true

                text: i18n("Move")
                icon: "transform-move"

                onClicked: tasksModel.requestMove(menu.visualParent.modelIndex())
            }

            PlasmaComponents.MenuItem {
                enabled: menu.visualParent && menu.visualParent.m.IsResizable === true

                text: i18n("Resize")

                onClicked: tasksModel.requestResize(menu.visualParent.modelIndex())
            }

            PlasmaComponents.MenuItem {
                checkable: true
                checked: menu.visualParent && menu.visualParent.m.IsKeepAbove === true

                text: i18n("Keep Above Others")
                icon: "go-up"

                onClicked: tasksModel.requestToggleKeepAbove(menu.visualParent.modelIndex())
            }

            PlasmaComponents.MenuItem {
                checkable: true
                checked: menu.visualParent && menu.visualParent.m.IsKeepBelow === true

                text: i18n("Keep Below Others")
                icon: "go-down"

                onClicked: tasksModel.requestToggleKeepBelow(menu.visualParent.modelIndex())
            }

            PlasmaComponents.MenuItem {
                enabled: menu.visualParent && menu.visualParent.m.IsFullScreenable === true

                checkable: true
                checked: menu.visualParent && menu.visualParent.m.IsFullScreen === true

                text: i18n("Fullscreen")
                icon: "view-fullscreen"

                onClicked: tasksModel.requestToggleFullScreen(menu.visualParent.modelIndex())
            }

            PlasmaComponents.MenuItem {
                enabled: menu.visualParent && menu.visualParent.m.IsShadeable === true

                checkable: true
                checked: menu.visualParent && menu.visualParent.m.IsShaded === true

                text: i18n("Shade")

                onClicked: tasksModel.requestToggleShaded(menu.visualParent.modelIndex())
            }

            PlasmaComponents.MenuItem {
                separator: true
            }

            PlasmaComponents.MenuItem {
                visible: (plasmoid.configuration.groupingStrategy != 0) && menu.visualParent.m.IsWindow === true

                checkable: true
                checked: menu.visualParent && menu.visualParent.m.IsGroupable === true

                text: i18n("Allow this program to be grouped")

                onClicked: tasksModel.requestToggleGrouping(menu.visualParent.modelIndex())
            }
        }
    }

    PlasmaComponents.MenuItem {
        property QtObject configureAction: null

        enabled: configureAction && configureAction.enabled

        text: configureAction ? configureAction.text : ""
        icon: configureAction ? configureAction.icon : ""

        onClicked: configureAction.trigger()

        Component.onCompleted: configureAction = plasmoid.action("configure")
    }

    PlasmaComponents.MenuItem {
        separator: true
    }

    PlasmaComponents.MenuItem {
        visible: (visualParent && visualParent.m.IsLauncher !== true && visualParent.m.IsStartup !== true)

        enabled: visualParent && visualParent.m.IsClosable === true

        text: i18n("Close")
        icon: "window-close"

        onClicked: tasksModel.requestClose(visualParent.modelIndex())
    }
}