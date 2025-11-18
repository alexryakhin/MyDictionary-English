# Screenshots for My Dictionary Website

This directory contains screenshots for the My Dictionary website. The website is designed to automatically display these screenshots when available, and fall back to placeholder text if the images are not found.

## Required Screenshots

To add screenshots to your website, save your app screenshots with the following filenames:

1. **`screenshot-ios-main.jpg`** - Main iOS app screen showing the dictionary interface
2. **`screenshot-macos-interface.jpg`** - macOS app interface showing desktop experience
3. **`screenshot-quiz-mode.jpg`** - Quiz mode or interactive learning interface
4. **`screenshot-analytics.jpg`** - Analytics dashboard or progress tracking screen
5. **`screenshot-shared-dictionary.jpg`** - Shared dictionary or collaboration features
6. **`screenshot-settings.jpg`** - Settings or customization screen

## Image Requirements

- **Format**: JPG or PNG
- **Aspect Ratio**: 16:9 or 4:3 (the website will crop to fit)
- **Resolution**: At least 1200x800 pixels for good quality
- **File Size**: Keep under 500KB per image for fast loading

## How It Works

The website uses a fallback system:
1. If the screenshot image exists, it will be displayed
2. If the image fails to load or doesn't exist, the placeholder text will be shown instead
3. This ensures your website always looks good, even without screenshots

## Adding Your Screenshots

1. Take screenshots of your app on different devices/screens
2. Rename them to match the filenames above
3. Place them in this `images` directory
4. The website will automatically display them

## Tips for Great Screenshots

- Use high-quality screenshots with good lighting
- Show the most important features of your app
- Make sure text is readable
- Consider using different devices (iPhone, iPad, Mac) for variety
- Keep the interface clean and uncluttered

## Testing

After adding screenshots:
1. Open `index.html` in your browser
2. Check that the screenshots display correctly
3. Test on different screen sizes to ensure responsiveness
4. Verify that placeholders still show if images are missing
