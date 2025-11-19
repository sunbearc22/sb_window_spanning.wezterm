#!/usr/bin/env python3

import argparse
import cssutils
from pathlib import Path

def get_ubuntu_panel_height_from_theme(theme):
    # Define the .css file path of the theme and check that it exist.
    file = Path("/usr/share/gnome-shell/theme/") / theme / "gnome-shell.css"
    # print(f"{file=}")
    if not file.exists():
        print(f"Invalid path {str(file)}")
        return
    # Parse the .css file using cssutils to extract panel's height
    try:
        css = cssutils.parseFile(str(file))
        for rule in css:
            if rule.type == cssutils.css.CSSRule.STYLE_RULE:
                # Check if this is the #panel selector
                if rule.selectorText.strip() == '#panel':
                    # Look through all properties in this rule
                    for prop in rule.style:
                        if prop.name.lower() == 'height':
                            return prop.value
    except Exception as e:
        print(f"Error parsing CSS: {e}")
    return

def main():
    parser = argparse.ArgumentParser(
        description='Get Ubuntu panel height from GNOME Shell theme'
    )
    parser.add_argument(
        'theme', 
        help='Name of the GNOME Shell theme (e.g., Yaru-purple-dark)',
    )
    args = parser.parse_args()
    height = get_ubuntu_panel_height_from_theme(args.theme)
    if height:
        print(height)
    # else:
    #     print("")  # Panel height not found

if __name__ == "__main__":
    main()
