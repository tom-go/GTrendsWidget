#define GT_MARGIN			40.f
#define GT_VIEW_HEIGHT		71.f / 3 * 2
#define SCROLL_INTERVAL 	(1.f/60.f)
#define TAG_SCROLL_VIEW 	10
#define TAG_INFO_VIEW		20
//#define TAG_SPINNER_VIEW	30
#define WALLPAPER_IMG		@"/System/Library/WeeAppPlugins/StocksWeeApp.bundle/WeeAppBackground.png"
#define UP_ARROW_IMG		@"/System/Library/WeeAppPlugins/StocksWeeApp.bundle/UpChangeArrow.png"
#define DOWN_ARROW_IMG		@"/System/Library/WeeAppPlugins/StocksWeeApp.bundle/DownChangeArrow.png"
#define PREFPATH			@"/var/mobile/Library/Preferences/jp.tom-go.GTrendsWidget.plist"
#define CACHEPATH			@"/var/mobile/Documents/.GTrendsWidget.plist"
#define MSG_LOADING 		@"Loading..."
#define MSG_OFFLINE 		@"Google Trends Offline"
#define MSG_ERROR_LOADING	@"Data Loading Error ;-("
#define MSG_ERROR_TIMEOUT	@"Connection timed out ;-("
#define RELEASE_SAFELY(__POINTER) { if (__POINTER){ [__POINTER release]; __POINTER = nil; } }

typedef enum {
    TypeNone = 0,
    TypeSpinner,
    TypeInfo
} InfoType;