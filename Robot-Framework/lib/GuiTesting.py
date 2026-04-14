# SPDX-FileCopyrightText: 2022-2026 Technology Innovation Institute (TII)
# SPDX-License-Identifier: Apache-2.0

from evdev import ecodes
from PIL import Image
from pyscreeze import locate, center
import logging
import pytesseract
import subprocess

def locate_image(screenshot, image, confidence):
    logging.info("Searching " + image)
    image_box = locate(image, screenshot, confidence=confidence)
    image_center = center(image_box)
    logging.info(image_box)
    logging.info(image_center)
    image_center_in_mouse_coordinates = convert_resolution(image_center)
    logging.info(image_center_in_mouse_coordinates)
    return image_center_in_mouse_coordinates

def get_data_from_image(image, scale=1):
    image = Image.open(image)
    image = image.resize((image.width * scale, image.height * scale), Image.BICUBIC)
    data = pytesseract.image_to_data(image, output_type=pytesseract.Output.DICT)
    logging.info(data)
    return data

def get_text(data: pytesseract.Output.DICT):
    text_list = []
    sentence = []

    for word in data['text']:
        if word == "":
            if sentence:
                text_list.append(' '.join(sentence))
                sentence.clear()
        else:
            sentence.append(word)

    if sentence:
        text_list.append(' '.join(sentence))

    logging.info(text_list)
    return text_list

def is_text_on_the_screen(screenshot, text, scale=1):
    logging.info("Searching " + text)
    data = get_data_from_image(screenshot, scale)

    for sentence in get_text(data):
        if text in sentence:
            return True

    return False

def locate_text(screenshot, text, scale=1):
    logging.info("Searching " + text)
    data = get_data_from_image(screenshot, scale)

    # Loop through results to find matching text
    for i, word in enumerate(data['text']):
        if text.lower() in word.strip().lower():
            x, y, w, h = (data[key][i] for key in ['left', 'top', 'width', 'height'])
            x, y, w, h = (v // scale for v in (x, y, w, h))
            text_center = (x + w // 2, y + h // 2)
            logging.info(f"Found '{text}' at {text_center}")
            image_center_in_mouse_coordinates = convert_resolution(text_center)
            logging.info(image_center_in_mouse_coordinates)
            return image_center_in_mouse_coordinates

    raise AssertionError(f"Text '{text}' not found on screen.")

def convert_resolution(coordinates):
    # Currently default screenshot image resolution is 1920x1200
    # but ydotool mouse movement resolution was tested to be 960x600.
    # Testing shows that this scaling ratio stays fixed even if changing the display resolution:
    # ydotool mouse resolution changes in relation to display resolution.
    # Hence we can use the hardcoded value.
    scaling_factor = 2
    mouse_coordinates = {
        'x': int(coordinates[0] / scaling_factor),
        'y': int(coordinates[1] / scaling_factor)
    }
    return mouse_coordinates

def convert_app_icon(crop, background, input_file='icon.svg', output_file='icon.png'):
    if background != "none":
        subprocess.run(['magick', '-background', background, input_file, '-gravity', 'center', '-extent',
                        '{}x{}'.format(crop, crop), output_file])
    else:
        subprocess.run(['magick', input_file, '-gravity', 'center', '-extent',
                        '{}x{}'.format(crop, crop), output_file])
    return

def negate_app_icon(input_file, output_file):
    subprocess.run(['magick', input_file, '-negate', output_file])

def generate_ydotool_key_command(key_combination):
    # Returns a `key ...` command string for the given key combination,
    # e.g. generate_ydotool_key_command("LEFTMETA+LEFTSHIFT+ESC") -> 'key 125:1 42:1 1:1 1:0 42:0 125:0'
    keys = key_combination.split("+")
    key_codes = []
    for key in keys:
        key = key.strip().upper()
        full_key = f"KEY_{key}"
        if not hasattr(ecodes, full_key):
            raise ValueError(f"Unknown key: {key} (tried {full_key})")
        key_codes.append(getattr(ecodes, full_key))

    press_events = [f"{code}:1" for code in key_codes]
    release_events = [f"{code}:0" for code in reversed(key_codes)]

    return "key " + " ".join(press_events + release_events)