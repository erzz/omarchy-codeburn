import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root

  moduleName: "codeburn"
  ipcTarget: "codeburn"

  readonly property color foreground: bar ? bar.barForeground : Color.foreground
  readonly property color urgent: bar ? bar.urgent : Color.urgent
  readonly property color dim: Qt.darker(foreground, 1.45)
  readonly property color subtleText: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.60)
  readonly property color accentColor: Color.accent
  readonly property color flameColor: "#ff7043"
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property string statusCommand: {
    var resolved = Qt.resolvedUrl("status.sh").toString().replace(/^file:\/\//, "")
    return resolved !== "" ? resolved : ((Quickshell.env("HOME") || "") + "/.config/omarchy/plugins/codeburn/status.sh")
  }
  readonly property int refreshIntervalSec: Math.max(60, Number(setting("refreshIntervalSec", 300)) || 300)

  property var statusData: null
  property bool refreshing: false
  property bool hasError: false
  property string errorMessage: ""
  property double lastUpdatedMs: 0
  property double nowMs: Date.now()

  // --- Data Accessors ---
  readonly property var current: statusData ? statusData.current : null
  readonly property real cost: current && current.cost !== undefined ? Number(current.cost) : 0
  readonly property int calls: current && current.calls !== undefined ? Number(current.calls) : 0
  readonly property int sessions: current && current.sessions !== undefined ? Number(current.sessions) : 0
  readonly property real inputTokens: current && current.inputTokens !== undefined ? Number(current.inputTokens) : 0
  readonly property real outputTokens: current && current.outputTokens !== undefined ? Number(current.outputTokens) : 0
  readonly property real cacheReadTokens: current && current.cacheReadTokens !== undefined ? Number(current.cacheReadTokens) : 0
  readonly property real cacheHitPercent: current && current.cacheHitPercent !== undefined ? Number(current.cacheHitPercent) : 0
  readonly property var topModels: current && Array.isArray(current.topModels) ? current.topModels : []
  readonly property var providerDetails: current && Array.isArray(current.providerDetails) ? current.providerDetails : []
  readonly property var topActivities: current && Array.isArray(current.topActivities) ? current.topActivities : []
  readonly property var optimize: statusData && statusData.optimize ? statusData.optimize : null
  readonly property var currency: statusData && statusData.currency ? statusData.currency : ({ symbol: "$", code: "USD" })
  readonly property string currencySymbol: currency && currency.symbol ? String(currency.symbol) : "$"

  readonly property bool isOnline: !hasError && statusData !== null
  readonly property string barCostText: isOnline ? formatCost(cost) : "--"
  readonly property string barStatusText: "󰈸 " + barCostText
  readonly property string barTooltipText: isOnline
    ? "CodeBurn: " + formatCost(cost) + " today · " + calls + " calls · " + sessions + " sessions (right-click to refresh)"
    : "CodeBurn: status unavailable (right-click to refresh)"

  visible: true
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function formatCost(val) {
    var num = Number(val || 0)
    if (num === 0) return currencySymbol + "0.00"
    if (num < 0.01) return "<" + currencySymbol + "0.01"
    return currencySymbol + num.toFixed(2)
  }

  function formatTokens(n) {
    var num = Number(n || 0)
    if (num >= 1000000000) return (num / 1000000000).toFixed(1) + "B"
    if (num >= 1000000) return (num / 1000000).toFixed(1) + "M"
    if (num >= 1000) return (num / 1000).toFixed(1) + "k"
    return String(Math.round(num))
  }

  function formatNumber(n) {
    var num = Number(n || 0)
    return num.toLocaleString()
  }

  function timeAgo(ms) {
    if (!ms || ms <= 0) return ""
    var diffSec = Math.max(0, Math.floor((nowMs - ms) / 1000))
    if (diffSec < 10) return "just now"
    if (diffSec < 60) return diffSec + "s ago"
    var diffMin = Math.floor(diffSec / 60)
    if (diffMin < 60) return diffMin + "m ago"
    var diffHr = Math.floor(diffMin / 60)
    return diffHr + "h ago"
  }

  function parseStatus(raw) {
    try {
      var trimmed = String(raw || "").trim()
      if (!trimmed) {
        hasError = true
        errorMessage = "Empty output from CodeBurn"
        return
      }
      var parsed = JSON.parse(trimmed)
      if (parsed && typeof parsed === "object") {
        if (parsed.error) {
          hasError = true
          errorMessage = String(parsed.error)
        } else {
          statusData = parsed
          hasError = false
          errorMessage = ""
          lastUpdatedMs = Date.now()
          nowMs = Date.now()
        }
      } else {
        hasError = true
        errorMessage = "Invalid JSON structure"
      }
    } catch (e) {
      console.warn("codeburn: JSON parse error", e)
      hasError = true
      errorMessage = "Unable to parse CodeBurn JSON output"
    }
  }

  function refresh() {
    if (statusProcess.running) return
    refreshing = true
    statusProcess.running = true
  }

  onOpenedChanged: if (opened) {
    nowMs = Date.now()
    if (Date.now() - lastUpdatedMs > 60000) {
      refresh()
    }
    if (panelFlick) panelFlick.contentY = 0
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  Process {
    id: statusProcess
    command: [root.statusCommand]
    running: false

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseStatus(text)
    }

    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (text && text.trim().length > 0) {
          console.warn("codeburn stderr:", text.trim())
        }
      }
    }

    onExited: function(exitCode) {
      root.refreshing = false
      if (exitCode !== 0) {
        root.hasError = true
        if (root.errorMessage === "") {
          root.errorMessage = "CodeBurn command exited with code " + exitCode
        }
      }
    }
  }

  Timer {
    id: pollTimer
    interval: root.refreshIntervalSec * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Timer {
    id: tickTimer
    interval: 15000
    running: root.opened
    repeat: true
    onTriggered: root.nowMs = Date.now()
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.barStatusText
    active: root.isOnline && root.cost > 0
    activeColor: root.accentColor
    fontSize: Style.font.bodySmall
    horizontalMargin: 4
    tooltipText: root.barTooltipText

    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) root.refresh()
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(420))
    contentHeight: panel.fittedContentHeight(contentColumn.implicitHeight, Style.space(660))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent

      onMoveRequested: function(dx, dy) {
        if (dy !== 0 && panelFlick) {
          panelFlick.contentY = Math.max(0, Math.min(
            panelFlick.contentY + dy * Style.space(60),
            Math.max(0, panelFlick.contentHeight - panelFlick.height)
          ))
        }
      }
      onActivateRequested: root.refresh()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(text) {
        if (text === "r" || text === "R") root.refresh()
      }

      Flickable {
        id: panelFlick
        anchors.fill: parent
        contentWidth: width
        contentHeight: contentColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
          id: contentColumn
          width: panelFlick.width
          spacing: Style.space(12)

          // ------------------------------------------------------------- HERO
          PanelHero {
            width: parent.width
            title: "CodeBurn"
            meta: root.isOnline
              ? (root.current && root.current.label ? String(root.current.label).toUpperCase() : "AI SPEND & USAGE")
              : "STATUS"
            detail: root.isOnline ? root.formatCost(root.cost) : "Offline"
            foreground: root.foreground
            fontFamily: root.fontFamily

            iconComponent: Component {
              Text {
                text: "󰈸"
                color: root.isOnline ? root.flameColor : root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.display
              }
            }

            trailingControl: Component {
              PanelActionButton {
                iconText: root.refreshing ? "󱑒" : "󰑐"
                tooltipText: "Refresh status (R)"
                foreground: root.foreground
                fontFamily: root.fontFamily
                onClicked: root.refresh()
              }
            }
          }

          // ------------------------------------------------------- ERROR CARD
          BorderSurface {
            id: errorCard
            visible: !root.isOnline
            width: parent.width
            implicitHeight: errorColumn.implicitHeight + Style.space(24)
            radius: Style.cornerRadius
            color: Style.selectedFillFor(root.urgent, root.urgent)
            borderSpec: Border.controlSpec("normal", root.urgent, root.urgent)

            Column {
              id: errorColumn
              anchors.centerIn: parent
              width: parent.width - Style.space(24)
              spacing: Style.space(8)

              Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Style.space(8)

                Text {
                  text: ""
                  color: root.urgent
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.subtitle
                }

                Text {
                  text: "CodeBurn Status Unavailable"
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.subtitle
                  font.bold: true
                }
              }

              Text {
                width: parent.width
                text: root.errorMessage !== ""
                  ? root.errorMessage
                  : "Unable to query codeburn status via npx or local CLI."
                color: root.subtleText
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
              }

              BorderSurface {
                anchors.horizontalCenter: parent.horizontalCenter
                implicitWidth: codeHint.implicitWidth + Style.space(16)
                implicitHeight: codeHint.implicitHeight + Style.space(8)
                radius: Style.cornerRadius
                color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.05)
                borderSpec: Border.controlSpec("normal", root.foreground, root.accentColor)

                Text {
                  id: codeHint
                  anchors.centerIn: parent
                  text: "npx codeburn status"
                  color: root.accentColor
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                }
              }
            }
          }

          // ---------------------------------------------------- SUMMARY METRICS
          Column {
            visible: root.isOnline
            width: parent.width
            spacing: Style.space(8)

            PanelSectionHeader {
              text: "TODAY OVERVIEW"
              foreground: root.foreground
              fontFamily: root.fontFamily
            }

            Row {
              width: parent.width
              spacing: Style.space(8)

              SummaryCell {
                label: "Cost"
                value: root.formatCost(root.cost)
                active: root.cost > 0
                highlightColor: root.flameColor
              }

              SummaryCell {
                label: "Calls"
                value: root.formatNumber(root.calls)
                active: root.calls > 0
              }

              SummaryCell {
                label: "Sessions"
                value: root.formatNumber(root.sessions)
                active: root.sessions > 0
              }

              SummaryCell {
                label: "Cache Hit"
                value: root.cacheHitPercent > 0 ? (root.cacheHitPercent.toFixed(1) + "%") : "0%"
                active: root.cacheHitPercent > 0
                highlightColor: root.accentColor
              }
            }

            // Secondary Token Counts Pill
            BorderSurface {
              width: parent.width
              implicitHeight: tokenRow.implicitHeight + Style.space(10)
              radius: Style.cornerRadius
              color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.035)
              borderSpec: Border.none()

              Row {
                id: tokenRow
                anchors.centerIn: parent
                spacing: Style.space(14)

                Row {
                  spacing: Style.space(4)
                  Text { text: "󰁅"; color: root.subtleText; font.family: root.fontFamily; font.pixelSize: Style.font.caption }
                  Text { text: "In: " + root.formatTokens(root.inputTokens); color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.caption; font.bold: true }
                }

                Text { text: "·"; color: root.dim; font.family: root.fontFamily }

                Row {
                  spacing: Style.space(4)
                  Text { text: "󰁝"; color: root.subtleText; font.family: root.fontFamily; font.pixelSize: Style.font.caption }
                  Text { text: "Out: " + root.formatTokens(root.outputTokens); color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.caption; font.bold: true }
                }

                Text { text: "·"; color: root.dim; font.family: root.fontFamily }

                Row {
                  spacing: Style.space(4)
                  Text { text: "󰒲"; color: root.subtleText; font.family: root.fontFamily; font.pixelSize: Style.font.caption }
                  Text { text: "Cache: " + root.formatTokens(root.cacheReadTokens); color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.caption; font.bold: true }
                }
              }
            }
          }

          // ---------------------------------------------------------- PROVIDERS
          PanelSeparator {
            visible: root.isOnline && root.providerDetails.length > 0
            foreground: root.foreground
          }

          Column {
            visible: root.isOnline && root.providerDetails.length > 0
            width: parent.width
            spacing: Style.space(8)

            PanelSectionHeader {
              text: "PROVIDERS"
              foreground: root.foreground
              fontFamily: root.fontFamily
            }

            Repeater {
              model: root.providerDetails

              Item {
                required property var modelData
                required property int index
                width: parent ? parent.width : 0
                implicitHeight: Style.space(32)

                BorderSurface {
                  anchors.fill: parent
                  radius: Style.cornerRadius
                  color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.03)
                  borderSpec: Border.none()

                  Row {
                    anchors.left: parent.left
                    anchors.leftMargin: Style.space(12)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Style.space(8)

                    Text {
                      text: "󰌹"
                      color: root.accentColor
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.body
                    }

                    Text {
                      text: String(modelData.label || modelData.id || "Provider")
                      color: root.foreground
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.body
                      font.bold: true
                    }
                  }

                  Text {
                    anchors.right: parent.right
                    anchors.rightMargin: Style.space(12)
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.formatCost(modelData.cost)
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                    font.bold: true
                  }
                }
              }
            }
          }

          // --------------------------------------------------------- TOP MODELS
          PanelSeparator {
            visible: root.isOnline && root.topModels.length > 0
            foreground: root.foreground
          }

          Column {
            visible: root.isOnline && root.topModels.length > 0
            width: parent.width
            spacing: Style.space(8)

            PanelSectionHeader {
              text: "TOP MODELS"
              foreground: root.foreground
              fontFamily: root.fontFamily
            }

            Repeater {
              model: root.topModels.slice(0, 5)

              ModelRow {
                width: parent ? parent.width : 0
                modelItem: modelData
                totalCost: root.cost
              }
            }
          }

          // ------------------------------------------------- TOP ACTIVITIES
          PanelSeparator {
            visible: root.isOnline && root.topActivities.length > 0
            foreground: root.foreground
          }

          Column {
            visible: root.isOnline && root.topActivities.length > 0
            width: parent.width
            spacing: Style.space(8)

            PanelSectionHeader {
              text: "TOP ACTIVITIES"
              foreground: root.foreground
              fontFamily: root.fontFamily
            }

            Repeater {
              model: root.topActivities.slice(0, 4)

              Item {
                required property var modelData
                required property int index
                width: parent ? parent.width : 0
                implicitHeight: Style.space(26)

                Row {
                  anchors.left: parent.left
                  anchors.leftMargin: Style.space(4)
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: Style.space(8)

                  Text {
                    text: String(modelData.name || "Activity")
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.bodySmall
                  }

                  Text {
                    visible: modelData.turns !== undefined && modelData.turns !== null
                    text: "(" + modelData.turns + " turns)"
                    color: root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                  }
                }

                Text {
                  anchors.right: parent.right
                  anchors.rightMargin: Style.space(4)
                  anchors.verticalCenter: parent.verticalCenter
                  text: root.formatCost(modelData.cost)
                  color: Number(modelData.cost) > 0 ? root.foreground : root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  font.bold: Number(modelData.cost) > 0
                }
              }
            }
          }

          // ------------------------------------------------------------- FOOTER
          PanelSeparator {
            foreground: root.foreground
          }

          Item {
            width: parent.width
            implicitHeight: Style.space(22)

            Row {
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.space(6)

              Text {
                visible: root.lastUpdatedMs > 0
                text: "Updated " + root.timeAgo(root.lastUpdatedMs)
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
              }
            }

            Row {
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.space(8)

              Text {
                text: "[R] Refresh  ·  [Esc] Close"
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
              }
            }
          }
        }
      }
    }
  }

  // ------------------------------------------------------- SUBCOMPONENTS
  component SummaryCell: Rectangle {
    id: cellRoot
    property string label: ""
    property string value: ""
    property bool active: false
    property color highlightColor: root.foreground

    width: (parent.width - parent.spacing * 3) / 4
    implicitHeight: cellLabels.implicitHeight + Style.space(12)
    radius: Style.cornerRadius
    color: cellRoot.active
      ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.05)
      : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.02)
    border.width: 1
    border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)

    Column {
      id: cellLabels
      anchors.centerIn: parent
      spacing: Style.space(2)

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: cellRoot.value
        color: cellRoot.active ? cellRoot.highlightColor : root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.subtitle
        font.bold: true
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: cellRoot.label.toUpperCase()
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        font.bold: true
        font.letterSpacing: 0.8
      }
    }
  }

  component ModelRow: Column {
    id: mRow
    property var modelItem: ({})
    property real totalCost: 1.0

    readonly property real itemCost: Number(modelItem.cost || 0)
    readonly property real ratio: totalCost > 0 ? Math.min(1.0, Math.max(0.0, itemCost / totalCost)) : 0

    width: parent ? parent.width : 0
    spacing: Style.space(4)

    Item {
      width: parent.width
      implicitHeight: Style.space(20)

      Row {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(6)

        Text {
          text: String(modelItem.name || "Model")
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          font.bold: itemCost > 0
        }

        Text {
          visible: modelItem.calls !== undefined && modelItem.calls !== null
          text: "(" + modelItem.calls + " calls)"
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
      }

      Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.formatCost(itemCost)
        color: itemCost > 0 ? root.accentColor : root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        font.bold: true
      }
    }

    // Visual distribution bar
    Rectangle {
      width: parent.width
      height: Style.space(4)
      radius: Style.cornerRadius
      color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)

      Rectangle {
        width: Math.max(0, parent.width * mRow.ratio)
        height: parent.height
        radius: Style.cornerRadius
        color: root.flameColor
        opacity: 0.85
      }
    }
  }
}
