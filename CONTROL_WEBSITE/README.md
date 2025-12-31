# Control Website

This folder allows you to control the content and styling of your website without editing code. Each setting is contained in a simple text file.

## 1. Hero & Header (`1_HERO_AND_HEADER`)
Change the main title, subtitle, and call-to-action buttons.
- `TITLE.txt`: The main headline.
- `SUBTITLE.txt`: The sub-headline.
- `BTN_PRIMARY_TEXT.txt` / `LINK.txt`: First button.
- `BTN_SECONDARY_TEXT.txt` / `LINK.txt`: Second button.

## 2. Narrative Chapters (`2_NARRATIVE_CHAPTERS`)
Folders for each feature/chapter.
- Each folder (`Chapter1`, etc.) contains:
  - `TITLE.txt`, `DESCRIPTION.txt`: Content.
  - `IMAGE_NAME.txt`: Image filename.
  - `IMG_WIDTH.txt`, `IMG_OFFSET.txt`, `IMG_ZOOM.txt`: Visual adjustments.

## 3. Design Studio (`3_DESIGN_STUDIO`)
Tweaks for fonts, spacing, and images.
- `HERO_FONT_SIZE_PX.txt`: Title size.
- `CORNER_ROUNDNESS_PX.txt`: Border radius.
- `HERO_IMG_SCALE.txt`, etc.: Fine-tune the hero image.
- `SCREENSHOTS_PATH.txt`: Pointing to `CONTROL_WEBSITE/screenshots`.

## 4. Final Conversion (`4_FINAL_CONVERSION`)
The bottom "Get Started" section.
- `TITLE.txt`, `SUBTITLE.txt`, `BUTTON_TEXT.txt`.
- `TECH_STACK.txt`: List of technologies.

## Screenshots (`screenshots`)
Place your images (png, jpg) in this folder.
- Refer to them by filename in `IMAGE_NAME.txt` or `HERO_IMAGE.txt`.

## How to Update
1. Edit any `.txt` file.
2. Run `run_app.bat` or `auto_sync.bat` to apply changes.
