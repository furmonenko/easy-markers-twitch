# Twitch Stream Marker OBS Script

A Lua script for OBS Studio that allows streamers to create Twitch stream markers with a single keypress. Stream markers make it easy to highlight important moments during your broadcast that you can revisit later in your VOD.

## Features

- Create Twitch stream markers with a customizable hotkey
- Automatically adds timestamp to marker descriptions
- Verifies stream is active before attempting to create markers
- Validates your Twitch credentials on startup
- Handles common errors with detailed explanations
- Includes testing buttons to verify your configuration
- Works on Windows systems

## Requirements

- OBS Studio 27.0 or newer
- A Twitch account with streaming privileges
- curl installed (already included in most Windows installations)
- A Twitch Developer Application with proper scopes

## Installation

1. Download the `east_markers_twitch.lua` script from the [releases page](https://github.com/furmonenko/obs-markers/releases/tag/easy_markers_twitch)

2. Place the file in your OBS scripts folder:
   - Windows: `%APPDATA%\obs-studio\scripts`
   - macOS: `~/Library/Application Support/obs-studio/scripts`
   - Linux: `~/.config/obs-studio/scripts`

3. In OBS Studio, go to Tools → Scripts

4. Click the "+" button and select the `twitch_marker.lua` file

5. Configure the script with your Twitch credentials (see next section)

## Configuration

### 1. Create a Twitch Developer Application

1. Go to the [Twitch Developer Console](https://dev.twitch.tv/console)
2. Log in with your Twitch account
3. Click on "Register Your Application"
4. Fill in the application details:
   - Name: `OBS Marker Script` (or any name you prefer)
   - OAuth Redirect URLs: `http://localhost`
   - Category: "Other"
5. Click "Create"
6. On the next page, note down your **Client ID**
7. Click "New Secret" and copy your **Client Secret**

### 2. Get Your OAuth Token

1. Go to [Twitch Token Generator](https://twitchtokengenerator.com/)
2. Click "Custom Scope Token"
3. Select the `channel:manage:broadcast` permission
4. Click "Generate Token!"
5. Authorize your Twitch account
6. Copy the **Access Token** that appears

### 3. Find Your Broadcaster ID

1. Go to [Twitch Tools](https://www.streamweasels.com/tools/convert-twitch-username-to-user-id/)
2. Enter your Twitch username
3. Click "Convert" and copy your **User ID**

### 4. Configure the Script in OBS

1. In OBS, go to Tools → Scripts
2. Select the Twitch Marker script
3. Fill in the following fields:
   - Client ID: *your Client ID from step 1*
   - OAuth Token: *your Access Token from step 2*
   - Broadcaster ID: *your User ID from step 3*
4. Enable "Debug Mode" if you want detailed logs
5. Click "Check Token" to verify your credentials

### 5. Set Up a Hotkey

1. In OBS, go to Settings → Hotkeys
2. Find "Add Twitch Marker" in the list
3. Click on the field and press the key combination you want to use
4. Click "Apply" to save your hotkey

## Usage

1. Start your Twitch stream using OBS
2. Press your configured hotkey whenever you want to create a marker
3. The script will create a marker on your stream with a description that includes the current time
4. After your stream, you can find these markers in your VOD

**Note:** Markers can only be created during an active stream. The script will notify you if you try to create a marker while not streaming.

## Troubleshooting

### Common Issues

#### "Invalid OAuth token" Error
- Your token may have expired (they typically last 60 days)
- Generate a new token using the steps above

#### "Missing scope" Error
- Your token doesn't have the required permissions
- Make sure to select the `channel:manage:broadcast` scope when generating your token

#### "Stream not active" Error
- You can only create markers during an active stream
- Make sure your stream is live on Twitch

#### Curl Not Found
- Ensure curl is installed on your system
- On Windows, it's usually available by default in newer versions

### Getting Help

If you encounter issues not covered here:

1. Enable Debug Mode in the script settings
2. Check the OBS log (Help → Log Files → View Current Log)
3. Create an issue on GitHub with the relevant log sections

## License

This project is licensed under the MIT License - see the license information at the top of the script for details.

## Acknowledgments

- Created by evilfurmo with assistance from Claude AI
- Based on the Twitch API [Create Stream Marker](https://dev.twitch.tv/docs/api/reference#create-stream-marker) endpoint
- Inspired by the need for quick and easy VOD marking during streams

## Contributing

Contributions are welcome! Feel free to submit pull requests or create issues for bugs and feature requests.

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add some amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request
