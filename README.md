# HSWidgets

Add options to display widgets right on your homescreen.

## Building

[Theos](https://github.com/theos/theos) is required for building this project.

Currently it is also dependent on iOS 8.1 sdk as it includes c++ header files (which also reduces environmental dependencies).

## Layout Customization

The layout of the hswidgets is saved in `/var/mobile/Library/Preferences/com.dgh0st.hswidget.widgetlayouts.plist` file which can be modified manually to enable certain features that are currently buggy. Features such as expanded today widgets, which are disabled due to there not being a good/easy way to figure out the space an expanded widget should take up. The optional configurations like `normalModeRows`, `expandedModeRows`, `expandedModeHeight` and `isExpandedMode` can be used to enable the expanded widget and get consistent height for each widget separately. The plist file has the following format:

```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist SYSTEM "file://localhost/System/Library/DTDs/PropertyList.dtd">
<plist version="1.0">
<dict>
	<key>0</key><!-- Page number (0 based) -->
	<array><!-- array of widgets on this page -->
		<dict>
			<key>widgetClass</key>
			<string>HSTodayWidgetViewController</string><!-- class used for the widget -->
			<key>WidgetOptions</key>
			<dict>
				<key>normalModeRows</key>
				<integer>2</integer><!-- Specify a custom number of icon rows that this widget will take up when in non-expanded mode (all apple widgets take up 2) -->
				<key>expandedModeRows</key>
				<integer>3</integer><!-- Specify a custom number of icon rows that this widget will take up when in expanded mode -->
				<key>expandedModeHeight</key>
				<integer>256</integer><!-- Specify a custom height for expanded mode -->
				<key>isExpandedMode</key>
				<true/><!-- enable expanded mode for the today widget -->
				<key>widgetIdentifier</key>
				<string>com.apple.weather.WeatherAppTodayWidget</string><!-- the identifier for the today widget used by apple -->
			</dict>
			<key>WidgetOriginRow</key>
			<integer>2</integer><!-- origin icon row for this widget -->
		</dict>
	</array>
	<key>1</key>
	<array>
		<dict>
			<key>widgetClass</key>
			<string>HSClockWidgetViewController</string>
			<key>WidgetOptions</key>
			<dict>
				<key>NumRows</key>
				<integer>2</integer><!-- Specify the number of rows this clock should take up -->
			</dict>
			<key>WidgetOriginRow</key>
			<integer>0</integer>
		</dict>
		<dict>
			<key>widgetClass</key>
			<string>HSSpacerWidgetViewController</string>
			<key>WidgetOptions</key>
			<dict>
				<key>NumRows</key>
				<integer>1</integer><!-- Specify the number of rows this spacer should take up -->
			</dict>
			<key>WidgetOriginRow</key>
			<integer>3</integer>
		</dict>
	</array>
</dict>
</plist>
```

## How to create your own widgets

### 1. Setup header files and lib file

You will need to download all the `.h` file from this repository and place them in `$THEOS/include/HSWidgets` folder so you can import them.

You will also need to place the latest dylib of HSWidgets in the `$THEOS/lib` folder for linking. You can find this at `/Library/MobileSubstrate/DynamicLibraries/HSWidgets.dylib` (make sure to rename this to `libHSWidgets.dylib`).

The file structure should look like the following:

```
$THEOS
	lib
		libHSWidgets.dylib
	include
		HSWidgets
			HSAdditionalOptionsTableViewController.h
			HSAdditionalOptionsViewController.h
			HSAddNewWidgetView.h
			HSAddWidgetRootViewController.h
			HSWidgetViewController.h
```

### 3. Setup the theos template for project generation

Install the theos_template folder and place it in `$THEOS/template/ios/`. When you run `$THEOS/bin/nic.pl`, it should display `iphone/hswidget` as one of the options. 

Make sure to have a unique `HSWidgets class name` since this is what HSWidgets uses to differentiate between widgets.

### 4. Implementation notes

All custom widgets need to be a subclass of `HSWidgetViewController` (which is a `UIViewController`).

If you want to add additional options in the add new widgets view like Today Widgets then you will need to create a subclass of `HSAdditionalOptionsTableViewController` and override the `+(Class)addNewWidgetAdditionalOptionsClass` method. Take a look at HSTodayWidget for example.
