# SpellFlare - Landing Page

A beautiful, kid-friendly landing page for the SpellFlare iOS and watchOS app (v3.0).

## Features

- **Responsive Design**: Works on desktop, tablet, and mobile
- **App Branding**: Uses the same purple/cyan color scheme as the app
- **Kid & Parent Friendly**: Appealing to both audiences
- **Privacy Policy**: Comprehensive privacy documentation
- **Contact Section**: Email integration using device's mail system
- **watchOS Support**: Highlights Apple Watch compatibility

## File Structure

```
spellingBee-LandingPage/
├── index.html          # Main landing page
├── privacy.html        # Privacy policy page
├── css/
│   └── styles.css      # All styles
├── images/
│   ├── app-store-badge.svg
│   └── (screenshots go here)
└── README.md
```

## Required Screenshots

Add the following screenshots to the `images/` folder:

### iPhone Screenshots (Recommended: 1170x2532 or similar)
| Filename | Description |
|----------|-------------|
| `iphone-home.png` | Home screen showing level grid |
| `iphone-spelling.png` | Spelling input screen |
| `iphone-correct.png` | Correct answer celebration |
| `iphone-level-complete.png` | Level complete screen |
| `iphone-grades.png` | Grade selection/onboarding |

### Apple Watch Screenshots (Recommended: 396x484 or similar)
| Filename | Description |
|----------|-------------|
| `watch-home.png` | Watch home screen with levels |
| `watch-spelling.png` | Watch spelling input |
| `watch-correct.png` | Watch correct answer |
| `watch-level-complete.png` | Watch level complete |

## Taking Screenshots

### iPhone Simulator
1. Open Xcode and run the app on iPhone simulator
2. Navigate to the desired screen
3. Press `Cmd + S` to save screenshot
4. Screenshots save to Desktop by default

### Apple Watch Simulator
1. Run the Watch app on Apple Watch simulator
2. Navigate to the desired screen
3. Press `Cmd + S` to save screenshot

### From Physical Device
1. Navigate to the screen you want to capture
2. Press `Side Button + Volume Up` simultaneously
3. Screenshots save to Photos app
4. AirDrop or sync to your Mac

## Customization

### Colors (in styles.css)
```css
:root {
    --primary-dark: #1A0A2E;      /* Dark purple background */
    --primary-purple: #4B1A8F;    /* Primary purple */
    --primary-light: #6B2EB5;     /* Light purple */
    --accent-cyan: #00D4FF;       /* Cyan accent */
}
```

### Contact Email
Update the email address in:
- `index.html` (line ~340): `mailto:teachmath.me@gmail.com`
- `privacy.html` (contact section): `teachmath.me@gmail.com`

### App Store Link
Replace the `#` in the download button href with your actual App Store URL:
```html
<a href="https://apps.apple.com/app/idXXXXXXXXXX" class="app-store-btn">
```

## Deployment Options

### GitHub Pages
1. Push to GitHub repository
2. Go to Settings → Pages
3. Select branch and folder
4. Your site will be at `username.github.io/repo-name`

### Netlify
1. Connect your GitHub repo to Netlify
2. Deploy with default settings
3. Get a free `*.netlify.app` domain

### Custom Domain
1. Deploy to any hosting service
2. Add CNAME record pointing to your host
3. Update hosting settings with your domain

## Testing Locally

Simply open `index.html` in a web browser:
```bash
open index.html
```

Or use a local server:
```bash
python3 -m http.server 8000
# Then visit http://localhost:8000
```

## Browser Support

- Chrome (latest)
- Safari (latest)
- Firefox (latest)
- Edge (latest)
- Mobile browsers (iOS Safari, Chrome for Android)

## License

This landing page is part of the SpellFlare project.
