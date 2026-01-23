import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "CurrencyData.js" as CurrencyData

ColumnLayout {
  id: root

  property var cfg: pluginApi?.pluginSettings || ({})

  // Currency model from shared CurrencyData.js
  property var currencyModel: CurrencyData.buildComboModel(false)
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  // Display mode options
  property var displayModeModel: [
    {
      "key": "icon",
      "name": "Icon only"
    },
    {
      "key": "compact",
      "name": "Compact (rate number)"
    },
    {
      "key": "full",
      "name": "Full (1 USD = 0.85 EUR)"
    }
  ]
  property var pluginApi: null

  // Refresh interval options (in minutes)
  property var refreshIntervalModel: [
    {
      "key": "15",
      "name": "15 minutes"
    },
    {
      "key": "30",
      "name": "30 minutes"
    },
    {
      "key": "60",
      "name": "1 hour"
    },
    {
      "key": "180",
      "name": "3 hours"
    },
    {
      "key": "360",
      "name": "6 hours"
    },
    {
      "key": "720",
      "name": "12 hours"
    }
  ]
  property string valueRefreshInterval: String(cfg.refreshInterval ?? defaults.refreshInterval ?? 60)

  // Global currency settings (used by launcher, widget, and panel)
  property string valueSourceCurrency: cfg.sourceCurrency || defaults.sourceCurrency || "USD"
  property string valueTargetCurrency: cfg.targetCurrency || defaults.targetCurrency || "EUR"

  // Widget settings
  property string valueWidgetDisplayMode: cfg.widgetDisplayMode || defaults.widgetDisplayMode || "icon"

  function saveSettings() {
    if (!pluginApi)
      return;
    pluginApi.pluginSettings.sourceCurrency = valueSourceCurrency;
    pluginApi.pluginSettings.targetCurrency = valueTargetCurrency;
    pluginApi.pluginSettings.widgetDisplayMode = valueWidgetDisplayMode;
    pluginApi.pluginSettings.refreshInterval = parseInt(valueRefreshInterval);
    pluginApi.saveSettings();
  }

  spacing: Style.marginL

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      Layout.bottomMargin: Style.marginS
      Layout.fillWidth: true
      label: "General Settings"
    }

    // TODO: change to searchable combo box
    NComboBox {
      Layout.fillWidth: true
      currentKey: valueSourceCurrency
      description: "Default currency to convert from"
      label: "Source Currency"
      minimumWidth: 300
      model: currencyModel

      onSelected: key => {
        valueSourceCurrency = key;
      }
    }

    // TODO: change to searchable combo box
    NComboBox {
      Layout.fillWidth: true
      currentKey: valueTargetCurrency
      description: "Default currency to convert to"
      label: "Target Currency"
      minimumWidth: 300
      model: currencyModel

      onSelected: key => {
        valueTargetCurrency = key;
      }
    }
  }
  NDivider {
    Layout.bottomMargin: Style.marginM
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
  }
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      Layout.bottomMargin: Style.marginS
      // description: "Configure the bar widget appearance and behavior"
      Layout.fillWidth: true
      label: "Widget Settings"
    }
    NComboBox {
      Layout.fillWidth: true
      currentKey: valueWidgetDisplayMode
      description: "How much information to show in the bar widget"
      label: "Display Mode"
      minimumWidth: 250
      model: displayModeModel

      onSelected: key => {
        valueWidgetDisplayMode = key;
      }
    }
    NComboBox {
      Layout.fillWidth: true
      currentKey: valueRefreshInterval
      defaultValue: defaults.refreshInterval
      description: "How often to refresh exchange rates automatically"
      label: "Auto-refresh Interval"
      minimumWidth: 250
      model: refreshIntervalModel

      onSelected: key => valueRefreshInterval = key
    }
  }
  Item {
    Layout.fillHeight: true
  }
}
