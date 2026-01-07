# Steam Price Watcher

Monitor Steam game prices and get notified when they reach your target price.

## Features

- 🎮 **Price Monitoring**: Automatically check Steam game prices at configurable intervals
- 🎯 **Target Prices**: Set your desired price for each game
- 🔔 **Desktop Notifications**: Get notified via notify-send when games reach your target price
- 📊 **Visual Indicator**: Bar widget shows a notification dot when games are at target price
- 💰 **Price Comparison**: See current price vs. target price with discount percentages
- ⚙️ **Easy Configuration**: Search games by App ID and add them to your watchlist
- 🔄 **Automatic Updates**: Prices are checked automatically based on your interval setting
- 🌍 **Multi-Currency**: Support for 40+ Steam currencies

## How to Use

### Adding Games to Watchlist

1. Open the plugin settings
2. Enter the Steam App ID in the search field
   - You can find the App ID in the game's Steam store page URL
   - Example: For CS2 the URL is `store.steampowered.com/app/730/`, so the App ID is `730`
3. Click "Search"
4. The plugin will fetch the game details
5. Set your target price (the plugin suggests 20% below current price)
6. Click "Add to Watchlist"

### Monitoring Prices

Once games are added to your watchlist:

- The widget will check prices automatically at your configured interval (default: 30 minutes)
- When a game reaches or goes below your target price:
  - A notification dot appears on the bar widget
  - You receive a desktop notification
  - The game is highlighted in the panel
- Click the widget to see all games and their current prices

### Managing Your Watchlist

In the panel (click the widget):

- View all monitored games with current and target prices
- See which games have reached target price (🎯 indicator)
- Edit target prices by clicking the edit icon
- Remove games from watchlist
- Refresh prices manually with the refresh button

### Settings

- **Check Interval**: How often to check prices (15-1440 minutes)
  - Default: 30 minutes
  - ⚠️ Very short intervals may result in many API requests
- **Currency**: Choose from 40+ supported Steam currencies
  - USD, EUR, GBP, BRL, PLN, JPY, CNY, and many more
- **Game Search**: Search and add games by Steam App ID

## Technical Details

- **API**: Uses Steam Store API (`store.steampowered.com/api/appdetails`)
- **Currency**: Supports 40+ currencies (USD, EUR, GBP, BRL, PLN, JPY, CNY, RUB, etc.)
- **Data Storage**: Settings are stored in Noctalia's plugin configuration
- **Notifications**: Uses notify-send for desktop notifications

## Requirements

- Noctalia Shell v3.6.0 or higher
- Internet connection for API access
- `curl` command-line tool (for API requests)
- `notify-send` (for desktop notifications)

## Supported Languages

- Portuguese (pt)
- English (en)
- Spanish (es)
- French (fr)
- German (de)
- Italian (it)
- Japanese (ja)
- Dutch (nl)
- Russian (ru)
- Turkish (tr)
- Ukrainian (uk-UA)
- Chinese Simplified (zh-CN)

## Changelog

### Version 1.1.0

- Expanded currency support from 10 to 40+ currencies
- All major Steam-supported currencies now available (ARS, AUD, BRL, CAD, CHF, CLP, CNY, COP, CZK, DKK, EUR, GBP, HKD, HUF, IDR, ILS, INR, JPY, KRW, KZT, MXN, MYR, NOK, NZD, PEN, PHP, PLN, QAR, RON, RUB, SAR, SEK, SGD, THB, TRY, TWD, UAH, USD, UYU, VND, ZAR)

### Version 1.0.0

- Initial release
- Steam API integration
- Price monitoring with configurable intervals
- Target price alerts
- Desktop notifications
- Multi-language support

## Author

Lokize

## License

This plugin follows the same license as Noctalia Shell.

## Tips

- Set realistic target prices (20-30% below current price is usually good)
- Don't set check intervals too short (<30 minutes) to avoid excessive API requests
- Games that are free or don't have pricing information cannot be added
- Notifications are sent only once per game until you update the target price
- The plugin remembers which games have been notified to avoid spam

## Troubleshooting

**Problem**: No prices showing
**Solution**: Check your internet connection and verify the App ID is correct

**Problem**: Notifications not appearing
**Solution**: Make sure notify-send is installed and working on your system

**Problem**: "No games found" when searching
**Solution**: Verify the App ID is correct and the game exists on Steam

**Problem**: Prices not updating
**Solution**: Click the refresh button in the panel or wait for the next automatic check

## Future Enhancements

Potential features for future versions:

- Price history tracking and charts
- Historical low price information (integration with SteamDB or ITAD)
- Steam sale event notifications
- Bulk price threshold adjustments
- Export/import watchlist to JSON
